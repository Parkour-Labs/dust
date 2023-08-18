use rusqlite::{Connection, DropBehavior, Transaction, TransactionBehavior};
use std::collections::HashMap;

use crate::{
  crdt::sets::{AtomSet, AtomSetEvents, Clock, EdgeSet, EdgeSetEvents, NodeSet, NodeSetEvents},
  deserialize, serialize,
};

#[derive(Debug, Clone)]
pub enum EventData {
  Node { value: Option<u64> },
  Atom { value: Option<Vec<u8>> },
  Edge { value: Option<(u128, u64, u128)> },
  MultiedgeInsert { id: u128, dst: u128 },
  MultiedgeRemove { id: u128, dst: u128 },
  BackedgeInsert { id: u128, src: u128 },
  BackedgeRemove { id: u128, src: u128 },
}

impl NodeSetEvents for Vec<(u64, EventData)> {
  fn push(&mut self, port: u64, value: Option<u64>) {
    self.push((port, EventData::Node { value }))
  }
}

impl AtomSetEvents for Vec<(u64, EventData)> {
  fn push(&mut self, port: u64, value: Option<Vec<u8>>) {
    self.push((port, EventData::Atom { value }))
  }
}

impl EdgeSetEvents for Vec<(u64, EventData)> {
  fn push_edge(&mut self, port: u64, value: Option<(u128, u64, u128)>) {
    self.push((port, EventData::Edge { value }))
  }
  fn push_multiedge_insert(&mut self, port: u64, id: u128, dst: u128) {
    self.push((port, EventData::MultiedgeInsert { id, dst }))
  }
  fn push_multiedge_remove(&mut self, port: u64, id: u128, dst: u128) {
    self.push((port, EventData::MultiedgeRemove { id, dst }))
  }
  fn push_backedge_insert(&mut self, port: u64, id: u128, src: u128) {
    self.push((port, EventData::BackedgeInsert { id, src }))
  }
  fn push_backedge_remove(&mut self, port: u64, id: u128, src: u128) {
    self.push((port, EventData::BackedgeRemove { id, src }))
  }
}

#[derive(Debug)]
pub struct Store {
  conn: Connection,
  nodes: NodeSet,
  atoms: AtomSet,
  edges: EdgeSet,
  events: Vec<(u64, EventData)>,
}

const NODES_NAME: &str = "nodes";
const ATOMS_NAME: &str = "atoms";
const EDGES_NAME: &str = "edges";

/// Starts an *auto-commit* transaction.
fn txn(conn: &mut Connection) -> Transaction<'_> {
  let mut res = conn.transaction_with_behavior(TransactionBehavior::Immediate).unwrap();
  res.set_drop_behavior(DropBehavior::Commit);
  res
}

impl Store {
  pub fn new(mut conn: Connection) -> Self {
    let mut txn = txn(&mut conn);
    let nodes = NodeSet::new(NODES_NAME, &mut txn);
    let atoms = AtomSet::new(ATOMS_NAME, &mut txn);
    let edges = EdgeSet::new(EDGES_NAME, &mut txn);
    std::mem::drop(txn);
    Self { conn, nodes, atoms, edges, events: Vec::new() }
  }

  pub fn node(&mut self, id: u128) -> Option<u64> {
    self.nodes.value(&mut txn(&mut self.conn), id).copied()
  }
  pub fn atom(&mut self, id: u128) -> Option<&[u8]> {
    self.atoms.value(&mut txn(&mut self.conn), id).map(|vec| vec.as_slice())
  }
  pub fn edge(&mut self, id: u128) -> Option<(u128, u64, u128)> {
    self.edges.value(&mut txn(&mut self.conn), id).copied()
  }
  pub fn nodes_by_label(&mut self, label: u64) -> Vec<u128> {
    self.nodes.query_id_by_label(&mut txn(&mut self.conn), label)
  }
  pub fn edges_by_label(&mut self, label: u64) -> Vec<(u128, (u128, u64, u128))> {
    self.edges.query_id_value_by_label(&mut txn(&mut self.conn), label)
  }
  pub fn edges_by_src(&mut self, src: u128) -> Vec<(u128, (u128, u64, u128))> {
    self.edges.query_id_value_by_src(&mut txn(&mut self.conn), src)
  }
  pub fn id_dst_by_src_label(&mut self, src: u128, label: u64) -> Vec<(u128, u128)> {
    self.edges.query_id_dst_by_src_label(&mut txn(&mut self.conn), src, label)
  }
  pub fn id_src_by_dst_label(&mut self, dst: u128, label: u64) -> Vec<(u128, u128)> {
    self.edges.query_id_src_by_dst_label(&mut txn(&mut self.conn), dst, label)
  }

  pub fn set_node(&mut self, id: u128, value: Option<u64>) {
    let this = self.nodes.this();
    let next = self.nodes.next();
    self.nodes.set(&mut txn(&mut self.conn), &mut self.events, (id, next, this, value));
  }
  pub fn set_atom(&mut self, id: u128, value: Option<Vec<u8>>) {
    let this = self.atoms.this();
    let next = self.atoms.next();
    self.atoms.set(&mut txn(&mut self.conn), &mut self.events, (id, next, this, value));
  }
  pub fn set_edge(&mut self, id: u128, value: Option<(u128, u64, u128)>) {
    let this = self.edges.this();
    let next = self.edges.next();
    self.edges.set(&mut txn(&mut self.conn), &mut self.events, (id, next, this, value));
  }
  pub fn set_edge_dst(&mut self, id: u128, dst: u128) {
    if let Some((src, label, _)) = self.edge(id) {
      self.set_edge(id, Some((src, label, dst)));
    }
  }

  pub fn subscribe_node(&mut self, id: u128, port: u64) {
    self.nodes.subscribe(&mut txn(&mut self.conn), &mut self.events, id, port);
  }
  pub fn unsubscribe_node(&mut self, id: u128, port: u64) {
    self.nodes.unsubscribe(id, port);
  }
  pub fn subscribe_atom(&mut self, id: u128, port: u64) {
    self.atoms.subscribe(&mut txn(&mut self.conn), &mut self.events, id, port);
  }
  pub fn unsubscribe_atom(&mut self, id: u128, port: u64) {
    self.atoms.unsubscribe(id, port);
  }
  pub fn subscribe_edge(&mut self, id: u128, port: u64) {
    self.edges.subscribe(&mut txn(&mut self.conn), &mut self.events, id, port);
  }
  pub fn unsubscribe_edge(&mut self, id: u128, port: u64) {
    self.edges.unsubscribe(id, port);
  }
  pub fn subscribe_multiedge(&mut self, src: u128, label: u64, port: u64) {
    self.edges.subscribe_multiedge(&mut txn(&mut self.conn), &mut self.events, src, label, port);
  }
  pub fn unsubscribe_multiedge(&mut self, src: u128, label: u64, port: u64) {
    self.edges.unsubscribe_multiedge(src, label, port);
  }
  pub fn subscribe_backedge(&mut self, dst: u128, label: u64, port: u64) {
    self.edges.subscribe_backedge(&mut txn(&mut self.conn), &mut self.events, dst, label, port);
  }
  pub fn unsubscribe_backedge(&mut self, dst: u128, label: u64, port: u64) {
    self.edges.unsubscribe_backedge(dst, label, port);
  }

  /// To keep backward compatibility, do not change existing strings and type annotations below.
  /// Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_version(&mut self) -> Vec<u8> {
    let nodes_version: &HashMap<u64, Clock> = self.nodes.buckets();
    let atoms_version: &HashMap<u64, Clock> = self.atoms.buckets();
    let edges_version: &HashMap<u64, Clock> = self.edges.buckets();
    let all: HashMap<&str, Vec<u8>> = HashMap::from([
      (NODES_NAME, serialize(nodes_version).unwrap()),
      (ATOMS_NAME, serialize(atoms_version).unwrap()),
      (EDGES_NAME, serialize(edges_version).unwrap()),
    ]);
    serialize(&all).unwrap()
  }

  /// To keep backward compatibility, do not change existing strings and type annotations below.
  /// Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_actions(&mut self, version: &[u8]) -> Vec<u8> {
    let all: HashMap<String, &[u8]> = deserialize(version).unwrap();
    let nodes_version: HashMap<u64, Clock> = all.get(NODES_NAME).map_or(HashMap::new(), |m| deserialize(m).unwrap());
    let atoms_version: HashMap<u64, Clock> = all.get(ATOMS_NAME).map_or(HashMap::new(), |m| deserialize(m).unwrap());
    let edges_version: HashMap<u64, Clock> = all.get(EDGES_NAME).map_or(HashMap::new(), |m| deserialize(m).unwrap());
    let mut txn = txn(&mut self.conn);
    let nodes_actions: Vec<(u128, Clock, u64, Option<u64>)> = self.nodes.actions(&mut txn, nodes_version);
    let atoms_actions: Vec<(u128, Clock, u64, Option<Vec<u8>>)> = self.atoms.actions(&mut txn, atoms_version);
    let edges_actions: Vec<(u128, Clock, u64, Option<(u128, u64, u128)>)> = self.edges.actions(&mut txn, edges_version);
    let all: HashMap<&str, Vec<u8>> = HashMap::from([
      (NODES_NAME, serialize(&nodes_actions).unwrap()),
      (ATOMS_NAME, serialize(&atoms_actions).unwrap()),
      (EDGES_NAME, serialize(&edges_actions).unwrap()),
    ]);
    serialize(&all).unwrap()
  }

  /// To keep backward compatibility, do not change existing strings and type annotations below.
  /// Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_join(&mut self, actions: &[u8]) {
    let all: HashMap<String, &[u8]> = deserialize(actions).unwrap();
    let nodes_actions: Vec<(u128, Clock, u64, Option<u64>)> =
      all.get(NODES_NAME).map_or(Vec::new(), |m| deserialize(m).unwrap());
    let atoms_actions: Vec<(u128, Clock, u64, Option<Vec<u8>>)> =
      all.get(ATOMS_NAME).map_or(Vec::new(), |m| deserialize(m).unwrap());
    let edges_actions: Vec<(u128, Clock, u64, Option<(u128, u64, u128)>)> =
      all.get(EDGES_NAME).map_or(Vec::new(), |m| deserialize(m).unwrap());
    let mut txn = txn(&mut self.conn);
    self.nodes.gamma_join(&mut txn, &mut self.events, nodes_actions);
    self.atoms.gamma_join(&mut txn, &mut self.events, atoms_actions);
    self.edges.gamma_join(&mut txn, &mut self.events, edges_actions);
  }
}
