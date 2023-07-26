//! A *persistent* last-writer-win object graph.

/*
use rusqlite::{OptionalExtension, Transaction};
use std::collections::HashSet;

use crate::joinable::{crdt as jcrdt, Clock, GammaJoinable, Joinable, State};
use crate::persistent::{PersistentGammaJoinable, PersistentJoinable, PersistentState};

/// A *persistent* last-writer-win object graph.
pub struct ObjectGraph {
  inner: jcrdt::ObjectGraph,
  loaded: (HashSet<u128>, HashSet<u128>),
}

impl ObjectGraph {
  /// Creates or loads data.
  pub fn new(txn: &Transaction, col: &str, name: &str) -> Self {
    txn
      .execute_batch(&format!(
        "
CREATE TABLE IF NOT EXISTS \"{col}.{name}.atoms\" (
  id BLOB NOT NULL,
  src BLOB NOT NULL,
  clock BLOB NOT NULL,
  data BLOB NOT NULL,
  PRIMARY KEY (id)
) STRICT, WITHOUT ROWID;
CREATE INDEX IF NOT EXISTS \"{col}.{name}.atoms.idx\" ON \"{col}.{name}.atoms\" (src);

CREATE TABLE IF NOT EXISTS \"{col}.{name}.edges\" (
  id BLOB NOT NULL,
  src BLOB NOT NULL,
  dst BLOB NOT NULL,
  clock BLOB NOT NULL,
  data BLOB NOT NULL,
  PRIMARY KEY (id)
) STRICT, WITHOUT ROWID;
CREATE INDEX IF NOT EXISTS \"{col}.{name}.edges.idx\" ON \"{col}.{name}.edges\" (src);
CREATE INDEX IF NOT EXISTS \"{col}.{name}.edges.idx\" ON \"{col}.{name}.edges\" (dst);
        "
      ))
      .unwrap();
    Self { inner: jcrdt::ObjectGraph::new(), loaded: (HashSet::new(), HashSet::new()) }
  }
  /// Loads element.
  pub fn load(&mut self, txn: &Transaction, col: &str, name: &str, index: &I) {
    if self.loaded.insert(index.clone()) {
      let opt = txn
        .prepare_cached(&format!("SELECT clock, data FROM \"{col}.{name}\" WHERE index = ?"))
        .unwrap()
        .query_row((postcard::to_allocvec(index).unwrap(),), |row| {
          Ok(jcrdt::Register::from(
            Clock::from_be_bytes(row.get(0)?),
            postcard::from_bytes(row.get_ref(1)?.as_blob()?).unwrap(),
          ))
        })
        .optional()
        .unwrap();
      self.inner.inner.insert(index.clone(), opt.unwrap_or_default());
    }
  }
  /// Saves loaded element.
  pub fn save(&self, txn: &Transaction, col: &str, name: &str, index: &I) {
    if let Some(elem) = self.inner.inner.get(index) {
      txn
        .prepare_cached(&format!("REPLACE INTO \"{col}.{name}\" (index, clock, data) VALUES (?, ?, ?)"))
        .unwrap()
        .execute((
          postcard::to_allocvec(index).unwrap(),
          elem.clock().to_u128().to_be_bytes(),
          postcard::to_allocvec(elem.value()).unwrap(),
        ))
        .unwrap();
    }
  }
  /// Unloads element.
  pub fn unload(&mut self, index: &I) {
    self.inner.inner.remove(index);
    self.loaded.remove(index);
  }
  /// Obtains reference to element.
  pub fn get(&mut self, txn: &Transaction, col: &str, name: &str, index: &I) -> Option<&T> {
    self.load(txn, col, name, index);
    self.inner.get(index)
  }

  /// Obtains reference to atom value.
  pub fn atom(&self, index: u128) -> Option<&(u128, Vec<u8>)> {
    self.inner.0.get(&index)?.value().as_ref()
  }
  /// Obtains reference to edge value.
  pub fn edge(&self, index: u128) -> Option<&(u128, u128, Vec<u8>)> {
    self.inner.1.get(&index)?.value().as_ref()
  }
  /// Makes modification of atom value.
  pub fn action_atom(clock: Clock, index: u128, value: Option<(u128, Vec<u8>)>) -> <Self as PersistentState>::Action {
    jcrdt::ObjectGraph::action_atom(clock, index, value)
  }
  /// Makes modification of edge value.
  pub fn action_edge(
    clock: Clock,
    index: u128,
    value: Option<(u128, u128, Vec<u8>)>,
  ) -> <Self as PersistentState>::Action {
    jcrdt::ObjectGraph::action_edge(clock, index, value)
  }
}

impl PersistentState for ObjectGraph {
  type State = jcrdt::Map<I, T>;
  type Action = <Self::State as State>::Action;

  fn initial(txn: &Transaction, col: &str, name: &str) -> Self {
    Self::new(txn, col, name)
  }

  fn apply(&mut self, txn: &Transaction, col: &str, name: &str, a: Self::Action) {
    let indices: Vec<I> = a.keys().cloned().collect();
    for index in &indices {
      self.load(txn, col, name, index);
    }
    self.inner.apply(a);
    for index in &indices {
      self.save(txn, col, name, index);
    }
  }

  fn id() -> Self::Action {
    jcrdt::Map::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    jcrdt::Map::comp(a, b)
  }
}

impl PersistentJoinable for ObjectGraph {
  fn preq(&mut self, txn: &Transaction, col: &str, name: &str, t: &Self::State) -> bool {
    for index in t.inner.keys() {
      self.load(txn, col, name, index);
    }
    self.inner.preq(t)
  }

  fn join(&mut self, txn: &Transaction, col: &str, name: &str, t: Self::State) {
    let indices: Vec<I> = t.inner.keys().cloned().collect();
    for index in &indices {
      self.load(txn, col, name, index);
    }
    self.inner.join(t);
    for index in &indices {
      self.save(txn, col, name, index);
    }
  }
}

impl PersistentGammaJoinable for ObjectGraph {
  fn gamma_join(&mut self, txn: &Transaction, col: &str, name: &str, a: Self::Action) {
    let indices: Vec<I> = a.keys().cloned().collect();
    for index in &indices {
      self.load(txn, col, name, index);
    }
    self.inner.gamma_join(a);
    for index in &indices {
      self.save(txn, col, name, index);
    }
  }
}
*/
