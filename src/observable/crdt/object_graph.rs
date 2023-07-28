//! An *observable* and *persistent* *persistent* last-writer-win object graph.

use rusqlite::Transaction;
use std::collections::hash_map::Entry;
use std::collections::HashMap;

use crate::joinable::Clock;
use crate::observable::{Aggregator, ObservableGammaJoinable, ObservableJoinable, ObservableState, Port};
use crate::persistent::{crdt as pcrdt, PersistentJoinable, PersistentState};

/// An *observable* and *persistent* *persistent* last-writer-win object graph.
pub struct ObjectGraph {
  inner: pcrdt::ObjectGraph,
  subscriptions: (HashMap<u128, Vec<Port>>, HashMap<u128, Vec<Port>>),
  // backlinks:
}

/*
impl ObjectGraph {
  /// Creates or loads data.
  pub fn new(txn: &Transaction, collection: &'static str, name: &'static str) -> Self {
  }

  /// Queries all nodes with given label.
  pub fn query_node_label(&self, txn: &Transaction, label: u64) -> Vec<u128> {
  }

  /// Queries all edges with given source.
  pub fn query_edge_src(&self, txn: &Transaction, src: u128) -> Vec<u128> {
  }

  /// Queries all edges with given label and destination.
  pub fn query_edge_label_dst(&self, txn: &Transaction, label: u64, dst: u128) -> Vec<u128> {
  }

  /// Loads node.
  pub fn load_node(&mut self, txn: &Transaction, id: u128) {
  }

  /// Loads edge.
  pub fn load_edge(&mut self, txn: &Transaction, id: u128) {
  }

  /// Saves loaded node.
  pub fn save_node(&self, txn: &Transaction, id: u128) {
  }

  /// Saves loaded edge.
  pub fn save_edge(&self, txn: &Transaction, id: u128) {
  }

  /// Unloads node.
  pub fn unload_node(&mut self, id: u128) {
  }

  /// Unloads edge.
  pub fn unload_edge(&mut self, id: u128) {
  }

  /// Obtains reference to node value.
  pub fn node(&mut self, txn: &Transaction, id: u128) -> Option<u64> {
  }

  /// Obtains reference to edge value.
  pub fn edge(&mut self, txn: &Transaction, id: u128) -> Option<(u128, u64, u128)> {
  }

  /// Makes modification of node value.
  pub fn action_node(clock: Clock, id: u128, value: Option<u64>) -> <Self as PersistentState>::Action {
  }

  /// Makes modification of edge value.
  pub fn action_edge(clock: Clock, id: u128, value: Option<(u128, u64, u128)>) -> <Self as PersistentState>::Action {
  }

  pub fn loads(&mut self, txn: &Transaction, ns: impl Iterator<Item = u128>, es: impl Iterator<Item = u128>) {
  }

  pub fn saves(&mut self, txn: &Transaction, ns: impl Iterator<Item = u128>, es: impl Iterator<Item = u128>) {
  }

  pub fn unloads(&mut self, ns: impl Iterator<Item = u128>, es: impl Iterator<Item = u128>) {
  }

  pub fn free(&mut self) {
  }
}

impl PersistentState for ObjectGraph {
  type State = jcrdt::ObjectGraph;
  type Action = <Self::State as State>::Action;

  fn initial(txn: &mut Transaction, col: &'static str, name: &'static str) -> Self {
  }

  fn apply(&mut self, txn: &mut Transaction, a: Self::Action) {
  }

  fn id() -> Self::Action {
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
  }
}

impl PersistentJoinable for ObjectGraph {
  fn preq(&mut self, txn: &mut Transaction, t: &Self::State) -> bool {
  }

  fn join(&mut self, txn: &mut Transaction, t: Self::State) {
  }
}

impl ObservableGammaJoinable for ObjectGraph {}
*/
