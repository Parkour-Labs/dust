use std::collections::HashMap;

use rusqlite::Transaction;

use super::{PersistentDeltaJoinable, PersistentGammaJoinable, PersistentJoinable, PersistentState, Serde};

trait TypeErasedState {
  fn apply(&mut self, txn: &Transaction, name: &str, a: &[u8]);
}

trait TypeErasedJoinable: TypeErasedState {
  fn preq(&self, txn: &Transaction, name: &str, t: &[u8]) -> bool;
  fn join(&mut self, txn: &Transaction, name: &str, t: &[u8]);
}

trait TypeErasedDeltaJoinable: TypeErasedJoinable {
  fn delta_join(&mut self, txn: &Transaction, name: &str, a: &[u8], b: &[u8]);
}

trait TypeErasedGammaJoinable: TypeErasedJoinable {
  fn gamma_join(&mut self, txn: &Transaction, name: &str, a: &[u8]);
}

impl<T: PersistentState> TypeErasedState for T
where
  T::State: Serde,
  T::Action: Serde,
{
  fn apply(&mut self, txn: &Transaction, name: &str, a: &[u8]) {
    self.apply(txn, name, postcard::from_bytes(a).unwrap())
  }
}

impl<T: PersistentJoinable> TypeErasedJoinable for T
where
  T::State: Serde,
  T::Action: Serde,
{
  fn preq(&self, txn: &Transaction, name: &str, t: &[u8]) -> bool {
    self.preq(txn, name, &postcard::from_bytes(t).unwrap())
  }

  fn join(&mut self, txn: &Transaction, name: &str, t: &[u8]) {
    self.join(txn, name, postcard::from_bytes(t).unwrap())
  }
}

impl<T: PersistentDeltaJoinable> TypeErasedDeltaJoinable for T
where
  T::State: Serde,
  T::Action: Serde,
{
  fn delta_join(&mut self, txn: &Transaction, name: &str, a: &[u8], b: &[u8]) {
    self.delta_join(txn, name, postcard::from_bytes(a).unwrap(), postcard::from_bytes(b).unwrap())
  }
}

impl<T: PersistentGammaJoinable> TypeErasedGammaJoinable for T
where
  T::State: Serde,
  T::Action: Serde,
{
  fn gamma_join(&mut self, txn: &Transaction, name: &str, a: &[u8]) {
    self.gamma_join(txn, name, postcard::from_bytes(a).unwrap())
  }
}

pub struct Controller<'a> {
  joinable: HashMap<&'static str, &'a dyn TypeErasedJoinable>,
  delta_joinable: HashMap<&'static str, &'a dyn TypeErasedDeltaJoinable>,
  gamma_joinable: HashMap<&'static str, &'a dyn TypeErasedGammaJoinable>,
  name: &'static str,
}

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
