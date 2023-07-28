use rusqlite::{Connection, Transaction};
use serde::de::DeserializeOwned;
use std::collections::HashMap;

use super::{PersistentGammaJoinable, PersistentJoinable, PersistentState};

trait GenericState {
  fn apply(&mut self, txn: &mut Transaction, a: &[u8]);
}

trait GenericJoinable: GenericState {
  fn preq(&mut self, txn: &mut Transaction, t: &[u8]) -> bool;
  fn join(&mut self, txn: &mut Transaction, t: &[u8]);
}

trait GenericGammaJoinable: GenericJoinable {
  fn gamma_join(&mut self, txn: &mut Transaction, a: &[u8]);
}

impl<T: PersistentState> GenericState for T
where
  T::State: DeserializeOwned,
  T::Action: DeserializeOwned,
{
  fn apply(&mut self, txn: &mut Transaction, a: &[u8]) {
    self.apply(txn, postcard::from_bytes(a).unwrap())
  }
}

impl<T: PersistentJoinable> GenericJoinable for T
where
  T::State: DeserializeOwned,
  T::Action: DeserializeOwned,
{
  fn preq(&mut self, txn: &mut Transaction, t: &[u8]) -> bool {
    self.preq(txn, &postcard::from_bytes(t).unwrap())
  }

  fn join(&mut self, txn: &mut Transaction, t: &[u8]) {
    self.join(txn, postcard::from_bytes(t).unwrap())
  }
}

impl<T: PersistentGammaJoinable> GenericGammaJoinable for T
where
  T::State: DeserializeOwned,
  T::Action: DeserializeOwned,
{
  fn gamma_join(&mut self, txn: &mut Transaction, a: &[u8]) {
    self.gamma_join(txn, postcard::from_bytes(a).unwrap())
  }
}

pub struct Collection {
  conn: Connection,
  name: &'static str,
  joinable: HashMap<&'static str, Box<dyn GenericJoinable>>,
  gamma_joinable: HashMap<&'static str, Box<dyn GenericGammaJoinable>>,
}

impl Collection {
  pub fn new(conn: Connection, name: &'static str) -> Self {
    Self { conn, name, joinable: HashMap::new(), gamma_joinable: HashMap::new() }
  }

  pub fn add_joinable<T: PersistentJoinable + 'static>(&mut self, name: &'static str)
  where
    T::State: DeserializeOwned,
    T::Action: DeserializeOwned,
  {
    assert!(!self.joinable.contains_key(name));
    assert!(!self.gamma_joinable.contains_key(name));
    let mut txn = self.conn.transaction().unwrap();
    self.joinable.insert(name, Box::new(T::initial(&mut txn, self.name, name)));
    txn.commit().unwrap();
  }

  pub fn add_gamma_joinable<T: PersistentGammaJoinable + 'static>(&mut self, name: &'static str)
  where
    T::State: DeserializeOwned,
    T::Action: DeserializeOwned,
  {
    assert!(!self.joinable.contains_key(name));
    assert!(!self.gamma_joinable.contains_key(name));
    let mut txn = self.conn.transaction().unwrap();
    self.gamma_joinable.insert(name, Box::new(T::initial(&mut txn, self.name, name)));
    txn.commit().unwrap();
  }

  pub fn txn(&mut self) -> Transaction<'_> {
    self.conn.transaction().unwrap()
  }
}

/*
#[test]
fn test() {
  let mut col = Collection::new(Connection::open_in_memory().unwrap(), "test");
  col.add_joinable::<Register<u64>>("name");
}
*/

/*
#[test]
fn test() {
  let k = String::from("test");
  let l = String::from("test");
  let mut map = HashMap::<&str, u64>::new();
  map.insert("const", 233);
  map.insert(k.as_str(), 233);
  assert_eq!(*map.get("const").unwrap(), 233);
  assert_eq!(*map.get(k.as_str()).unwrap(), 233);
  assert_eq!(*map.get(l.as_str()).unwrap(), 233);
  assert_eq!(*map.get("test").unwrap(), 233);
}
*/
