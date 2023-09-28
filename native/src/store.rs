use rusqlite::Connection;

use crate::workspace::{Constraints, Workspace};
use crate::{StoreError, Transactor};

pub struct Store {
  txr: Option<Transactor>,
  workspace: Workspace,
}

impl Store {
  pub fn new(conn: Connection, constraints: Constraints) -> Result<Self, StoreError> {
    let mut txr = conn.try_into()?;
    let workspace = Workspace::new("", constraints, &mut txr);
    Ok(Self { txr: Some(txr), workspace })
  }

  pub fn as_mut(&mut self) -> Result<(&mut Transactor, &mut Workspace), StoreError> {
    let txr = self.txr.as_mut().ok_or(StoreError::Disconnected)?;
    Ok((txr, &mut self.workspace))
  }

  pub fn commit(&mut self) -> Result<(), StoreError> {
    let txr = self.txr.take().ok_or(StoreError::Disconnected)?;
    let conn: Connection = txr.try_into()?;
    let txr: Transactor = conn.try_into()?;
    self.txr = Some(txr);
    Ok(())
  }

  pub fn close(mut self) -> Result<(), StoreError> {
    let txr = self.txr.take().ok_or(StoreError::Disconnected)?;
    let conn: Connection = txr.try_into()?;
    conn.close().map_err(|(_, err)| err)?;
    Ok(())
  }
}

/*
/// Basic interface for model types.
pub trait Model: Sized {
  fn id(&self) -> u128;
  fn get(id: u128) -> Option<Self>;
}

/// Nullable atomic values.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct AtomOption<T: Serialize + DeserializeOwned> {
  id: u128,
  src: u128,
  label: u64,
  _t: PhantomData<T>,
}

impl<T: Serialize + DeserializeOwned> AtomOption<T> {
  pub fn from_raw(id: u128, src: u128, label: u64) -> Self {
    Self { id, src, label, _t: PhantomData }
  }
  pub fn id(&self) -> u128 {
    self.id
  }
  pub fn get(&self) -> Option<T> {
    access_store_with(|store| store.atom(self.id).map(|(_, _, bytes)| deserialize(&bytes).unwrap()))
  }
  pub fn set(&self, value: Option<&T>) {
    access_store_with(|store| {
      store.set_atom(self.id, value.map(|inner| (self.src, self.label, serialize(inner).unwrap().into())))
    });
  }
}

/// Non-nullable atomic values.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Atom<T: Serialize + DeserializeOwned> {
  inner: AtomOption<T>,
}

impl<T: Serialize + DeserializeOwned> Atom<T> {
  pub fn from_raw(id: u128, src: u128, label: u64) -> Self {
    Self { inner: AtomOption::from_raw(id, src, label) }
  }
  pub fn id(&self) -> u128 {
    self.inner.id()
  }
  pub fn get(&self) -> T {
    self.inner.get().unwrap()
  }
  pub fn set(&self, value: &T) {
    self.inner.set(Some(value))
  }
}

/// Nullable links.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LinkOption<T: Model> {
  id: u128,
  src: u128,
  label: u64,
  _t: PhantomData<T>,
}

impl<T: Model> LinkOption<T> {
  pub fn from_raw(id: u128, src: u128, label: u64) -> Self {
    Self { id, src, label, _t: PhantomData }
  }
  pub fn id(&self) -> u128 {
    self.id
  }
  pub fn get(&self) -> Option<T> {
    access_store_with(|store| store.edge(self.id)).and_then(|(_, _, dst)| T::get(dst))
  }
  pub fn set(&self, value: Option<&T>) {
    access_store_with(|store| store.set_edge(self.id, value.map(|inner| (self.src, self.label, inner.id()))));
  }
}

/// Non-nullable links.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Link<T: Model> {
  inner: LinkOption<T>,
}

impl<T: Model> Link<T> {
  pub fn from_raw(id: u128, src: u128, label: u64) -> Self {
    Self { inner: LinkOption::from_raw(id, src, label) }
  }
  pub fn id(&self) -> u128 {
    self.inner.id()
  }
  pub fn get(&self) -> T {
    self.inner.get().unwrap()
  }
  pub fn set(&self, value: &T) {
    self.inner.set(Some(value))
  }
}

/// Multiple links.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Multilinks<T> {
  src: u128,
  label: u64,
  _t: PhantomData<T>,
}

impl<T: Model> Multilinks<T> {
  pub fn from_raw(src: u128, label: u64) -> Self {
    Self { src, label, _t: PhantomData }
  }
  pub fn get(&self) -> Vec<T> {
    let mut res = Vec::new();
    for (_, dst) in access_store_with(|store| store.edge_dst_by_src_label(self.src, self.label)) {
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
    for (id, dst) in access_store_with(|store| store.edge_dst_by_src_label(self.src, self.label)) {
      if dst == object.id() {
        access_store_with(|store| store.set_edge(id, None));
        break;
      }
    }
  }
}

/// Backward links (read-only).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Backlinks<T: Model> {
  dst: u128,
  label: u64,
  _t: PhantomData<T>,
}

impl<T: Model> Backlinks<T> {
  pub fn from_raw(dst: u128, label: u64) -> Self {
    Self { dst, label, _t: PhantomData }
  }
  pub fn get(&self) -> Vec<T> {
    let mut res = Vec::new();
    for (_, src) in access_store_with(|store| store.edge_src_by_dst_label(self.dst, self.label)) {
      if let Some(inner) = T::get(src) {
        res.push(inner);
      }
    }
    res
  }
}

/// Synchronises all data (step 1).
pub fn sync_version() -> Box<[u8]> {
  access_store_with(|store| store.sync_version())
}

/// Synchronises all data (step 2).
pub fn sync_actions(clocks: &[u8]) -> Box<[u8]> {
  access_store_with(|store| store.sync_actions(clocks))
}

/// Synchronises all data (step 3).
pub fn sync_join(actions: &[u8]) -> Option<Box<[u8]>> {
  access_store_with(|store| store.sync_join(actions))
}

/// Example usage (should be automatically generated by macros) and tests.
#[cfg(test)]
#[allow(warnings, unused)]
mod tests {
  use crate::global::{self, Atom, AtomOption, Backlinks, Link, LinkOption, Model, Multilinks};
  use crate::serialize;
  use rand::Rng;

  #[derive(Debug)]
  struct Trivial {
    id: u128,
    unit: Atom<()>,
  }

  impl Trivial {
    pub const UNIT_LABEL: u64 = 1 /* Calculated from fnv64_hash("Trivial.unit") */;

    pub fn new(unit: &()) -> Self {
      let mut rng = rand::thread_rng();
      let id = rng.gen();

      global::access_store_with(|store| {
        // Create `Trivial.unit`.
        store.set_atom(rng.gen(), Some((id, Self::UNIT_LABEL, serialize(unit).unwrap().into())));
      });

      // Return.
      Self::get(id).unwrap()
    }

    pub fn delete(self) {
      global::access_store_with(|store| {
        // Delete all fields.
        for (atom, _) in store.atom_label_value_by_src(self.id) {
          store.set_atom(atom, None);
        }
        for (edge, _) in store.edge_label_dst_by_src(self.id) {
          store.set_atom(edge, None);
        }
      });
    }
  }

  impl Model for Trivial {
    fn id(&self) -> u128 {
      self.id
    }

    fn get(id: u128) -> Option<Self> {
      global::access_store_with(|store| {
        // Variables for existing data.
        let mut unit: Option<Atom<()>> = None;

        // Load existing data.
        for (atom, (label, _)) in store.atom_label_value_by_src(id) {
          match label {
            Self::UNIT_LABEL => unit = Some(Atom::from_raw(atom, id, label)),
            _ => (),
          }
        }
        for (edge, (label, _)) in store.edge_label_dst_by_src(id) {
          match label {
            _ => (),
          }
        }

        // Pack together. Fail if a field is not found.
        Some(Self { id, unit: unit? })
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
    pub const ATOM_ONE_LABEL: u64 = 2 /* Calculated from fnv64_hash("Something.atom_one") */;
    pub const ATOM_TWO_LABEL: u64 = 3 /* Calculated from fnv64_hash("Something.atom_two") */;
    pub const LINK_ONE_LABEL: u64 = 4 /* Calculated from fnv64_hash("Something.link_one") */;
    pub const LINK_TWO_LABEL: u64 = 5 /* Calculated from fnv64_hash("Something.link_two") */;
    pub const LINK_THREE_LABEL: u64 = 6 /* Calculated from fnv64_hash("Something.link_three") */;

    pub fn new(atom_one: &String, atom_two: Option<&String>, link_one: &Trivial, link_two: Option<&Trivial>) -> Self {
      let mut rng = rand::thread_rng();
      let id = rng.gen();

      global::access_store_with(|store| {
        // Create `Something.atom_one`.
        store.set_atom(rng.gen(), Some((id, Self::ATOM_ONE_LABEL, serialize(atom_one).unwrap().into())));

        // Create `Something.atom_two`.
        if let Some(atom_two) = atom_two {
          store.set_atom(rng.gen(), Some((id, Self::ATOM_TWO_LABEL, serialize(atom_two).unwrap().into())));
        }

        // Create `Something.link_one`.
        store.set_edge(rng.gen(), Some((id, Self::LINK_ONE_LABEL, link_one.id())));

        // Create `Something.link_two`.
        if let Some(link_two) = link_two {
          store.set_edge(rng.gen(), Some((id, Self::LINK_TWO_LABEL, link_two.id())));
        }
      });

      // Return.
      Self::get(id).unwrap()
    }

    pub fn delete(self) {
      global::access_store_with(|store| {
        // Delete all fields.
        for (atom, _) in store.atom_label_value_by_src(self.id) {
          store.set_atom(atom, None);
        }
        for (edge, _) in store.edge_label_dst_by_src(self.id) {
          store.set_atom(edge, None);
        }
      });
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
        for (atom, (label, _)) in store.atom_label_value_by_src(id) {
          match label {
            Self::ATOM_ONE_LABEL => atom_one = Some(Atom::from_raw(atom, id, label)),
            Self::ATOM_TWO_LABEL => atom_two = Some(AtomOption::from_raw(atom, id, label)),
            _ => (),
          }
        }
        for (edge, (label, _)) in store.edge_label_dst_by_src(id) {
          match label {
            Self::LINK_ONE_LABEL => link_one = Some(Link::from_raw(edge, id, label)),
            Self::LINK_TWO_LABEL => link_two = Some(LinkOption::from_raw(edge, id, label)),
            _ => (),
          }
        }

        // Pack together. Fail if a required field is not found.
        Some(Self {
          id,
          atom_one: atom_one?,
          atom_two: atom_two.unwrap_or(AtomOption::from_raw(
            id ^ (Self::ATOM_TWO_LABEL as u128),
            id,
            Self::ATOM_TWO_LABEL,
          )),
          link_one: link_one?,
          link_two: link_two.unwrap_or(LinkOption::from_raw(
            id ^ (Self::LINK_TWO_LABEL as u128),
            id,
            Self::LINK_TWO_LABEL,
          )),
          link_three: Multilinks::from_raw(id, Self::LINK_THREE_LABEL),
          backlink: Backlinks::from_raw(id, Something::LINK_THREE_LABEL),
        })
      })
    }
  }

  #[test]
  fn object_store_simple() {
    global::init_in_memory();
    global::access_store_with(|store| store.set_atom(0, Some((1, 2, vec![2, 3, 3].into()))));
    global::access_store_with(|store| store.set_atom(1, Some((3, 4, vec![2, 3, 3, 3].into()))));
    global::access_store_with(|store| store.set_edge(rand::thread_rng().gen(), Some((0, 23333, 1))));
    assert_eq!(global::access_store_with(|store| store.atom(0)), Some((1, 2, vec![2, 3, 3].into())));
    assert_eq!(global::access_store_with(|store| store.atom(1)), Some((3, 4, vec![2, 3, 3, 3].into())));
    let edges = global::access_store_with(|store| store.edge_label_dst_by_src(0));
    assert_eq!(edges.len(), 1);
    assert_eq!(edges[0].1, (23333, 1));
  }

  #[test]
  fn atom_link_simple() {
    global::init_in_memory();

    let trivial = Trivial::new(&());
    let trivial_again = Trivial::new(&());

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
*/
