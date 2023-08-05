use rand::Rng;
use rusqlite::Connection;
use serde::{de::DeserializeOwned, ser::Serialize};
use std::{cell::Cell, marker::PhantomData};

use crate::store::Store;
use crate::{deserialize, serialize};

const INITIAL_COMMANDS: &str = "
PRAGMA auto_vacuum = INCREMENTAL;
PRAGMA journal_mode = WAL;
PRAGMA wal_autocheckpoint = 8000;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -20000;
PRAGMA busy_timeout = 3000;
";

thread_local! {
  static OBJECT_STORE: Cell<Option<Store>> = Cell::new(None);
}

pub fn init(path: &str) {
  let conn = Connection::open(path).unwrap();
  conn.execute_batch(INITIAL_COMMANDS).unwrap();
  OBJECT_STORE.with(|cell| cell.set(Some(Store::new(conn, ""))));
}

pub fn init_in_memory() {
  let conn = Connection::open_in_memory().unwrap();
  conn.execute_batch(INITIAL_COMMANDS).unwrap();
  OBJECT_STORE.with(|cell| cell.set(Some(Store::new(conn, ""))));
}

pub fn access_store_with<R>(f: impl FnOnce(&mut Store) -> R) -> R {
  OBJECT_STORE.with(|cell| {
    let mut store = cell.take().unwrap();
    let res = f(&mut store);
    cell.set(Some(store));
    res
  })
}

pub fn sync_clocks() -> Vec<u8> {
  access_store_with(|store| store.sync_clocks())
}

pub fn sync_actions(clocks: &[u8]) -> Vec<u8> {
  access_store_with(|store| store.sync_actions(clocks))
}

pub fn sync_apply(actions: &[u8]) {
  access_store_with(|store| store.sync_apply(actions))
}

pub trait Model: std::marker::Sized {
  fn id(&self) -> u128;
  fn get(id: u128) -> Option<Self>;
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AtomOption<T: Serialize + DeserializeOwned> {
  id: u128,
  _t: PhantomData<T>,
}

impl<T: Serialize + DeserializeOwned> AtomOption<T> {
  pub fn from_raw(id: u128) -> Self {
    Self { id, _t: Default::default() }
  }
  pub fn get(&self) -> Option<T> {
    access_store_with(|store| store.atom(self.id).map(|bytes| deserialize(bytes).unwrap()))
  }
  pub fn set(&self, value: Option<&T>) {
    access_store_with(|store| store.set_atom(self.id, value.map(|inner| serialize(inner).unwrap())));
  }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Atom<T: Serialize + DeserializeOwned> {
  inner: AtomOption<T>,
}

impl<T: Serialize + DeserializeOwned> Atom<T> {
  pub fn from_raw(id: u128) -> Self {
    Self { inner: AtomOption::from_raw(id) }
  }
  pub fn get(&self) -> T {
    self.inner.get().unwrap()
  }
  pub fn set(&self, value: &T) {
    self.inner.set(Some(value))
  }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LinkOption<T: Model> {
  id: u128,
  _t: PhantomData<T>,
}

impl<T: Model> LinkOption<T> {
  pub fn from_raw(id: u128) -> Self {
    Self { id, _t: Default::default() }
  }
  pub fn get(&self) -> Option<T> {
    access_store_with(|store| store.edge(self.id)).and_then(|(_, _, dst)| T::get(dst))
  }
  pub fn set(&self, value: Option<&T>) {
    access_store_with(|store| {
      store.set_edge_dst(self.id, value.map_or_else(|| rand::thread_rng().gen(), |inner| inner.id()))
    });
  }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Link<T: Model> {
  inner: LinkOption<T>,
}

impl<T: Model> Link<T> {
  pub fn from_raw(id: u128) -> Self {
    Self { inner: LinkOption::from_raw(id) }
  }
  pub fn get(&self) -> T {
    self.inner.get().unwrap()
  }
  pub fn set(&self, value: &T) {
    self.inner.set(Some(value))
  }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Multilinks<T> {
  src: u128,
  label: u64,
  _t: PhantomData<T>,
}

impl<T: Model> Multilinks<T> {
  pub fn from_raw(src: u128, label: u64) -> Self {
    Self { src, label, _t: Default::default() }
  }
  pub fn get(&self) -> Vec<T> {
    access_store_with(|store| {
      let mut res = store.query_edge_src_label(self.src, self.label);
      for id in res.as_mut_slice() {
        *id = store.edge(*id).unwrap().0;
      }
      res
    })
    .into_iter()
    .filter_map(T::get)
    .collect()
  }
  pub fn insert(&self, dst: &T) {
    access_store_with(|store| store.set_edge(rand::thread_rng().gen(), Some((self.src, self.label, dst.id()))));
  }
  pub fn remove(&self, dst: &T) {
    access_store_with(|store| {
      for id in store.query_edge_src_label(self.src, self.label) {
        if store.edge(id).unwrap().2 == dst.id() {
          store.set_edge(id, None);
          break;
        }
      }
    });
  }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Backlinks<T: Model> {
  dst: u128,
  label: u64,
  _t: PhantomData<T>,
}

impl<T: Model> Backlinks<T> {
  pub fn from_raw(dst: u128, label: u64) -> Self {
    Self { dst, label, _t: Default::default() }
  }
  pub fn get(&self) -> Vec<T> {
    access_store_with(|store| {
      let mut res = store.query_edge_dst_label(self.dst, self.label);
      for id in res.as_mut_slice() {
        *id = store.edge(*id).unwrap().0;
      }
      res
    })
    .into_iter()
    .filter_map(T::get)
    .collect()
  }
}
