//! A *persistent* last-writer-win register.

use rusqlite::OptionalExtension;
use serde::de::DeserializeOwned;
use serde::ser::Serialize;

use crate::joinable::{crdt as jcrdt, Clock};
use crate::joinable::{Minimum, State};

/// A *persistent* last-writer-win register.
pub struct Register<T: Minimum + Serialize + DeserializeOwned> {
  inner: jcrdt::Register<T>,
  name: &'static str,
}

impl<T: Minimum + Serialize + DeserializeOwned> Register<T> {
  /// Loads or creates a minimum register.
  pub fn new<S: RegisterStore<T>>(store: &S, name: &'static str, default: impl FnOnce() -> T) -> Self {
    store.init(name);
    let (clock, value) = store.get(name).unwrap_or((Clock::minimum(), default()));
    Self { inner: jcrdt::Register::from(clock, value), name }
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
  pub fn action(clock: Clock, value: T) -> <jcrdt::Register<T> as State>::Action {
    jcrdt::Register::action(clock, value)
  }
  /// Updates clock and value.
  pub fn apply<S: RegisterStore<T>>(&mut self, store: &S, action: <jcrdt::Register<T> as State>::Action) {
    self.inner.apply(action);
    store.set(self.name, (self.inner.clock(), self.inner.value()));
  }
}

/// Database interface for [`Register`].
pub trait RegisterStore<T: Minimum + Serialize + DeserializeOwned> {
  fn init(&self, name: &str);
  fn get(&self, name: &str) -> Option<(Clock, T)>;
  fn set(&self, name: &str, data: (Clock, &T));
}

/// Implementation of [`RegisterStore`] using SQLite.
impl<'a, T: Minimum + Serialize + DeserializeOwned> RegisterStore<T> for rusqlite::Transaction<'a> {
  fn init(&self, name: &str) {
    self
      .prepare_cached(&format!(
        "CREATE TABLE IF NOT EXISTS \"{name}\" (clock BLOB NOT NULL, data BLOB NOT NULL) STRICT"
      ))
      .unwrap()
      .execute(())
      .unwrap();
  }

  fn get(&self, name: &str) -> Option<(Clock, T)> {
    self
      .prepare_cached(&format!("SELECT clock, data FROM \"{name}\" WHERE rowid = 0"))
      .unwrap()
      .query_row((), |row| {
        Ok((Clock::from_be_bytes(row.get(0)?), postcard::from_bytes(row.get_ref(1)?.as_blob()?).unwrap()))
      })
      .optional()
      .unwrap()
  }

  fn set(&self, name: &str, data: (Clock, &T)) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}\" (rowid, clock, data) VALUES (0, ?, ?)"))
      .unwrap()
      .execute((data.0.to_u128().to_be_bytes(), postcard::to_allocvec(data.1).unwrap()))
      .unwrap();
  }
}
