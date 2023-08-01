//! An *observable* and *persistent* last-writer-win object graph.

use rusqlite::Transaction;
use std::collections::hash_map::Entry;
use std::collections::HashMap;

use crate::joinable::Clock;
use crate::observable::{
  Aggregator, ObservablePersistentGammaJoinable, ObservablePersistentJoinable, ObservablePersistentState, Port,
  SetEvent,
};
use crate::persistent::{crdt as pcrdt, PersistentJoinable, PersistentState};

/// An *observable* and *persistent* last-writer-win object graph.
#[derive(Debug, Clone)]
pub struct ObjectGraph {
  inner: pcrdt::ObjectGraph,
  node_subscriptions: HashMap<u128, Vec<Port>>,
  edge_subscriptions: HashMap<u128, Vec<Port>>,
  multiedge_subscriptions: HashMap<(u128, u64), Vec<Port>>,
  backedge_subscriptions: HashMap<(u128, u64), Vec<Port>>,
}

#[derive(Debug)]
pub struct ObjectGraphAggregator<'a> {
  pub node_aggregator: &'a mut Aggregator<Option<u64>>,
  pub edge_aggregator: &'a mut Aggregator<Option<(u128, u64, u128)>>,
  pub set_aggregator: &'a mut Aggregator<SetEvent<u128>>,
}

impl ObjectGraph {
  /// Creates or loads data.
  pub fn new(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    Self {
      inner: pcrdt::ObjectGraph::new(txn, collection, name),
      node_subscriptions: HashMap::new(),
      edge_subscriptions: HashMap::new(),
      multiedge_subscriptions: HashMap::new(),
      backedge_subscriptions: HashMap::new(),
    }
  }

  /// Queries all nodes with given label.
  pub fn query_node_label(&self, txn: &mut Transaction, label: u64) -> Vec<u128> {
    self.inner.query_node_label(txn, label)
  }

  /// Queries all edges with given source.
  pub fn query_edge_src(&self, txn: &mut Transaction, src: u128) -> Vec<u128> {
    self.inner.query_edge_src(txn, src)
  }

  /// Queries all edges with given source and label.
  pub fn query_edge_src_label(&self, txn: &mut Transaction, src: u128, label: u64) -> Vec<u128> {
    self.inner.query_edge_src_label(txn, src, label)
  }

  /// Queries all edges with given destination and label.
  pub fn query_edge_dst_label(&self, txn: &mut Transaction, dst: u128, label: u64) -> Vec<u128> {
    self.inner.query_edge_dst_label(txn, dst, label)
  }

  /// Loads node.
  pub fn load_node(&mut self, txn: &mut Transaction, id: u128) {
    self.inner.load_node(txn, id)
  }

  /// Loads edge.
  pub fn load_edge(&mut self, txn: &mut Transaction, id: u128) {
    self.inner.load_edge(txn, id)
  }

  /// Saves loaded node.
  pub fn save_node(&self, txn: &mut Transaction, id: u128) {
    self.inner.save_node(txn, id)
  }

  /// Saves loaded edge.
  pub fn save_edge(&self, txn: &mut Transaction, id: u128) {
    self.inner.save_edge(txn, id)
  }

  /// Unloads node.
  pub fn unload_node(&mut self, id: u128) {
    self.inner.unload_node(id)
  }

  /// Unloads edge.
  pub fn unload_edge(&mut self, id: u128) {
    self.inner.unload_edge(id)
  }

  /// Obtains reference to node value.
  pub fn node(&mut self, txn: &mut Transaction, id: u128) -> Option<u64> {
    self.inner.node(txn, id)
  }

  /// Obtains reference to edge value.
  pub fn edge(&mut self, txn: &mut Transaction, id: u128) -> Option<(u128, u64, u128)> {
    self.inner.edge(txn, id)
  }

  /// Makes modification of node value.
  pub fn action_node(clock: Clock, id: u128, value: Option<u64>) -> <Self as ObservablePersistentState>::Action {
    pcrdt::ObjectGraph::action_node(clock, id, value)
  }

  /// Makes modification of edge value.
  pub fn action_edge(
    clock: Clock,
    id: u128,
    value: Option<(u128, u64, u128)>,
  ) -> <Self as ObservablePersistentState>::Action {
    pcrdt::ObjectGraph::action_edge(clock, id, value)
  }

  /// Frees memory.
  pub fn free(&mut self) {
    self.inner.free()
  }

  /// Adds observer.
  pub fn subscribe_node(&mut self, txn: &mut Transaction, ctx: &mut ObjectGraphAggregator<'_>, id: u128, port: Port) {
    self.node_subscriptions.entry(id).or_default().push(port);
    ctx.node_aggregator.push(port, self.node(txn, id));
  }

  /// Adds observer.
  pub fn subscribe_edge(&mut self, txn: &mut Transaction, ctx: &mut ObjectGraphAggregator<'_>, id: u128, port: Port) {
    self.edge_subscriptions.entry(id).or_default().push(port);
    ctx.edge_aggregator.push(port, self.edge(txn, id));
  }

  /// Adds observer.
  pub fn subscribe_multiedge(
    &mut self,
    txn: &mut Transaction,
    ctx: &mut ObjectGraphAggregator<'_>,
    src: u128,
    label: u64,
    port: Port,
  ) {
    self.multiedge_subscriptions.entry((src, label)).or_default().push(port);
    for id in self.query_edge_src_label(txn, src, label) {
      if let Some((src, _, _)) = self.edge(txn, id) {
        ctx.set_aggregator.push(port, SetEvent::Insert(src));
      }
    }
  }

  /// Adds observer.
  pub fn subscribe_backedge(
    &mut self,
    txn: &mut Transaction,
    ctx: &mut ObjectGraphAggregator<'_>,
    dst: u128,
    label: u64,
    port: Port,
  ) {
    self.backedge_subscriptions.entry((dst, label)).or_default().push(port);
    for id in self.query_edge_dst_label(txn, dst, label) {
      if let Some((src, _, _)) = self.edge(txn, id) {
        ctx.set_aggregator.push(port, SetEvent::Insert(src));
      }
    }
  }

  /// Removes observer.
  pub fn unsubscribe_node(&mut self, id: u128, port: Port) {
    if let Entry::Occupied(mut entry) = self.node_subscriptions.entry(id) {
      entry.get_mut().retain(|&x| x != port);
      if entry.get().is_empty() {
        entry.remove();
      }
    }
  }

  /// Removes observer.
  pub fn unsubscribe_edge(&mut self, id: u128, port: Port) {
    if let Entry::Occupied(mut entry) = self.edge_subscriptions.entry(id) {
      entry.get_mut().retain(|&x| x != port);
      if entry.get().is_empty() {
        entry.remove();
      }
    }
  }

  /// Removes observer.
  pub fn unsubscribe_multiedge(&mut self, src: u128, label: u64, port: Port) {
    if let Entry::Occupied(mut entry) = self.multiedge_subscriptions.entry((src, label)) {
      entry.get_mut().retain(|&x| x != port);
      if entry.get().is_empty() {
        entry.remove();
      }
    }
  }

  /// Removes observer.
  pub fn unsubscribe_backedge(&mut self, dst: u128, label: u64, port: Port) {
    if let Entry::Occupied(mut entry) = self.backedge_subscriptions.entry((dst, label)) {
      entry.get_mut().retain(|&x| x != port);
      if entry.get().is_empty() {
        entry.remove();
      }
    }
  }

  fn notifies_pre(
    &mut self,
    txn: &mut Transaction,
    ctx: &mut ObjectGraphAggregator<'_>,
    _nodes: &[u128],
    edges: &[u128],
  ) {
    for &id in edges {
      if let Some((src, label, dst)) = self.inner.edge(txn, id) {
        if let Some(ports) = self.multiedge_subscriptions.get(&(src, label)) {
          for &port in ports {
            ctx.set_aggregator.push(port, SetEvent::Remove(dst));
          }
        }
        if let Some(ports) = self.backedge_subscriptions.get(&(dst, label)) {
          for &port in ports {
            ctx.set_aggregator.push(port, SetEvent::Remove(src));
          }
        }
      }
    }
  }

  fn notifies_post(
    &mut self,
    txn: &mut Transaction,
    ctx: &mut ObjectGraphAggregator<'_>,
    nodes: &[u128],
    edges: &[u128],
  ) {
    for &id in nodes {
      if let Some(ports) = self.node_subscriptions.get(&id) {
        for &port in ports {
          ctx.node_aggregator.push(port, self.inner.node(txn, id));
        }
      }
    }
    for &id in edges {
      if let Some(ports) = self.edge_subscriptions.get(&id) {
        for &port in ports {
          ctx.edge_aggregator.push(port, self.inner.edge(txn, id));
        }
      }
      if let Some((src, label, dst)) = self.inner.edge(txn, id) {
        if let Some(ports) = self.multiedge_subscriptions.get(&(src, label)) {
          for &port in ports {
            ctx.set_aggregator.push(port, SetEvent::Insert(dst));
          }
        }
        if let Some(ports) = self.backedge_subscriptions.get(&(dst, label)) {
          for &port in ports {
            ctx.set_aggregator.push(port, SetEvent::Insert(src));
          }
        }
      }
    }
  }
}

impl ObservablePersistentState for ObjectGraph {
  type State = <pcrdt::ObjectGraph as PersistentState>::State;
  type Action = <pcrdt::ObjectGraph as PersistentState>::Action;
  type Transaction<'a> = Transaction<'a>;
  type Context<'a> = ObjectGraphAggregator<'a>;

  fn initial(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    Self::new(txn, collection, name)
  }

  fn apply(&mut self, txn: &mut Transaction, ctx: &mut ObjectGraphAggregator<'_>, a: Self::Action) {
    let nodes: Vec<u128> = a.0.keys().copied().collect();
    let edges: Vec<u128> = a.1.keys().copied().collect();
    self.notifies_pre(txn, ctx, &nodes, &edges);
    self.inner.apply(txn, a);
    self.notifies_post(txn, ctx, &nodes, &edges);
  }

  fn id() -> Self::Action {
    pcrdt::ObjectGraph::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    pcrdt::ObjectGraph::comp(a, b)
  }
}

impl ObservablePersistentJoinable for ObjectGraph {
  fn preq(&mut self, txn: &mut Transaction, _ctx: &mut ObjectGraphAggregator<'_>, t: &Self::State) -> bool {
    self.inner.preq(txn, t)
  }

  fn join(&mut self, txn: &mut Transaction, ctx: &mut ObjectGraphAggregator<'_>, t: Self::State) {
    let nodes: Vec<u128> = t.inner.0.keys().copied().collect();
    let edges: Vec<u128> = t.inner.1.keys().copied().collect();
    self.notifies_pre(txn, ctx, &nodes, &edges);
    self.inner.join(txn, t);
    self.notifies_post(txn, ctx, &nodes, &edges);
  }
}

impl ObservablePersistentGammaJoinable for ObjectGraph {}
