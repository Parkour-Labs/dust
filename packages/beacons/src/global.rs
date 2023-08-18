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
  OBJECT_STORE.with(|cell| cell.set(Some(Store::new(conn))));
}

pub fn init_in_memory() {
  let conn = Connection::open_in_memory().unwrap();
  conn.execute_batch(INITIAL_COMMANDS).unwrap();
  OBJECT_STORE.with(|cell| cell.set(Some(Store::new(conn))));
}

pub fn access_store_with<R>(f: impl FnOnce(&mut Store) -> R) -> R {
  OBJECT_STORE.with(|cell| {
    let mut store = cell.take().unwrap();
    let res = f(&mut store);
    cell.set(Some(store));
    res
  })
}

pub fn sync_version() -> Vec<u8> {
  access_store_with(|store| store.sync_version())
}

pub fn sync_actions(clocks: &[u8]) -> Vec<u8> {
  access_store_with(|store| store.sync_actions(clocks))
}

pub fn sync_join(actions: &[u8]) {
  access_store_with(|store| store.sync_join(actions))
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
    let mut res = Vec::new();
    for (_, dst) in access_store_with(|store| store.id_dst_by_src_label(self.src, self.label)) {
      if let Some(inner) = T::get(dst) {
        res.push(inner);
      }
    }
    res
  }
  pub fn insert(&self, object: &T) {
    access_store_with(|store| store.set_edge(rand::thread_rng().gen(), Some((self.src, self.label, object.id()))));
  }
  pub fn remove(&self, object: &T) {
    for (id, dst) in access_store_with(|store| store.id_dst_by_src_label(self.src, self.label)) {
      if dst == object.id() {
        access_store_with(|store| store.set_edge(id, None));
        break;
      }
    }
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
    let mut res = Vec::new();
    for (_, src) in access_store_with(|store| store.id_src_by_dst_label(self.dst, self.label)) {
      if let Some(inner) = T::get(src) {
        res.push(inner);
      }
    }
    res
  }
}

#[cfg(test)]
mod tests {
  use crate::global::{self, Atom, AtomOption, Backlinks, Link, LinkOption, Model, Multilinks};
  use crate::serialize;
  use rand::Rng;

  #[derive(Debug)]
  struct Trivial {
    id: u128,
  }

  impl Trivial {
    pub const LABEL: u64 = 0 /* Calculated from fnv64_hash("Trivial") */;

    pub fn new(/* (No code generated here) */) -> Self {
      let mut rng = rand::thread_rng();
      let id = rng.gen();

      global::access_store_with(|store| {
        // Create `Trivial`.
        store.set_node(id, Some(Trivial::LABEL));

        /* (No code generated here) */
      });

      // Return.
      Self::get(id).unwrap()
    }

    pub fn delete(self) {
      global::access_store_with(|store| store.set_node(self.id, None));
    }
  }

  impl Model for Trivial {
    fn id(&self) -> u128 {
      self.id
    }

    fn get(id: u128) -> Option<Self> {
      global::access_store_with(|store| {
        // Variables for existing data.
        /* (No code generated here) */

        // Load existing data.
        store.node(id)?;
        /* (No code generated here) */

        // Pack together. Fail if a field is not found.
        Some(Self {
          id,
          /* (No code generated here) */
        })
      })
    }
  }

  #[derive(Debug)]
  struct Something {
    id: u128,
    atom_one: Atom<String>,
    atom_two: AtomOption<String>,
    link_one: Link<Trivial>,
    link_two: LinkOption<Trivial>,
    link_three: Multilinks<Something>,
    backlink: Backlinks<Something>,
  }

  impl Something {
    pub const LABEL: u64 = 1 /* Calculated from fnv64_hash("Something") */;
    pub const ATOM_ONE_LABEL: u64 = 2 /* Calculated from fnv64_hash("Something.atom_one") */;
    pub const ATOM_TWO_LABEL: u64 = 3 /* Calculated from fnv64_hash("Something.atom_two") */;
    pub const LINK_ONE_LABEL: u64 = 4 /* Calculated from fnv64_hash("Something.link_one") */;
    pub const LINK_TWO_LABEL: u64 = 5 /* Calculated from fnv64_hash("Something.link_two") */;
    pub const LINK_THREE_LABEL: u64 = 6 /* Calculated from fnv64_hash("Something.link_three") */;

    pub fn new(atom_one: &String, atom_two: Option<&String>, link_one: &Trivial, link_two: Option<&Trivial>) -> Self {
      let mut rng = rand::thread_rng();
      let id = rng.gen();

      global::access_store_with(|store| {
        // Create `Something`.
        store.set_node(id, Some(Something::LABEL));

        // Create `Something.atom_one`.
        let atom_one_id = rng.gen();
        store.set_edge(rng.gen(), Some((id, Something::ATOM_ONE_LABEL, atom_one_id)));
        store.set_atom(atom_one_id, Some(serialize(atom_one).unwrap()));

        // Create `Something.atom_two`.
        if let Some(atom_two) = atom_two {
          let atom_two_id = rng.gen();
          store.set_edge(rng.gen(), Some((id, Something::ATOM_TWO_LABEL, atom_two_id)));
          store.set_atom(atom_two_id, Some(serialize(atom_two).unwrap()));
        } else {
          store.set_edge(rng.gen(), Some((id, Something::ATOM_TWO_LABEL, rng.gen())));
        }

        // Create `Something.link_one`.
        store.set_edge(rng.gen(), Some((id, Something::LINK_ONE_LABEL, link_one.id())));

        // Create `Something.link_two`.
        if let Some(link_two) = link_two {
          store.set_edge(rng.gen(), Some((id, Something::LINK_TWO_LABEL, link_two.id())));
        } else {
          store.set_edge(rng.gen(), Some((id, Something::LINK_TWO_LABEL, rng.gen())));
        }
      });

      // Return.
      Self::get(id).unwrap()
    }

    pub fn delete(self) {
      global::access_store_with(|store| store.set_node(self.id, None));
    }
  }

  impl Model for Something {
    fn id(&self) -> u128 {
      self.id
    }

    fn get(id: u128) -> Option<Self> {
      global::access_store_with(|store| {
        // Variables for existing data.
        let mut atom_one: Option<Atom<String>> = None;
        let mut atom_two: Option<AtomOption<String>> = None;
        let mut link_one: Option<Link<Trivial>> = None;
        let mut link_two: Option<LinkOption<Trivial>> = None;

        // Load existing data.
        store.node(id)?;
        for (edge, (_, label, dst)) in store.edges_by_src(id) {
          match label {
            Something::ATOM_ONE_LABEL => atom_one = Some(Atom::from_raw(dst)),
            Something::ATOM_TWO_LABEL => atom_two = Some(AtomOption::from_raw(dst)),
            Something::LINK_ONE_LABEL => link_one = Some(Link::from_raw(edge)),
            Something::LINK_TWO_LABEL => link_two = Some(LinkOption::from_raw(edge)),
            _ => (),
          }
        }

        // Pack together. Fail if a field is not found.
        Some(Self {
          id,
          atom_one: atom_one?,
          atom_two: atom_two?,
          link_one: link_one?,
          link_two: link_two?,
          link_three: Multilinks::from_raw(id, Something::LINK_THREE_LABEL),
          backlink: Backlinks::from_raw(id, Something::LINK_THREE_LABEL),
        })
      })
    }
  }

  #[test]
  fn object_store_simple() {
    global::init_in_memory();
    global::access_store_with(|store| store.set_node(0, Some(233)));
    global::access_store_with(|store| store.set_node(1, Some(2333)));
    global::access_store_with(|store| store.set_edge(rand::thread_rng().gen(), Some((0, 23333, 1))));
    assert_eq!(global::access_store_with(|store| store.node(0)), Some(233));
    assert_eq!(global::access_store_with(|store| store.node(1)), Some(2333));
    let edges = global::access_store_with(|store| store.edges_by_src(0));
    assert_eq!(edges.len(), 1);
    assert_eq!(edges[0].1, (0, 23333, 1));
  }

  #[test]
  fn atom_link_simple() {
    global::init_in_memory();

    let trivial = Trivial::new();
    let trivial_again = Trivial::new();

    let something = Something::new(&String::from("test"), Some(&String::from("2333")), &trivial, Some(&trivial));
    let something_else = Something::new(&String::from("test"), None, &trivial, None);
    something_else.link_three.insert(&something);

    let something_id = something.id();
    let something_else_id = something_else.id();

    let something_copy = Something::get(something_id).unwrap();
    let something_else_copy = Something::get(something_else_id).unwrap();

    assert_eq!(something_copy.atom_one.get(), "test");
    assert_eq!(something_copy.atom_two.get().unwrap(), "2333");
    assert_eq!(something_copy.link_one.get().id(), trivial.id());
    assert_eq!(something_copy.link_two.get().unwrap().id(), trivial.id());
    assert_eq!(something_copy.link_three.get().len(), 0);

    assert_eq!(something_else_copy.atom_one.get(), "test");
    assert!(something_else_copy.atom_two.get().is_none());
    assert_eq!(something_else_copy.link_one.get().id(), trivial.id());
    assert!(something_else_copy.link_two.get().is_none());
    assert_eq!(something_else_copy.link_three.get().len(), 1);
    assert_eq!(something_else_copy.link_three.get()[0].id(), something.id());

    something_copy.atom_two.set(None);
    assert!(something_copy.atom_two.get().is_none());
    something_copy.atom_two.set(Some(&String::from("gg")));
    assert_eq!(something_copy.atom_two.get().unwrap(), "gg");
    something_copy.link_two.set(None);
    assert!(something_copy.link_two.get().is_none());
    something_copy.link_two.set(Some(&trivial_again));
    assert_eq!(something_copy.link_two.get().unwrap().id(), trivial_again.id());

    assert_eq!(something.backlink.get().len(), 1);
    something.link_three.insert(&something);
    assert_eq!(something.backlink.get().len(), 2);
    something.link_three.insert(&something);
    assert_eq!(something.backlink.get().len(), 3);
    something.link_three.remove(&something);
    assert_eq!(something.backlink.get().len(), 2);
    something_else.link_three.remove(&something);
    assert_eq!(something.backlink.get().len(), 1);

    trivial.delete();
    trivial_again.delete();
    assert!(std::panic::catch_unwind(|| something.link_one.get()).is_err()); // Panics.
    assert!(something.link_two.get().is_none());
    assert!(std::panic::catch_unwind(|| something_else.link_one.get()).is_err()); // Panics.
    assert!(something_else.link_two.get().is_none());
    something.delete();
    something_else.delete();
  }
}
