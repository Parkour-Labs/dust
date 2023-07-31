//! A *persistent* last-writer-win element map.

use rusqlite::{OptionalExtension, Transaction};
use std::collections::HashSet;

use crate::joinable::{crdt as jcrdt, Clock, Joinable, State};
use crate::persistent::{PersistentGammaJoinable, PersistentJoinable, PersistentState};

/// A *persistent* last-writer-win element map.
pub struct ObjectSet {
  inner: jcrdt::ObjectSet,
  loaded: HashSet<u128>,
  collection: &'static str,
  name: &'static str,
}

impl ObjectSet {
  /// Creates or loads data.
  pub fn new(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    txn
      .execute_batch(&format!(
        "
CREATE TABLE IF NOT EXISTS \"{collection}.{name}\" (
  id BLOB NOT NULL,
  clock BLOB NOT NULL,
  value BLOB,
  PRIMARY KEY (id)
) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
    Self { inner: jcrdt::ObjectSet::new(), loaded: HashSet::new(), collection, name }
  }

  /// Loads element.
  pub fn load(&mut self, txn: &mut Transaction, id: u128) {
    if self.loaded.insert(id) {
      let col = self.collection;
      let name = self.name;
      let opt = txn
        .prepare_cached(&format!("SELECT clock, value FROM \"{col}.{name}\" WHERE id = ?"))
        .unwrap()
        .query_row((id.to_be_bytes(),), |row| {
          let clock = row.get(0).unwrap();
          let value = row.get(1).unwrap();
          Ok(jcrdt::Register::from(Clock::from_be_bytes(clock), value))
        })
        .optional()
        .unwrap();
      self.inner.inner.insert(id, opt.unwrap_or_default());
    }
  }

  /// Saves loaded element.
  pub fn save(&self, txn: &mut Transaction, id: u128) {
    if let Some(elem) = self.inner.inner.get(&id) {
      let col = self.collection;
      let name = self.name;
      txn
        .prepare_cached(&format!("REPLACE INTO \"{col}.{name}\" VALUES (?, ?, ?)"))
        .unwrap()
        .execute((id.to_be_bytes(), elem.clock().to_u128().to_be_bytes(), elem.value()))
        .unwrap();
    }
  }

  /// Unloads element.
  pub fn unload(&mut self, id: u128) {
    self.inner.inner.remove(&id);
    self.loaded.remove(&id);
  }

  /// Obtains reference to element.
  pub fn get(&mut self, txn: &mut Transaction, id: u128) -> Option<&[u8]> {
    self.load(txn, id);
    self.inner.get(id)
  }

  /// Makes modification of element.
  pub fn action(clock: Clock, id: u128, value: Option<Vec<u8>>) -> <Self as PersistentState>::Action {
    jcrdt::ObjectSet::action(clock, id, value)
  }

  fn loads(&mut self, txn: &mut Transaction, ids: impl Iterator<Item = u128>) {
    for id in ids {
      self.load(txn, id);
    }
  }

  fn saves(&mut self, txn: &mut Transaction, ids: impl Iterator<Item = u128>) {
    for id in ids {
      self.save(txn, id);
    }
  }

  /// Frees memory.
  pub fn free(&mut self) {
    self.inner = jcrdt::ObjectSet::new();
    self.loaded = HashSet::new();
  }
}

impl PersistentState for ObjectSet {
  type State = jcrdt::ObjectSet;
  type Action = <Self::State as State>::Action;
  type Transaction<'a> = Transaction<'a>;

  fn initial(txn: &mut Transaction, col: &'static str, name: &'static str) -> Self {
    Self::new(txn, col, name)
  }

  fn apply(&mut self, txn: &mut Transaction, a: Self::Action) {
    let ids: Vec<u128> = a.keys().copied().collect();
    self.loads(txn, ids.iter().copied());
    self.inner.apply(a);
    self.saves(txn, ids.into_iter());
  }

  fn id() -> Self::Action {
    jcrdt::ObjectSet::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    jcrdt::ObjectSet::comp(a, b)
  }
}

impl PersistentJoinable for ObjectSet {
  fn preq(&mut self, txn: &mut Transaction, t: &Self::State) -> bool {
    self.loads(txn, t.inner.keys().copied());
    self.inner.preq(t)
  }

  fn join(&mut self, txn: &mut Transaction, t: Self::State) {
    let ids: Vec<u128> = t.inner.keys().copied().collect();
    self.loads(txn, ids.iter().copied());
    self.inner.join(t);
    self.saves(txn, ids.into_iter());
  }
}

impl PersistentGammaJoinable for ObjectSet {}
