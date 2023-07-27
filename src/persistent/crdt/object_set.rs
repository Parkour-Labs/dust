//! A *persistent* last-writer-win element map.

use rusqlite::{OptionalExtension, Transaction};
use std::collections::HashSet;

use crate::joinable::{crdt as jcrdt, Clock, GammaJoinable, Joinable, State};
use crate::persistent::{PersistentGammaJoinable, PersistentJoinable, PersistentState, Serde};

/// A *persistent* last-writer-win element map.
pub struct ObjectSet<T: Ord + Serde> {
  inner: jcrdt::ObjectSet<T>,
  loaded: HashSet<u128>,
  collection: &'static str,
  name: &'static str,
}

impl<T: Ord + Serde> ObjectSet<T> {
  /// Creates or loads data.
  pub fn new(txn: &Transaction, collection: &'static str, name: &'static str) -> Self {
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
  pub fn load(&mut self, txn: &Transaction, id: u128) {
    if self.loaded.insert(id) {
      let col = self.collection;
      let name = self.name;
      let opt = txn
        .prepare_cached(&format!("SELECT clock, value FROM \"{col}.{name}\" WHERE id = ?"))
        .unwrap()
        .query_row((id.to_be_bytes(),), |row| {
          let clock = row.get(0).unwrap();
          let value = row.get_ref(1).unwrap().as_blob_or_null().unwrap();
          Ok(jcrdt::Register::from(
            Clock::from_be_bytes(clock),
            value.map(|value| postcard::from_bytes(value).unwrap()),
          ))
        })
        .optional()
        .unwrap();
      self.inner.inner.insert(id, opt.unwrap_or_default());
    }
  }

  /// Saves loaded element.
  pub fn save(&self, txn: &Transaction, id: u128) {
    if let Some(elem) = self.inner.inner.get(&id) {
      let col = self.collection;
      let name = self.name;
      txn
        .prepare_cached(&format!("REPLACE INTO \"{col}.{name}\" VALUES (?, ?, ?)"))
        .unwrap()
        .execute((
          id.to_be_bytes(),
          elem.clock().to_u128().to_be_bytes(),
          elem.value().as_ref().map(|value| postcard::to_allocvec(value).unwrap()),
        ))
        .unwrap();
    }
  }

  /// Unloads element.
  pub fn unload(&mut self, id: u128) {
    self.inner.inner.remove(&id);
    self.loaded.remove(&id);
  }

  /// Obtains reference to element.
  pub fn get(&mut self, txn: &Transaction, id: u128) -> Option<&T> {
    self.load(txn, id);
    self.inner.get(id)
  }

  /// Makes modification of element.
  pub fn action(clock: Clock, id: u128, value: Option<T>) -> <Self as PersistentState>::Action {
    jcrdt::ObjectSet::action(clock, id, value)
  }

  pub fn loads(&mut self, txn: &Transaction, ids: impl Iterator<Item = u128>) {
    for id in ids {
      self.load(txn, id);
    }
  }

  pub fn saves(&mut self, txn: &Transaction, ids: impl Iterator<Item = u128>) {
    for id in ids {
      self.save(txn, id);
    }
  }

  pub fn unloads(&mut self, ids: impl Iterator<Item = u128>) {
    for id in ids {
      self.unload(id);
    }
  }

  pub fn free(&mut self) {
    self.inner = jcrdt::ObjectSet::new();
    self.loaded = HashSet::new();
  }
}

impl<T: Ord + Serde> PersistentState for ObjectSet<T> {
  type State = jcrdt::ObjectSet<T>;
  type Action = <Self::State as State>::Action;

  fn initial(txn: &Transaction, col: &'static str, name: &'static str) -> Self {
    Self::new(txn, col, name)
  }

  fn apply(&mut self, txn: &Transaction, a: Self::Action) {
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

impl<T: Ord + Serde> PersistentJoinable for ObjectSet<T> {
  fn preq(&mut self, txn: &Transaction, t: &Self::State) -> bool {
    self.loads(txn, t.inner.keys().copied());
    self.inner.preq(t)
  }

  fn join(&mut self, txn: &Transaction, t: Self::State) {
    let ids: Vec<u128> = t.inner.keys().copied().collect();
    self.loads(txn, ids.iter().copied());
    self.inner.join(t);
    self.saves(txn, ids.into_iter());
  }
}

impl<T: Ord + Serde> PersistentGammaJoinable for ObjectSet<T> {
  fn gamma_join(&mut self, txn: &Transaction, a: Self::Action) {
    let ids: Vec<u128> = a.keys().copied().collect();
    self.loads(txn, ids.iter().copied());
    self.inner.gamma_join(a);
    self.saves(txn, ids.into_iter());
  }
}
