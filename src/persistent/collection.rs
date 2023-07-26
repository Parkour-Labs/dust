use rusqlite::{Connection, Transaction};
use std::collections::HashMap;

use super::{PersistentDeltaJoinable, PersistentGammaJoinable, PersistentJoinable, PersistentState, Serde};

trait TypeErasedState {
  fn apply(&mut self, txn: &Transaction, col: &str, name: &str, a: &[u8]);
}

trait TypeErasedJoinable: TypeErasedState {
  fn preq(&mut self, txn: &Transaction, col: &str, name: &str, t: &[u8]) -> bool;
  fn join(&mut self, txn: &Transaction, col: &str, name: &str, t: &[u8]);
}

trait TypeErasedDeltaJoinable: TypeErasedJoinable {
  fn delta_join(&mut self, txn: &Transaction, col: &str, name: &str, a: &[u8], b: &[u8]);
}

trait TypeErasedGammaJoinable: TypeErasedJoinable {
  fn gamma_join(&mut self, txn: &Transaction, col: &str, name: &str, a: &[u8]);
}

impl<T: PersistentState> TypeErasedState for T
where
  T::State: Serde,
  T::Action: Serde,
{
  fn apply(&mut self, txn: &Transaction, col: &str, name: &str, a: &[u8]) {
    self.apply(txn, col, name, postcard::from_bytes(a).unwrap())
  }
}

impl<T: PersistentJoinable> TypeErasedJoinable for T
where
  T::State: Serde,
  T::Action: Serde,
{
  fn preq(&mut self, txn: &Transaction, col: &str, name: &str, t: &[u8]) -> bool {
    self.preq(txn, col, name, &postcard::from_bytes(t).unwrap())
  }

  fn join(&mut self, txn: &Transaction, col: &str, name: &str, t: &[u8]) {
    self.join(txn, col, name, postcard::from_bytes(t).unwrap())
  }
}

impl<T: PersistentDeltaJoinable> TypeErasedDeltaJoinable for T
where
  T::State: Serde,
  T::Action: Serde,
{
  fn delta_join(&mut self, txn: &Transaction, col: &str, name: &str, a: &[u8], b: &[u8]) {
    self.delta_join(txn, col, name, postcard::from_bytes(a).unwrap(), postcard::from_bytes(b).unwrap())
  }
}

impl<T: PersistentGammaJoinable> TypeErasedGammaJoinable for T
where
  T::State: Serde,
  T::Action: Serde,
{
  fn gamma_join(&mut self, txn: &Transaction, col: &str, name: &str, a: &[u8]) {
    self.gamma_join(txn, col, name, postcard::from_bytes(a).unwrap())
  }
}

pub struct Collection {
  conn: Connection,
  name: &'static str,
  joinable: HashMap<&'static str, Box<dyn TypeErasedJoinable>>,
  delta_joinable: HashMap<&'static str, Box<dyn TypeErasedDeltaJoinable>>,
  gamma_joinable: HashMap<&'static str, Box<dyn TypeErasedGammaJoinable>>,
}

impl Collection {
  pub fn new(conn: Connection, name: &'static str) -> Self {
    Self { conn, name, joinable: HashMap::new(), delta_joinable: HashMap::new(), gamma_joinable: HashMap::new() }
  }

  pub fn add_joinable<T: PersistentJoinable + 'static>(&mut self, name: &'static str)
  where
    T::State: Serde,
    T::Action: Serde,
  {
    assert!(!self.joinable.contains_key(name));
    assert!(!self.delta_joinable.contains_key(name));
    assert!(!self.gamma_joinable.contains_key(name));
    let txn = self.conn.transaction().unwrap();
    self.joinable.insert(name, Box::new(T::initial(&txn, self.name, name)));
    txn.commit().unwrap();
  }

  pub fn add_delta_joinable<T: PersistentDeltaJoinable + 'static>(&mut self, name: &'static str)
  where
    T::State: Serde,
    T::Action: Serde,
  {
    assert!(!self.joinable.contains_key(name));
    assert!(!self.delta_joinable.contains_key(name));
    assert!(!self.gamma_joinable.contains_key(name));
    let txn = self.conn.transaction().unwrap();
    self.delta_joinable.insert(name, Box::new(T::initial(&txn, self.name, name)));
    txn.commit().unwrap();
  }

  pub fn add_gamma_joinable<T: PersistentGammaJoinable + 'static>(&mut self, name: &'static str)
  where
    T::State: Serde,
    T::Action: Serde,
  {
    assert!(!self.joinable.contains_key(name));
    assert!(!self.delta_joinable.contains_key(name));
    assert!(!self.gamma_joinable.contains_key(name));
    let txn = self.conn.transaction().unwrap();
    self.gamma_joinable.insert(name, Box::new(T::initial(&txn, self.name, name)));
    txn.commit().unwrap();
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
