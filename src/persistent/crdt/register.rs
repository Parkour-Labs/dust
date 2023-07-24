//! A *persistent* last-writer-win register.

use rusqlite::{OptionalExtension, Transaction};

use crate::joinable::{crdt as jcrdt, Clock, Joinable};
use crate::joinable::{Minimum, State};
use crate::persistent::{PersistentJoinable, PersistentState, Serde};

/// A *persistent* last-writer-win register.
pub struct Register<T: Minimum + Serde> {
  inner: jcrdt::Register<T>,
}

impl<T: Minimum + Serde> PersistentState for Register<T> {
  type State = jcrdt::Register<T>;
  type Action = <jcrdt::Register<T> as State>::Action;

  fn initial(txn: &Transaction, name: &str) -> Self {
    txn
      .execute_batch(&format!(
        "CREATE TABLE IF NOT EXISTS \"{name}\" (clock BLOB NOT NULL, data BLOB NOT NULL) STRICT;"
      ))
      .unwrap();
    let opt = txn
      .prepare_cached(&format!("SELECT clock, data FROM \"{name}\" WHERE rowid = 0"))
      .unwrap()
      .query_row((), |row| {
        Ok(jcrdt::Register::from(
          Clock::from_be_bytes(row.get(0).unwrap()),
          postcard::from_bytes(row.get_ref(1).unwrap().as_blob().unwrap()).unwrap(),
        ))
      })
      .optional()
      .unwrap();
    Self { inner: opt.unwrap_or_default() }
  }

  fn apply(&mut self, txn: &Transaction, name: &str, a: Self::Action) {
    self.inner.apply(a);
    txn
      .prepare_cached(&format!("REPLACE INTO \"{name}\" (rowid, clock, data) VALUES (0, ?, ?)"))
      .unwrap()
      .execute((self.inner.clock().to_u128().to_be_bytes(), postcard::to_allocvec(self.inner.value()).unwrap()))
      .unwrap();
  }

  fn id() -> Self::Action {
    jcrdt::Register::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    jcrdt::Register::comp(a, b)
  }
}

impl<T: Minimum + Serde> PersistentJoinable for Register<T> {
  fn preq(&self, _txn: &Transaction, _name: &str, t: &Self::State) -> bool {
    self.inner.preq(t)
  }

  fn join(&mut self, _txn: &Transaction, _name: &str, t: Self::State) {
    self.inner.join(t)
  }
}
