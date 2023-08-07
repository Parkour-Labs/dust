//! A *persistent* last-writer-win object graph.

use rusqlite::{OptionalExtension, Transaction};
use std::collections::HashSet;

use crate::joinable::{crdt as jcrdt, Clock, Joinable, State};
use crate::persistent::{PersistentGammaJoinable, PersistentJoinable, PersistentState};

/// A *persistent* last-writer-win object graph.
#[derive(Debug, Clone)]
pub struct ObjectGraph {
  inner: jcrdt::ObjectGraph,
  loaded: (HashSet<u128>, HashSet<u128>),
  collection: &'static str,
  name: &'static str,
}

impl ObjectGraph {
  /// Creates or loads data.
  pub fn new(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    txn
      .execute_batch(&format!(
        "
CREATE TABLE IF NOT EXISTS \"{collection}.{name}.nodes\" (
  id BLOB NOT NULL,
  clock BLOB NOT NULL,
  label BLOB,
  PRIMARY KEY (id)
) STRICT, WITHOUT ROWID;
CREATE INDEX IF NOT EXISTS \"{collection}.{name}.nodes.idx_label\" ON \"{collection}.{name}.nodes\" (label);

CREATE TABLE IF NOT EXISTS \"{collection}.{name}.edges\" (
  id BLOB NOT NULL,
  clock BLOB NOT NULL,
  src BLOB,
  label BLOB,
  dst BLOB,
  PRIMARY KEY (id)
) STRICT, WITHOUT ROWID;
CREATE INDEX IF NOT EXISTS \"{collection}.{name}.edges.idx_src_label\" ON \"{collection}.{name}.edges\" (src, label);
CREATE INDEX IF NOT EXISTS \"{collection}.{name}.edges.idx_dst_label\" ON \"{collection}.{name}.edges\" (dst, label);
        "
      ))
      .unwrap();
    Self { inner: jcrdt::ObjectGraph::new(), loaded: (HashSet::new(), HashSet::new()), collection, name }
  }

  /// Queries all nodes with given label.
  pub fn query_node_label(&self, txn: &mut Transaction, label: u64) -> Vec<u128> {
    let col = self.collection;
    let name = self.name;
    txn
      .prepare_cached(&format!(
        "SELECT id FROM \"{col}.{name}.nodes\" INDEXED BY \"{col}.{name}.nodes.idx_label\" WHERE label = ?"
      ))
      .unwrap()
      .query_map((label.to_be_bytes(),), |row| Ok(u128::from_be_bytes(row.get(0).unwrap())))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  /// Queries all edges with given source.
  pub fn query_edge_src(&self, txn: &mut Transaction, src: u128) -> Vec<u128> {
    let col = self.collection;
    let name = self.name;
    txn
      .prepare_cached(&format!(
        "SELECT id FROM \"{col}.{name}.edges\" INDEXED BY \"{col}.{name}.edges.idx_src_label\" WHERE src = ?"
      ))
      .unwrap()
      .query_map((src.to_be_bytes(),), |row| Ok(u128::from_be_bytes(row.get(0).unwrap())))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  /// Queries all edges with given source and label.
  pub fn query_edge_src_label(&self, txn: &mut Transaction, src: u128, label: u64) -> Vec<u128> {
    let col = self.collection;
    let name = self.name;
    txn
      .prepare_cached(&format!(
        "SELECT id FROM \"{col}.{name}.edges\" INDEXED BY \"{col}.{name}.edges.idx_src_label\" WHERE src = ? AND label = ?"
      ))
      .unwrap()
      .query_map((src.to_be_bytes(),label.to_be_bytes()), |row| Ok(u128::from_be_bytes(row.get(0).unwrap())))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  /// Queries all edges with given destination and label.
  pub fn query_edge_dst_label(&self, txn: &mut Transaction, dst: u128, label: u64) -> Vec<u128> {
    let col = self.collection;
    let name = self.name;
    txn
      .prepare_cached(&format!(
        "SELECT id FROM \"{col}.{name}.edges\" INDEXED BY \"{col}.{name}.edges.idx_dst_label\" WHERE dst = ? AND label = ?"
      ))
      .unwrap()
      .query_map((dst.to_be_bytes(),label.to_be_bytes()), |row| Ok(u128::from_be_bytes(row.get(0).unwrap())))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  /// Loads node.
  pub fn load_node(&mut self, txn: &mut Transaction, id: u128) {
    if self.loaded.0.insert(id) {
      let col = self.collection;
      let name = self.name;
      let opt = txn
        .prepare_cached(&format!("SELECT clock, label FROM \"{col}.{name}.nodes\" WHERE id = ?"))
        .unwrap()
        .query_row((id.to_be_bytes(),), |row| {
          let clock = row.get(0).unwrap();
          let label: Option<_> = row.get(1).unwrap();
          Ok(jcrdt::Register::from(Clock::from_be_bytes(clock), label.map(u64::from_be_bytes)))
        })
        .optional()
        .unwrap();
      self.inner.inner.0.insert(id, opt.unwrap_or_default());
    }
  }

  /// Loads edge.
  pub fn load_edge(&mut self, txn: &mut Transaction, id: u128) {
    if self.loaded.1.insert(id) {
      let col = self.collection;
      let name = self.name;
      let opt = txn
        .prepare_cached(&format!("SELECT clock, src, label, dst FROM \"{col}.{name}.edges\" WHERE id = ?"))
        .unwrap()
        .query_row((id.to_be_bytes(),), |row| {
          let clock = row.get(0).unwrap();
          let src: Option<_> = row.get(1).unwrap();
          let label: Option<_> = row.get(2).unwrap();
          let dst: Option<_> = row.get(3).unwrap();
          Ok(jcrdt::Register::from(
            Clock::from_be_bytes(clock),
            label.map(|label| {
              (u128::from_be_bytes(src.unwrap()), u64::from_be_bytes(label), u128::from_be_bytes(dst.unwrap()))
            }),
          ))
        })
        .optional()
        .unwrap();
      self.inner.inner.1.insert(id, opt.unwrap_or_default());
    }
  }

  /// Saves loaded node.
  pub fn save_node(&self, txn: &mut Transaction, id: u128) {
    if let Some(elem) = self.inner.inner.0.get(&id) {
      let col = self.collection;
      let name = self.name;
      txn
        .prepare_cached(&format!("REPLACE INTO \"{col}.{name}.nodes\" VALUES (?, ?, ?)"))
        .unwrap()
        .execute((id.to_be_bytes(), elem.clock().to_be_bytes(), elem.value().map(|value| value.to_be_bytes())))
        .unwrap();
    }
  }

  /// Saves loaded edge.
  pub fn save_edge(&self, txn: &mut Transaction, id: u128) {
    if let Some(elem) = self.inner.inner.1.get(&id) {
      let col = self.collection;
      let name = self.name;
      txn
        .prepare_cached(&format!("REPLACE INTO \"{col}.{name}.edges\" VALUES (?, ?, ?, ?, ?)"))
        .unwrap()
        .execute((
          id.to_be_bytes(),
          elem.clock().to_be_bytes(),
          elem.value().map(|value| value.0.to_be_bytes()),
          elem.value().map(|value| value.1.to_be_bytes()),
          elem.value().map(|value| value.2.to_be_bytes()),
        ))
        .unwrap();
    }
  }

  /// Unloads node.
  pub fn unload_node(&mut self, id: u128) {
    self.inner.inner.0.remove(&id);
    self.loaded.0.remove(&id);
  }

  /// Unloads edge.
  pub fn unload_edge(&mut self, id: u128) {
    self.inner.inner.1.remove(&id);
    self.loaded.1.remove(&id);
  }

  /// Obtains reference to node value.
  pub fn node(&mut self, txn: &mut Transaction, id: u128) -> Option<u64> {
    self.load_node(txn, id);
    self.inner.node(id)
  }

  /// Obtains reference to edge value.
  pub fn edge(&mut self, txn: &mut Transaction, id: u128) -> Option<(u128, u64, u128)> {
    self.load_edge(txn, id);
    self.inner.edge(id)
  }

  /// Makes modification of node value.
  pub fn action_node(
    &mut self,
    txn: &mut Transaction,
    id: u128,
    value: Option<u64>,
  ) -> <Self as PersistentState>::Action {
    self.load_node(txn, id);
    self.inner.action_node(id, value)
  }

  /// Makes modification of edge value.
  pub fn action_edge(
    &mut self,
    txn: &mut Transaction,
    id: u128,
    value: Option<(u128, u64, u128)>,
  ) -> <Self as PersistentState>::Action {
    self.load_edge(txn, id);
    self.inner.action_edge(id, value)
  }

  fn loads(&mut self, txn: &mut Transaction, nodes: impl Iterator<Item = u128>, edges: impl Iterator<Item = u128>) {
    for id in nodes {
      self.load_node(txn, id);
    }
    for id in edges {
      self.load_edge(txn, id);
    }
  }

  fn saves(&mut self, txn: &mut Transaction, nodes: impl Iterator<Item = u128>, edges: impl Iterator<Item = u128>) {
    for id in nodes {
      self.save_node(txn, id);
    }
    for id in edges {
      self.save_edge(txn, id);
    }
  }

  /// Frees memory.
  pub fn free(&mut self) {
    self.inner = jcrdt::ObjectGraph::new();
    self.loaded = (HashSet::new(), HashSet::new());
  }
}

impl PersistentState for ObjectGraph {
  type State = jcrdt::ObjectGraph;
  type Action = <Self::State as State>::Action;
  type Transaction<'a> = Transaction<'a>;

  fn initial(txn: &mut Transaction, col: &'static str, name: &'static str) -> Self {
    Self::new(txn, col, name)
  }

  fn apply(&mut self, txn: &mut Transaction, a: Self::Action) {
    let nodes: Vec<u128> = a.0.keys().copied().collect();
    let edges: Vec<u128> = a.1.keys().copied().collect();
    self.loads(txn, nodes.iter().copied(), edges.iter().copied());
    self.inner.apply(a);
    self.saves(txn, nodes.into_iter(), edges.into_iter());
  }

  fn id() -> Self::Action {
    jcrdt::ObjectGraph::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    jcrdt::ObjectGraph::comp(a, b)
  }
}

impl PersistentJoinable for ObjectGraph {
  fn preq(&mut self, txn: &mut Transaction, t: &Self::State) -> bool {
    self.loads(txn, t.inner.0.keys().copied(), t.inner.1.keys().copied());
    self.inner.preq(t)
  }

  fn join(&mut self, txn: &mut Transaction, t: Self::State) {
    let nodes: Vec<u128> = t.inner.0.keys().copied().collect();
    let edges: Vec<u128> = t.inner.1.keys().copied().collect();
    self.loads(txn, nodes.iter().copied(), edges.iter().copied());
    self.inner.join(t);
    self.saves(txn, nodes.into_iter(), edges.into_iter());
  }
}

impl PersistentGammaJoinable for ObjectGraph {}
