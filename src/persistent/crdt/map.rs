//! A *persistent* last-writer-win element map.

use rusqlite::{OptionalExtension, Transaction};
use std::collections::HashSet;

use crate::joinable::{crdt as jcrdt, Clock, GammaJoinable, Id, Joinable, State};
use crate::persistent::{PersistentGammaJoinable, PersistentJoinable, PersistentState, Serde};

/// A *persistent* last-writer-win element map.
pub struct Map<I: Id + Serde, T: Ord + Serde> {
  inner: jcrdt::Map<I, T>,
  loaded: HashSet<I>,
}

impl<I: Id + Serde, T: Ord + Serde> Map<I, T> {
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
    Self { inner: jcrdt::Map::new(), loaded: HashSet::new() }
  }
  /// Loads element.
  pub fn load(&mut self, txn: &Transaction, col: &str, name: &str, id: &I) {
    if self.loaded.insert(id.clone()) {
      let opt = txn
        .prepare_cached(&format!("SELECT clock, data FROM \"{col}.{name}\" WHERE id = ?"))
        .unwrap()
        .query_row((postcard::to_allocvec(id).unwrap(),), |row| {
          Ok(jcrdt::Register::from(
            Clock::from_be_bytes(row.get(0)?),
            postcard::from_bytes(row.get_ref(1)?.as_blob()?).unwrap(),
          ))
        })
        .optional()
        .unwrap();
      self.inner.inner.insert(id.clone(), opt.unwrap_or_default());
    }
  }
  /// Saves loaded element.
  pub fn save(&self, txn: &Transaction, col: &str, name: &str, id: &I) {
    if let Some(elem) = self.inner.inner.get(id) {
      txn
        .prepare_cached(&format!("REPLACE INTO \"{col}.{name}\" (id, clock, data) VALUES (?, ?, ?)"))
        .unwrap()
        .execute((
          postcard::to_allocvec(id).unwrap(),
          elem.clock().to_u128().to_be_bytes(),
          postcard::to_allocvec(elem.value()).unwrap(),
        ))
        .unwrap();
    }
  }
  /// Unloads element.
  pub fn unload(&mut self, id: &I) {
    self.inner.inner.remove(id);
    self.loaded.remove(id);
  }
  /// Obtains reference to element.
  pub fn get(&mut self, txn: &Transaction, col: &str, name: &str, id: &I) -> Option<&T> {
    self.load(txn, col, name, id);
    self.inner.get(id)
  }
  /// Makes modification of element.
  pub fn action(clock: Clock, id: I, value: Option<T>) -> <Self as PersistentState>::Action {
    jcrdt::Map::action(clock, id, value)
  }
}

impl<I: Id + Serde, T: Ord + Serde> PersistentState for Map<I, T> {
  type State = jcrdt::Map<I, T>;
  type Action = <Self::State as State>::Action;

  fn initial(txn: &Transaction, col: &str, name: &str) -> Self {
    Self::new(txn, col, name)
  }

  fn apply(&mut self, txn: &Transaction, col: &str, name: &str, a: Self::Action) {
    let ids: Vec<I> = a.keys().cloned().collect();
    for id in &ids {
      self.load(txn, col, name, id);
    }
    self.inner.apply(a);
    for id in &ids {
      self.save(txn, col, name, id);
    }
  }

  fn id() -> Self::Action {
    jcrdt::Map::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    jcrdt::Map::comp(a, b)
  }
}

impl<I: Id + Serde, T: Ord + Serde> PersistentJoinable for Map<I, T> {
  fn preq(&mut self, txn: &Transaction, col: &str, name: &str, t: &Self::State) -> bool {
    for id in t.inner.keys() {
      self.load(txn, col, name, id);
    }
    self.inner.preq(t)
  }

  fn join(&mut self, txn: &Transaction, col: &str, name: &str, t: Self::State) {
    let ids: Vec<I> = t.inner.keys().cloned().collect();
    for id in &ids {
      self.load(txn, col, name, id);
    }
    self.inner.join(t);
    for id in &ids {
      self.save(txn, col, name, id);
    }
  }
}

impl<I: Id + Serde, T: Ord + Serde> PersistentGammaJoinable for Map<I, T> {
  fn gamma_join(&mut self, txn: &Transaction, col: &str, name: &str, a: Self::Action) {
    let ids: Vec<I> = a.keys().cloned().collect();
    for id in &ids {
      self.load(txn, col, name, id);
    }
    self.inner.gamma_join(a);
    for id in &ids {
      self.save(txn, col, name, id);
    }
  }
}
