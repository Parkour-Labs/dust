//! A *persistent* last-writer-win register.

use rusqlite::{OptionalExtension, Transaction};
use serde::{de::DeserializeOwned, ser::Serialize};

use crate::joinable::{crdt as jcrdt, Clock, Joinable};
use crate::joinable::{Minimum, State};
use crate::persistent::{PersistentJoinable, PersistentState};

/// A *persistent* last-writer-win register.
pub struct Register<T: Minimum + Serialize + DeserializeOwned> {
  inner: jcrdt::Register<T>,
  collection: &'static str,
  name: &'static str,
}

impl<T: Minimum + Serialize + DeserializeOwned> Register<T> {
  /// Creates or loads data.
  pub fn new(txn: &Transaction, collection: &'static str, name: &'static str) -> Self {
    txn
      .execute_batch(&format!(
        "
CREATE TABLE IF NOT EXISTS \"{collection}.{name}\" (
  id BLOB NOT NULL,
  clock BLOB NOT NULL,
  value BLOB NOT NULL,
  PRIMARY KEY (id)
) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
    let opt = txn
      .prepare_cached(&format!("SELECT clock, value FROM \"{collection}.{name}\" WHERE id = X''"))
      .unwrap()
      .query_row((), |row| {
        let clock = row.get(0).unwrap();
        let value = row.get_ref(1).unwrap().as_blob().unwrap();
        Ok(jcrdt::Register::from(Clock::from_be_bytes(clock), postcard::from_bytes(value).unwrap()))
      })
      .optional()
      .unwrap();
    Self { inner: opt.unwrap_or_default(), collection, name }
  }

  /// Saves data.
  pub fn save(&self, txn: &Transaction) {
    let col = self.collection;
    let name = self.name;
    txn
      .prepare_cached(&format!("REPLACE INTO \"{col}.{name}\" VALUES (X'', ?, ?)"))
      .unwrap()
      .execute((self.inner.clock().to_u128().to_be_bytes(), postcard::to_allocvec(self.inner.value()).unwrap()))
      .unwrap();
  }

  /// Obtains clock.
  pub fn clock(&self) -> Clock {
    self.inner.clock()
  }

  /// Obtains value.
  pub fn value(&self) -> &T {
    self.inner.value()
  }

  /// Makes modification.
  pub fn action(clock: Clock, value: T) -> <Self as PersistentState>::Action {
    jcrdt::Register::action(clock, value)
  }
}

impl<T: Minimum + Serialize + DeserializeOwned> PersistentState for Register<T> {
  type State = jcrdt::Register<T>;
  type Action = <Self::State as State>::Action;

  fn initial(txn: &Transaction, col: &'static str, name: &'static str) -> Self {
    Self::new(txn, col, name)
  }

  fn apply(&mut self, txn: &Transaction, a: Self::Action) {
    self.inner.apply(a);
    self.save(txn);
  }

  fn id() -> Self::Action {
    jcrdt::Register::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    jcrdt::Register::comp(a, b)
  }
}

impl<T: Minimum + Serialize + DeserializeOwned> PersistentJoinable for Register<T> {
  fn preq(&mut self, _txn: &Transaction, t: &Self::State) -> bool {
    self.inner.preq(t)
  }

  fn join(&mut self, _txn: &Transaction, t: Self::State) {
    self.inner.join(t)
  }
}
