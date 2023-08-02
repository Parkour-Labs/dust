use rusqlite::{Connection, DropBehavior, Transaction, TransactionBehavior};
use std::collections::HashMap;

use crate::joinable::Clock;
use crate::observable::{
  crdt::{ObjectGraph, ObjectGraphAggregator, ObjectSet},
  Aggregator, ObservablePersistentState, SetEvent,
};
use crate::persistent::vector_history::VectorHistory;

#[derive(Debug, Clone)]
struct Aggregators {
  atoms: Aggregator<Option<Vec<u8>>>,
  nodes: Aggregator<Option<u64>>,
  edges: Aggregator<Option<(u128, u64, u128)>>,
  id_sets: Aggregator<SetEvent<u128>>,
}

impl Aggregators {
  fn new() -> Self {
    Self { atoms: Aggregator::new(), nodes: Aggregator::new(), edges: Aggregator::new(), id_sets: Aggregator::new() }
  }

  fn atoms(&mut self) -> &mut Aggregator<Option<Vec<u8>>> {
    &mut self.atoms
  }

  fn graph(&mut self) -> ObjectGraphAggregator {
    ObjectGraphAggregator {
      node_aggregator: &mut self.nodes,
      edge_aggregator: &mut self.edges,
      id_set_aggregator: &mut self.id_sets,
    }
  }
}

#[derive(Debug)]
pub struct ObjectStore {
  connection: Connection,
  // name: &'static str,
  vector_history: VectorHistory,

  atoms: ObjectSet,
  graph: ObjectGraph,
  aggregators: Aggregators,
}

/// Starts an *auto-commit* transaction.
fn txn(connection: &mut Connection) -> Transaction<'_> {
  let mut res = connection.transaction_with_behavior(TransactionBehavior::Immediate).unwrap();
  res.set_drop_behavior(DropBehavior::Commit);
  res
}

impl ObjectStore {
  pub fn new(mut connection: Connection, name: &'static str) -> Self {
    let mut txn = txn(&mut connection);
    let vector_history = VectorHistory::new(&mut txn, name);
    let atoms = ObjectSet::new(&mut txn, name, "atoms");
    let graph = ObjectGraph::new(&mut txn, name, "graph");
    std::mem::drop(txn);
    Self { connection, vector_history, atoms, graph, aggregators: Aggregators::new() }
  }

  fn this(&self) -> u128 {
    self.vector_history.this()
  }
  fn new_clock(&self) -> Clock {
    Clock::new(self.vector_history.latest())
  }
  fn atoms_apply(&mut self, replica: u128, clock: Clock, action: <ObjectSet as ObservablePersistentState>::Action) {
    let mut txn = txn(&mut self.connection);
    if self
      .vector_history
      .push(&mut txn, (replica, clock, String::from("atoms"), postcard::to_allocvec(&action).unwrap()))
      .is_some()
    {
      self.atoms.apply(&mut txn, self.aggregators.atoms(), action);
    }
  }
  fn graph_apply(&mut self, replica: u128, clock: Clock, action: <ObjectGraph as ObservablePersistentState>::Action) {
    let mut txn = txn(&mut self.connection);
    if self
      .vector_history
      .push(&mut txn, (replica, clock, String::from("graph"), postcard::to_allocvec(&action).unwrap()))
      .is_some()
    {
      self.graph.apply(&mut txn, &mut self.aggregators.graph(), action);
    }
  }

  pub fn node(&mut self, id: u128) -> Option<u64> {
    self.graph.node(&mut txn(&mut self.connection), id)
  }
  pub fn atom(&mut self, id: u128) -> Option<&[u8]> {
    self.atoms.get(&mut txn(&mut self.connection), id)
  }
  pub fn edge(&mut self, id: u128) -> Option<(u128, u64, u128)> {
    self.graph.edge(&mut txn(&mut self.connection), id)
  }
  pub fn query_edge_src(&mut self, src: u128) -> Vec<u128> {
    self.graph.query_edge_src(&mut txn(&mut self.connection), src)
  }
  pub fn query_edge_src_label(&mut self, src: u128, label: u64) -> Vec<u128> {
    self.graph.query_edge_src_label(&mut txn(&mut self.connection), src, label)
  }
  pub fn query_edge_dst_label(&mut self, dst: u128, label: u64) -> Vec<u128> {
    self.graph.query_edge_dst_label(&mut txn(&mut self.connection), dst, label)
  }

  pub fn set_node(&mut self, id: u128, value: Option<u64>) {
    let clock = self.new_clock();
    self.graph_apply(self.this(), clock, ObjectGraph::action_node(clock, id, value));
  }
  pub fn set_atom(&mut self, id: u128, value: Option<Vec<u8>>) {
    let clock = self.new_clock();
    self.atoms_apply(self.this(), clock, ObjectSet::action(clock, id, value));
  }
  pub fn set_edge(&mut self, id: u128, value: Option<(u128, u64, u128)>) {
    let clock = self.new_clock();
    self.graph_apply(self.this(), clock, ObjectGraph::action_edge(clock, id, value));
  }
  pub fn set_edge_dst(&mut self, id: u128, dst: u128) {
    if let Some((src, label, _)) = self.edge(id) {
      self.set_edge(id, Some((src, label, dst)));
    }
  }

  pub fn subscribe_node(&mut self, id: u128, port: u64) {
    self.graph.subscribe_node(&mut txn(&mut self.connection), &mut self.aggregators.graph(), id, port);
  }
  pub fn unsubscribe_node(&mut self, id: u128, port: u64) {
    self.graph.unsubscribe_node(id, port);
  }
  pub fn subscribe_atom(&mut self, id: u128, port: u64) {
    self.atoms.subscribe(&mut txn(&mut self.connection), self.aggregators.atoms(), id, port);
  }
  pub fn unsubscribe_atom(&mut self, id: u128, port: u64) {
    self.atoms.unsubscribe(id, port);
  }
  pub fn subscribe_edge(&mut self, id: u128, port: u64) {
    self.graph.subscribe_edge(&mut txn(&mut self.connection), &mut self.aggregators.graph(), id, port);
  }
  pub fn unsubscribe_edge(&mut self, id: u128, port: u64) {
    self.graph.unsubscribe_edge(id, port);
  }
  pub fn subscribe_multiedge(&mut self, src: u128, label: u64, port: u64) {
    self.graph.subscribe_multiedge(&mut txn(&mut self.connection), &mut self.aggregators.graph(), src, label, port);
  }
  pub fn unsubscribe_multiedge(&mut self, src: u128, label: u64, port: u64) {
    self.graph.unsubscribe_multiedge(src, label, port);
  }
  pub fn subscribe_backedge(&mut self, dst: u128, label: u64, port: u64) {
    self.graph.subscribe_backedge(&mut txn(&mut self.connection), &mut self.aggregators.graph(), dst, label, port);
  }
  pub fn unsubscribe_backedge(&mut self, dst: u128, label: u64, port: u64) {
    self.graph.unsubscribe_backedge(dst, label, port);
  }

  pub fn sync_clocks(&mut self) -> Vec<u8> {
    let clocks = self.vector_history.latests();
    postcard::to_allocvec::<HashMap<u128, Option<Clock>>>(&clocks).unwrap()
  }
  pub fn sync_actions(&mut self, clocks: &[u8]) -> Vec<u8> {
    let clocks = postcard::from_bytes::<HashMap<u128, Option<Clock>>>(clocks).unwrap();
    let actions = self.vector_history.collect(&mut txn(&mut self.connection), clocks);
    postcard::to_allocvec::<Vec<(u128, Clock, String, Vec<u8>)>>(&actions).unwrap()
  }
  pub fn sync_apply(&mut self, actions: &[u8]) {
    let mut txn = txn(&mut self.connection);
    let actions = postcard::from_bytes::<Vec<(u128, Clock, String, Vec<u8>)>>(actions).unwrap();
    for (_replica, _clock, name, action) in self.vector_history.append(&mut txn, actions) {
      match name.as_str() {
        "atoms" => {
          let action = postcard::from_bytes(&action).unwrap();
          self.atoms.apply(&mut txn, self.aggregators.atoms(), action);
        }
        "graph" => {
          let action = postcard::from_bytes(&action).unwrap();
          self.graph.apply(&mut txn, &mut self.aggregators.graph(), action);
        }
        _ => {}
      }
    }
  }
}
