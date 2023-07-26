//! A *persistent* last-writer-win register.

use rusqlite::{OptionalExtension, Transaction};

use crate::joinable::{crdt as jcrdt, Clock, Joinable};
use crate::joinable::{Minimum, State};
use crate::persistent::{PersistentJoinable, PersistentState, Serde};

/// A *persistent* last-writer-win register.
pub struct Register<T: Minimum + Serde> {
  inner: jcrdt::Register<T>,
}

impl<T: Minimum + Serde> Register<T> {
  /// Creates or loads data.
  pub fn new(txn: &Transaction, col: &str, name: &str) -> Self {
    txn
      .execute_batch(&format!(
        "
CREATE TABLE IF NOT EXISTS \"{col}.{name}\" (
  id BLOB NOT NULL,
  clock BLOB NOT NULL,
  data BLOB NOT NULL,
  PRIMARY KEY (id)
) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
    let opt = txn
      .prepare_cached(&format!("SELECT clock, data FROM \"{col}.{name}\" WHERE id = X''"))
      .unwrap()
      .query_row((), |row| {
        Ok(jcrdt::Register::from(
          Clock::from_be_bytes(row.get(0)?),
          postcard::from_bytes(row.get_ref(1)?.as_blob()?).unwrap(),
        ))
      })
      .optional()
      .unwrap();
    Self { inner: opt.unwrap_or_default() }
  }
  /// Saves data.
  pub fn save(&self, txn: &Transaction, col: &str, name: &str) {
    txn
      .prepare_cached(&format!("REPLACE INTO \"{col}.{name}\" (id, clock, data) VALUES (X'', ?, ?)"))
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

impl<T: Minimum + Serde> PersistentState for Register<T> {
  type State = jcrdt::Register<T>;
  type Action = <Self::State as State>::Action;

  fn initial(txn: &Transaction, col: &str, name: &str) -> Self {
    Self::new(txn, col, name)
  }

  fn apply(&mut self, txn: &Transaction, col: &str, name: &str, a: Self::Action) {
    self.inner.apply(a);
    self.save(txn, col, name);
  }

  fn id() -> Self::Action {
    jcrdt::Register::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    jcrdt::Register::comp(a, b)
  }
}

impl<T: Minimum + Serde> PersistentJoinable for Register<T> {
  fn preq(&mut self, _txn: &Transaction, _collection: &str, _name: &str, t: &Self::State) -> bool {
    self.inner.preq(t)
  }

  fn join(&mut self, _txn: &Transaction, _collection: &str, _name: &str, t: Self::State) {
    self.inner.join(t)
  }
}
