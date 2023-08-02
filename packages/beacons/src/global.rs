use rand::Rng;
use rusqlite::Connection;
use serde::{de::DeserializeOwned, ser::Serialize};
use std::{cell::Cell, marker::PhantomData};

use crate::object_store::ObjectStore;

const INITIAL_COMMANDS: &str = "
PRAGMA auto_vacuum = INCREMENTAL;
PRAGMA journal_mode = WAL;
PRAGMA wal_autocheckpoint = 8000;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -20000;
PRAGMA busy_timeout = 3000;
";

thread_local! {
  static OBJECT_STORE: Cell<Option<ObjectStore>> = Cell::new(None);
}

pub fn init(path: &str) {
  let conn = Connection::open(path).unwrap();
  conn.execute_batch(INITIAL_COMMANDS).unwrap();
  OBJECT_STORE.with(|cell| cell.set(Some(ObjectStore::new(conn, ""))));
}

pub fn init_in_memory() {
  let conn = Connection::open_in_memory().unwrap();
  conn.execute_batch(INITIAL_COMMANDS).unwrap();
  OBJECT_STORE.with(|cell| cell.set(Some(ObjectStore::new(conn, ""))));
}

pub fn access_store_with<R>(f: impl FnOnce(&mut ObjectStore) -> R) -> R {
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
pub struct Atom<T: Serialize + DeserializeOwned> {
  id: u128,
  _t: PhantomData<T>,
}

impl<T: Serialize + DeserializeOwned> Atom<T> {
  pub fn from_raw(id: u128) -> Self {
    Self { id, _t: Default::default() }
  }
  pub fn get(&self) -> Option<T> {
    access_store_with(|store| store.atom(self.id).map(|bytes| postcard::from_bytes(bytes).unwrap()))
  }
  pub fn set(&self, value: &T) {
    access_store_with(|store| store.set_atom(self.id, Some(postcard::to_allocvec(value).unwrap())));
  }
  pub fn remove(&self) {
    access_store_with(|store| store.set_atom(self.id, None));
  }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Link<T: Model> {
  id: u128,
  _t: PhantomData<T>,
}

impl<T: Model> Link<T> {
  pub fn from_raw(id: u128) -> Self {
    Self { id, _t: Default::default() }
  }
  pub fn get(&self) -> Option<T> {
    access_store_with(|store| store.edge(self.id)).and_then(|(_, _, dst)| T::get(dst))
  }
  pub fn set(&self, value: &T) {
    access_store_with(|store| store.set_edge_dst(self.id, value.id()));
  }
  pub fn remove(&self) {
    access_store_with(|store| store.set_edge_dst(self.id, rand::thread_rng().gen()));
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
  pub fn add(&self, dst: u128) {
    access_store_with(|store| store.set_edge(rand::thread_rng().gen(), Some((self.src, self.label, dst))));
  }
  pub fn remove(&self, dst: u128) {
    access_store_with(|store| {
      for id in store.query_edge_src_label(self.src, self.label) {
        if store.edge(id).unwrap().2 == dst {
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
