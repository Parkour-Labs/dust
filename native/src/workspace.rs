#![allow(clippy::type_complexity)]

pub mod atom_set;
pub mod edge_set;
pub mod metadata;
pub mod node_set;

use rusqlite::Transaction;
use std::{
  borrow::Borrow,
  collections::{btree_map::Entry, BTreeMap, BTreeSet},
};

use self::{atom_set::AtomSet, edge_set::EdgeSet, metadata::WorkspaceMetadata, node_set::NodeSet};
use crate::{
  deserialize,
  ffi::structs::{CAtom, CEdge, CEventData, CNode},
  serialize,
};

pub const NODES_NAME: &str = "nodes";
pub const ATOMS_NAME: &str = "atoms";
pub const EDGES_NAME: &str = "edges";

#[derive(Debug, Clone, Default)]
pub struct Constraints {
  sticky_nodes: BTreeSet<u64>,
  sticky_atoms: BTreeSet<u64>,
  sticky_edges: BTreeSet<u64>,
}

impl Constraints {
  pub fn new() -> Self {
    Default::default()
  }
  pub fn add_sticky_node(&mut self, label: u64) {
    self.sticky_nodes.insert(label);
  }
  pub fn add_sticky_atom(&mut self, label: u64) {
    self.sticky_atoms.insert(label);
  }
  pub fn add_sticky_edge(&mut self, label: u64) {
    self.sticky_edges.insert(label);
  }
}

#[derive(Debug)]
pub struct Workspace {
  metadata: WorkspaceMetadata,
  constraints: Constraints,
  nodes: NodeSet,
  atoms: AtomSet,
  edges: EdgeSet,
  events: Vec<CEventData>,
}

/*
/// Starts an *auto-commit* transaction.
fn txn(conn: &mut Connection) -> Transaction<'_> {
  let mut res = conn.transaction_with_behavior(TransactionBehavior::Immediate).unwrap();
  res.set_drop_behavior(DropBehavior::Commit);
  res
}
*/

impl Workspace {
  pub fn new(prefix: &'static str, constraints: Constraints, txn: &mut Transaction) -> Self {
    let metadata = WorkspaceMetadata::new(prefix, txn);
    let nodes = NodeSet::new(prefix, NODES_NAME, txn);
    let atoms = AtomSet::new(prefix, ATOMS_NAME, txn);
    let edges = EdgeSet::new(prefix, EDGES_NAME, txn);
    Self { metadata, constraints, nodes, atoms, edges, events: Vec::new() }
  }

  pub fn node(&mut self, txn: &mut Transaction, id: u128) -> Option<u64> {
    self.nodes.get(txn, id).and_then(|(_, _, _, label)| label)
  }
  pub fn node_by_label(&mut self, txn: &mut Transaction, label: u64) -> Vec<u128> {
    self.nodes.by_label(txn, label)
  }
  pub fn atom(&mut self, txn: &mut Transaction, id: u128) -> Option<(u128, u64, Box<[u8]>)> {
    self.atoms.get(txn, id).and_then(|(_, _, _, slv)| slv)
  }
  pub fn atom_label_value_by_src(&mut self, txn: &mut Transaction, src: u128) -> Vec<(u128, (u64, Box<[u8]>))> {
    self.atoms.label_value_by_src(txn, src)
  }
  pub fn atom_value_by_src_label(&mut self, txn: &mut Transaction, src: u128, label: u64) -> Vec<(u128, Box<[u8]>)> {
    self.atoms.value_by_src_label(txn, src, label)
  }
  pub fn atom_src_value_by_label(&mut self, txn: &mut Transaction, label: u64) -> Vec<(u128, (u128, Box<[u8]>))> {
    self.atoms.src_value_by_label(txn, label)
  }
  pub fn atom_src_by_label_value(&mut self, txn: &mut Transaction, label: u64, value: &[u8]) -> Vec<(u128, u128)> {
    self.atoms.src_by_label_value(txn, label, value)
  }
  pub fn edge(&mut self, txn: &mut Transaction, id: u128) -> Option<(u128, u64, u128)> {
    self.edges.get(txn, id).and_then(|(_, _, _, sld)| sld)
  }
  pub fn edge_label_dst_by_src(&mut self, txn: &mut Transaction, src: u128) -> Vec<(u128, (u64, u128))> {
    self.edges.label_dst_by_src(txn, src)
  }
  pub fn edge_dst_by_src_label(&mut self, txn: &mut Transaction, src: u128, label: u64) -> Vec<(u128, u128)> {
    self.edges.dst_by_src_label(txn, src, label)
  }
  pub fn edge_src_label_by_dst(&mut self, txn: &mut Transaction, dst: u128) -> Vec<(u128, (u128, u64))> {
    self.edges.src_label_by_dst(txn, dst)
  }
  pub fn edge_src_by_dst_label(&mut self, txn: &mut Transaction, dst: u128, label: u64) -> Vec<(u128, u128)> {
    self.edges.src_by_dst_label(txn, dst, label)
  }

  pub fn set_node_raw(
    txn: &mut Transaction,
    nodes: &mut NodeSet,
    events: &mut Vec<CEventData>,
    id: u128,
    bucket: u64,
    clock: u64,
    label: Option<u64>,
  ) -> bool {
    if let Some(prev) = nodes.set(txn, id, bucket, clock, label) {
      let prev = prev.and_then(|(_, _, _, label)| label);
      events.push(CEventData::Node {
        id: id.into(),
        prev: prev.map(|label| CNode { label }).into(),
        curr: label.map(|label| CNode { label }).into(),
      });
      return true;
    }
    false
  }

  pub fn set_atom_raw(
    txn: &mut Transaction,
    atoms: &mut AtomSet,
    events: &mut Vec<CEventData>,
    id: u128,
    bucket: u64,
    clock: u64,
    slv: Option<(u128, u64, &[u8])>,
  ) -> bool {
    if let Some(prev) = atoms.set(txn, id, bucket, clock, slv) {
      let prev = prev.and_then(|(_, _, _, slv)| slv);
      events.push(CEventData::Atom {
        id: id.into(),
        prev: prev.map(|(src, label, value)| CAtom { src: src.into(), label, value: value.into() }).into(),
        curr: slv.map(|(src, label, value)| CAtom { src: src.into(), label, value: Vec::from(value).into() }).into(),
      });
      return true;
    }
    false
  }

  pub fn set_edge_raw(
    txn: &mut Transaction,
    edges: &mut EdgeSet,
    events: &mut Vec<CEventData>,
    id: u128,
    bucket: u64,
    clock: u64,
    sld: Option<(u128, u64, u128)>,
  ) -> bool {
    if let Some(prev) = edges.set(txn, id, bucket, clock, sld) {
      let prev = prev.and_then(|(_, _, _, sld)| sld);
      events.push(CEventData::Edge {
        id: id.into(),
        prev: prev.map(|(src, label, dst)| CEdge { src: src.into(), label, dst: dst.into() }).into(),
        curr: sld.map(|(src, label, dst)| CEdge { src: src.into(), label, dst: dst.into() }).into(),
      });
      return true;
    }
    false
  }

  pub fn set_node(&mut self, txn: &mut Transaction, id: u128, label: Option<u64>) {
    let this = self.metadata.this();
    let next = self.nodes.next();
    assert!(Self::set_node_raw(txn, &mut self.nodes, &mut self.events, id, this, next, label));
  }

  pub fn set_atom_ref(&mut self, txn: &mut Transaction, id: u128, slv: Option<(u128, u64, &[u8])>) {
    let this = self.metadata.this();
    let next = self.atoms.next();
    assert!(Self::set_atom_raw(txn, &mut self.atoms, &mut self.events, id, this, next, slv));
  }

  pub fn set_atom(&mut self, txn: &mut Transaction, id: u128, slv: Option<(u128, u64, Box<[u8]>)>) {
    let this = self.metadata.this();
    let next = self.atoms.next();
    let slv = slv.as_ref().map(|(src, label, value)| (*src, *label, value.borrow()));
    assert!(Self::set_atom_raw(txn, &mut self.atoms, &mut self.events, id, this, next, slv));
  }

  pub fn set_edge(&mut self, txn: &mut Transaction, id: u128, sld: Option<(u128, u64, u128)>) {
    let this = self.metadata.this();
    let next = self.edges.next();
    assert!(Self::set_edge_raw(txn, &mut self.edges, &mut self.events, id, this, next, sld));
  }

  pub fn gamma_join_nodes_raw(
    txn: &mut Transaction,
    nodes: &mut NodeSet,
    events: &mut Vec<CEventData>,
    mut actions: Vec<(u128, u64, u64, Option<u64>)>,
  ) -> Vec<(u128, u64, u64, Option<u64>)> {
    actions.retain(|(id, bucket, clock, label)| Self::set_node_raw(txn, nodes, events, *id, *bucket, *clock, *label));
    actions
  }

  pub fn gamma_join_atoms_raw(
    txn: &mut Transaction,
    atoms: &mut AtomSet,
    events: &mut Vec<CEventData>,
    mut actions: Vec<(u128, u64, u64, Option<(u128, u64, Box<[u8]>)>)>,
  ) -> Vec<(u128, u64, u64, Option<(u128, u64, Box<[u8]>)>)> {
    actions.retain(|(id, bucket, clock, slv)| {
      let slv = slv.as_ref().map(|(src, label, value)| (*src, *label, value.borrow()));
      Self::set_atom_raw(txn, atoms, events, *id, *bucket, *clock, slv)
    });
    actions
  }

  pub fn gamma_join_edges_raw(
    txn: &mut Transaction,
    edges: &mut EdgeSet,
    events: &mut Vec<CEventData>,
    mut actions: Vec<(u128, u64, u64, Option<(u128, u64, u128)>)>,
  ) -> Vec<(u128, u64, u64, Option<(u128, u64, u128)>)> {
    actions.retain(|(id, bucket, clock, sld)| Self::set_edge_raw(txn, edges, events, *id, *bucket, *clock, *sld));
    actions
  }

  /// Issues write-read barrier: goes through all recent modifications,
  /// performing any additional action required to maintain invariants:
  ///
  /// 1. `atom_implies_node`: all atoms must start from a node.
  /// 2. `edge_implies_node`: all edges must start from and ends at nodes.
  /// 3. `sticky_or_none`: for each node, if it has "sticky" atoms or edges
  ///     attached to it at the previous barrier, those must be preserved,
  ///     otherwise the node must be removed.
  pub fn barrier(&mut self, txn: &mut Transaction) -> Vec<CEventData> {
    let mut mod_nodes = BTreeMap::<u128, (Option<u64>, Option<u64>)>::new();
    let mut mod_atoms = BTreeMap::<u128, (Option<(u128, u64)>, Option<(u128, u64)>)>::new();
    let mut mod_edges = BTreeMap::<u128, (Option<(u128, u64, u128)>, Option<(u128, u64, u128)>)>::new();

    // Find the original and final values of modified elements.
    for event in self.events.iter() {
      match event {
        CEventData::Node { id, prev, curr } => {
          let prev = prev.as_option().map(|CNode { label }| *label);
          let curr = curr.as_option().map(|CNode { label }| *label);
          match mod_nodes.entry((*id).into()) {
            Entry::Vacant(entry) => {
              entry.insert((prev, curr));
            }
            Entry::Occupied(mut entry) => {
              let (orig, _) = entry.get();
              entry.insert((*orig, curr));
            }
          };
        }
        CEventData::Atom { id, prev, curr } => {
          let prev = prev.as_option().map(|CAtom { src, label, value: _ }| ((*src).into(), *label));
          let curr = curr.as_option().map(|CAtom { src, label, value: _ }| ((*src).into(), *label));
          match mod_atoms.entry((*id).into()) {
            Entry::Vacant(entry) => {
              entry.insert((prev, curr));
            }
            Entry::Occupied(mut entry) => {
              let (orig, _) = entry.get();
              entry.insert((*orig, curr));
            }
          };
        }
        CEventData::Edge { id, prev, curr } => {
          let prev = prev.as_option().map(|CEdge { src, label, dst }| ((*src).into(), *label, (*dst).into()));
          let curr = curr.as_option().map(|CEdge { src, label, dst }| ((*src).into(), *label, (*dst).into()));
          match mod_edges.entry((*id).into()) {
            Entry::Vacant(entry) => {
              entry.insert((prev, curr));
            }
            Entry::Occupied(mut entry) => {
              let (orig, _) = entry.get();
              entry.insert((*orig, curr));
            }
          };
        }
      }
    }

    // Assuming all conditions were true before any of the modifications,
    // we only need to focus on changes which cause violations.

    // The set of nodes which definitely violate (3), or possibly are endpoints of atoms/edges violating (1) (2).
    let mut nodes = BTreeSet::<u128>::new();

    for (id, (prev, curr)) in mod_nodes {
      if let Some(label) = prev {
        if self.constraints.sticky_nodes.contains(&label) && !matches!(curr, Some(curr_label) if curr_label == label) {
          nodes.insert(id); // `prev` is sticky, `curr` does not exist or have `label` changed (3)
        }
      }
      if prev.is_some() && curr.is_none() {
        nodes.insert(id); // `curr` node does not exist (1) (2)
      }
    }

    for (id, (prev, curr)) in mod_atoms {
      if let Some((src, label)) = prev {
        if self.constraints.sticky_atoms.contains(&label)
          && !matches!(curr, Some((curr_src, curr_label)) if curr_src == src && curr_label == label)
        {
          nodes.insert(src); // `prev` is sticky, `curr` does not exist or have `src` or `label` changed (3)
        }
      }
      if let Some((src, _)) = curr {
        if !self.nodes.exists(txn, src) {
          self.set_atom(txn, id, None); // `curr` exists, `src` node does not exist (1)
        }
      }
    }

    for (id, (prev, curr)) in mod_edges {
      if let Some((src, label, _)) = prev {
        if self.constraints.sticky_atoms.contains(&label)
          && !matches!(curr, Some((curr_src, curr_label, _)) if curr_src == src && curr_label == label)
        {
          nodes.insert(src); // `prev` is sticky, `curr` does not exist or have `src` or `label` changed (3)
        }
      }
      if let Some((src, label, dst)) = curr {
        if !self.nodes.exists(txn, src) {
          self.set_edge(txn, id, None); // `curr` exists, `src` node does not exist (2)
        }
        if !self.nodes.exists(txn, dst) {
          self.set_edge(txn, id, None); // `curr` exists, `dst` node does not exist (2)
          if self.constraints.sticky_edges.contains(&label) {
            nodes.insert(src); // `curr` is sticky, `curr` is removed (?)
          }
        }
      }
    }

    while let Some(id) = nodes.pop_first() {
      if self.nodes.exists(txn, id) {
        self.set_node(txn, id, None);
      }
      for (atom, _) in self.atom_label_value_by_src(txn, id) {
        self.set_atom(txn, atom, None);
      }
      for (edge, _) in self.edge_label_dst_by_src(txn, id) {
        self.set_edge(txn, edge, None);
      }
      for (edge, (src, label)) in self.edge_src_label_by_dst(txn, id) {
        self.set_edge(txn, edge, None);
        if self.constraints.sticky_edges.contains(&label) {
          nodes.insert(src); // `curr` is sticky, `curr` is removed (?)
        }
      }
    }

    std::mem::take(&mut self.events)
  }

  /// To keep backward compatibility, do not change existing strings and type
  /// annotations below. Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_version(&mut self, _: &mut Transaction) -> Box<[u8]> {
    let nodes_version: &BTreeMap<u64, u64> = self.nodes.buckets();
    let atoms_version: &BTreeMap<u64, u64> = self.atoms.buckets();
    let edges_version: &BTreeMap<u64, u64> = self.edges.buckets();

    let all: BTreeMap<&str, Vec<u8>> = BTreeMap::from([
      (NODES_NAME, serialize(nodes_version).unwrap()),
      (ATOMS_NAME, serialize(atoms_version).unwrap()),
      (EDGES_NAME, serialize(edges_version).unwrap()),
    ]);

    serialize(&all).unwrap().into()
  }

  /// To keep backward compatibility, do not change existing strings and type
  /// annotations below. Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_actions(&mut self, txn: &mut Transaction, version: &[u8]) -> Box<[u8]> {
    let all: BTreeMap<String, &[u8]> = deserialize(version).unwrap();

    let nodes_version: BTreeMap<u64, u64> = all.get(NODES_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());
    let atoms_version: BTreeMap<u64, u64> = all.get(ATOMS_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());
    let edges_version: BTreeMap<u64, u64> = all.get(EDGES_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());

    let nodes_actions: Vec<(u128, u64, u64, Option<u64>)> = self.nodes.actions(txn, nodes_version);
    let atoms_actions: Vec<(u128, u64, u64, Option<(u128, u64, Box<[u8]>)>)> = self.atoms.actions(txn, atoms_version);
    let edges_actions: Vec<(u128, u64, u64, Option<(u128, u64, u128)>)> = self.edges.actions(txn, edges_version);

    let all: BTreeMap<&str, Vec<u8>> = BTreeMap::from([
      (NODES_NAME, serialize(&nodes_actions).unwrap()),
      (ATOMS_NAME, serialize(&atoms_actions).unwrap()),
      (EDGES_NAME, serialize(&edges_actions).unwrap()),
    ]);

    serialize(&all).unwrap().into()
  }

  /// To keep backward compatibility, do not change existing strings and type
  /// annotations below. Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_join(&mut self, txn: &mut Transaction, actions: &[u8]) -> Option<Box<[u8]>> {
    let all: BTreeMap<String, &[u8]> = deserialize(actions).unwrap();

    let nodes_actions: Vec<(u128, u64, u64, Option<u64>)> =
      all.get(NODES_NAME).map_or_else(Vec::new, |m| deserialize(m).unwrap());
    let atoms_actions: Vec<(u128, u64, u64, Option<(u128, u64, Box<[u8]>)>)> =
      all.get(ATOMS_NAME).map_or_else(Vec::new, |m| deserialize(m).unwrap());
    let edges_actions: Vec<(u128, u64, u64, Option<(u128, u64, u128)>)> =
      all.get(EDGES_NAME).map_or_else(Vec::new, |m| deserialize(m).unwrap());

    let nodes_actions: Vec<(u128, u64, u64, Option<u64>)> =
      Self::gamma_join_nodes_raw(txn, &mut self.nodes, &mut self.events, nodes_actions);
    let atoms_actions: Vec<(u128, u64, u64, Option<(u128, u64, Box<[u8]>)>)> =
      Self::gamma_join_atoms_raw(txn, &mut self.atoms, &mut self.events, atoms_actions);
    let edges_actions: Vec<(u128, u64, u64, Option<(u128, u64, u128)>)> =
      Self::gamma_join_edges_raw(txn, &mut self.edges, &mut self.events, edges_actions);

    if nodes_actions.is_empty() && atoms_actions.is_empty() && edges_actions.is_empty() {
      None
    } else {
      let all: BTreeMap<&str, Vec<u8>> = BTreeMap::from([
        (NODES_NAME, serialize(&nodes_actions).unwrap()),
        (ATOMS_NAME, serialize(&atoms_actions).unwrap()),
        (EDGES_NAME, serialize(&edges_actions).unwrap()),
      ]);
      Some(serialize(&all).unwrap().into())
    }
  }
}

#[cfg(test)]
mod tests {
  use core::panic;

  use super::*;
  use rand::{seq::SliceRandom, Rng};
  use rusqlite::Connection;

  #[test]
  fn barrier_simple() {
    let mut conn = Connection::open_in_memory().unwrap();
    let mut rng = rand::thread_rng();
    let mut txn = conn.transaction().unwrap();
    let mut constraints = Constraints::new();
    constraints.add_sticky_node(100);
    constraints.add_sticky_atom(200);
    constraints.add_sticky_edge(300);
    let mut ws = Workspace::new("", constraints, &mut txn);

    let node0 = rng.gen();
    let node1 = rng.gen();
    let node2 = rng.gen();
    let node3 = rng.gen();
    ws.set_node(&mut txn, node0, Some(0));
    ws.set_node(&mut txn, node1, Some(100));
    ws.set_node(&mut txn, node2, Some(0));
    ws.set_node(&mut txn, node3, Some(100));
    ws.set_edge(&mut txn, rng.gen(), Some((node0, 2, node0)));
    ws.set_edge(&mut txn, rng.gen(), Some((node0, 3, node1)));
    ws.set_edge(&mut txn, rng.gen(), Some((node1, 2, node1)));
    ws.set_edge(&mut txn, rng.gen(), Some((node1, 3, node0)));
    ws.set_edge(&mut txn, rng.gen(), Some((node1, 2, 2333))); // Invalid
    ws.set_edge(&mut txn, rng.gen(), Some((2333, 2, node1))); // Invalid
    ws.barrier(&mut txn);
    assert_eq!(ws.node(&mut txn, node0), Some(0));
    assert_eq!(ws.node(&mut txn, node1), Some(100));
    assert_eq!(ws.edge_label_dst_by_src(&mut txn, node0).len(), 2);
    assert_eq!(ws.edge_src_label_by_dst(&mut txn, node0).len(), 2);
    assert_eq!(ws.edge_label_dst_by_src(&mut txn, node1).len(), 2);
    assert_eq!(ws.edge_src_label_by_dst(&mut txn, node1).len(), 2);

    ws.set_node(&mut txn, node0, Some(2333));
    ws.set_node(&mut txn, node1, Some(2333)); // Invalid
    ws.set_edge(&mut txn, rng.gen(), Some((node0, 3, node1))); // Invalid
    ws.set_edge(&mut txn, rng.gen(), Some((node1, 3, node0))); // Invalid
    ws.barrier(&mut txn);
    assert_eq!(ws.node(&mut txn, node0), Some(2333));
    assert_eq!(ws.node(&mut txn, node1), None);
    assert_eq!(ws.edge_label_dst_by_src(&mut txn, node0).len(), 1);
    assert_eq!(ws.edge_src_label_by_dst(&mut txn, node0).len(), 1);
    assert_eq!(ws.edge_label_dst_by_src(&mut txn, node1).len(), 0);
    assert_eq!(ws.edge_src_label_by_dst(&mut txn, node1).len(), 0);

    let atom0 = rng.gen();
    let atom1 = rng.gen();
    let atom2 = rng.gen();
    ws.set_atom(&mut txn, atom0, Some((node0, 1, vec![1, 2, 3, 4].into())));
    ws.set_atom(&mut txn, atom1, Some((node0, 200, vec![].into()))); // Overwritten
    ws.set_atom(&mut txn, atom1, Some((node0, 0, vec![].into()))); // Overwritten
    ws.set_atom(&mut txn, atom1, Some((node0, 200, vec![5, 6, 7].into())));
    ws.set_atom(&mut txn, atom2, Some((node2, 2, vec![].into())));
    ws.barrier(&mut txn);
    assert!(ws.atom(&mut txn, atom0).is_some());
    assert!(ws.atom(&mut txn, atom1).is_some());
    assert!(ws.atom(&mut txn, atom2).is_some());

    ws.set_atom(&mut txn, atom0, Some((node2, 1, vec![].into())));
    ws.set_atom(&mut txn, atom1, Some((node2, 200, vec![].into()))); // Invalid, delete `node0`
    ws.set_atom(&mut txn, atom2, Some((node0, 2, vec![].into()))); // Invalid, `node0` deleted
    ws.barrier(&mut txn);
    assert!(ws.node(&mut txn, node0).is_none());
    assert!(ws.atom(&mut txn, atom0).is_some());
    assert!(ws.atom(&mut txn, atom1).is_some());
    assert!(ws.atom(&mut txn, atom2).is_none());

    let edge0 = rng.gen();
    let edge1 = rng.gen();
    let edge2 = rng.gen();
    let edge3 = rng.gen();
    ws.set_edge(&mut txn, edge0, Some((node3, 1, node0))); // Invalid
    ws.set_edge(&mut txn, edge1, Some((node3, 2, node1))); // Invalid
    ws.set_edge(&mut txn, edge2, Some((node3, 300, node2)));
    ws.set_edge(&mut txn, edge3, Some((node3, 300, node3)));
    ws.barrier(&mut txn);
    assert!(ws.node(&mut txn, node2).is_some());
    assert!(ws.node(&mut txn, node3).is_some());
    assert!(ws.edge(&mut txn, edge0).is_none());
    assert!(ws.edge(&mut txn, edge1).is_none());
    assert!(ws.edge(&mut txn, edge2).is_some());
    assert!(ws.edge(&mut txn, edge3).is_some());

    ws.set_edge(&mut txn, rng.gen(), Some((node2, 300, node0))); // Invalid, delete `node2` (?) and `node3`
    ws.barrier(&mut txn);
    assert!(ws.node(&mut txn, node2).is_none());
    assert!(ws.node(&mut txn, node3).is_none());

    const N: usize = 2333;
    let nodes: Vec<u128> = (0..N + 1).map(|_| rng.gen()).collect();
    let edges: Vec<u128> = (0..N).map(|_| rng.gen()).collect();
    let atom = rng.gen();
    for i in 0..N {
      ws.set_node(&mut txn, nodes[i], Some(0));
      ws.set_edge(&mut txn, edges[i], Some((nodes[i], 300, nodes[i + rng.gen_range(1..=(N - i))])));
    }
    ws.set_node(&mut txn, nodes[N], Some(0));
    ws.set_atom(&mut txn, atom, Some((nodes[N], 200, vec![].into())));
    ws.barrier(&mut txn);
    for i in 0..N {
      assert!(ws.node(&mut txn, nodes[i]).is_some());
      assert!(ws.edge(&mut txn, edges[i]).is_some());
    }
    ws.set_atom(&mut txn, atom, Some((nodes[N], 2333, vec![].into()))); // Invalid, delete `nodes` and `edges`
    ws.barrier(&mut txn);
    for i in 0..N {
      assert!(ws.node(&mut txn, nodes[i]).is_none());
      assert!(ws.edge(&mut txn, edges[i]).is_none());
    }
  }

  #[test]
  fn barrier_random() {
    const K: u64 = 20;
    let mut constraints = Constraints::new();
    for i in 0..K {
      constraints.add_sticky_node(i);
      constraints.add_sticky_atom(i);
      constraints.add_sticky_edge(i);
    }

    for round in 0..100 {
      let mut conn = Connection::open_in_memory().unwrap();
      let mut rng = rand::thread_rng();
      let mut txn = conn.transaction().unwrap();
      let mut ws = Workspace::new("", constraints.clone(), &mut txn);

      let mut nodes = vec![];
      let mut atoms = vec![];
      let mut edges = vec![];

      // Generate nodes.
      for _ in 0..300 {
        let node = rng.gen();
        let label = rng.gen_range(0..K * 2);
        ws.set_node(&mut txn, node, Some(label));
        nodes.push((node, vec![], vec![]));
      }

      // Generate atoms from nodes.
      for _ in 0..1000 {
        let atom = rng.gen();
        let i = rng.gen_range(0..nodes.len());
        let label = rng.gen_range(0..K * 2);
        ws.set_atom(&mut txn, atom, Some((nodes[i].0, label, vec![].into())));
        if label < K {
          nodes[i].1.push((atom, label));
        }
        atoms.push(atom);
      }

      // Generate edges between nodes.
      for _ in 0..1000 {
        let edge = rng.gen();
        let i = rng.gen_range(0..nodes.len());
        let j = rng.gen_range(0..nodes.len());
        let label = rng.gen_range(0..K * 2);
        ws.set_edge(&mut txn, edge, Some((nodes[i].0, label, nodes[j].0)));
        if label < K {
          nodes[i].2.push((edge, label));
        }
        edges.push(edge);
      }

      // Done.
      ws.barrier(&mut txn);

      // Generate operations.
      for _ in 0..round {
        match rng.gen_range(0..3) {
          0 => {
            // Randomly mutate node.
            let mut node = nodes.choose(&mut rng).unwrap().0;
            if rng.gen_ratio(1, 16) {
              node = rng.gen();
            }
            let mut value = ws.node(&mut txn, node);
            if rng.gen_ratio(1, 16) {
              value = None;
            }
            if let Some(inner) = &mut value {
              if rng.gen_ratio(1, 2) {
                *inner = rng.gen_range(0..K * 2);
              }
            }
            ws.set_node(&mut txn, node, value);
          }
          1 => {
            // Randomly mutate atom.
            let mut atom = *atoms.choose(&mut rng).unwrap();
            if rng.gen_ratio(1, 16) {
              atom = rng.gen();
            }
            let mut value = ws.atom(&mut txn, atom);
            if rng.gen_ratio(1, 16) {
              value = None;
            }
            if let Some(inner) = &mut value {
              if rng.gen_ratio(1, 4) {
                inner.0 = nodes.choose(&mut rng).unwrap().0;
              }
              if rng.gen_ratio(1, 16) {
                inner.0 = rng.gen();
              }
              if rng.gen_ratio(1, 4) {
                inner.1 = rng.gen_range(0..K * 2);
              }
              if rng.gen_ratio(1, 16) {
                inner.1 = rng.gen();
              }
            }
            ws.set_atom(&mut txn, atom, value);
          }
          2 => {
            // Randomly mutate edge.
            let mut edge = *edges.choose(&mut rng).unwrap();
            if rng.gen_ratio(1, 16) {
              edge = rng.gen();
            }
            let mut value = ws.edge(&mut txn, edge);
            if rng.gen_ratio(1, 16) {
              value = None;
            }
            if let Some(inner) = &mut value {
              if rng.gen_ratio(1, 4) {
                inner.0 = nodes.choose(&mut rng).unwrap().0;
              }
              if rng.gen_ratio(1, 16) {
                inner.0 = rng.gen();
              }
              if rng.gen_ratio(1, 4) {
                inner.1 = rng.gen_range(0..K * 2);
              }
              if rng.gen_ratio(1, 4) {
                inner.2 = nodes.choose(&mut rng).unwrap().0;
              }
              if rng.gen_ratio(1, 16) {
                inner.2 = rng.gen();
              }
            }
            ws.set_edge(&mut txn, edge, value);
          }
          _ => panic!(),
        }
      }

      // Done.
      ws.barrier(&mut txn);

      // Check invariants.
      // (1)
      for atom in atoms {
        if let Some((src, _, _)) = ws.atom(&mut txn, atom) {
          assert!(ws.node(&mut txn, src).is_some());
        }
      }
      // (2)
      for edge in edges {
        if let Some((src, _, dst)) = ws.edge(&mut txn, edge) {
          assert!(ws.node(&mut txn, src).is_some());
          assert!(ws.node(&mut txn, dst).is_some());
        }
      }
      // (3)
      let mut count = 0;
      for (node, ratoms, redges) in nodes {
        if ws.node(&mut txn, node).is_some() {
          for (ratom, label) in ratoms {
            assert_eq!(ws.atom(&mut txn, ratom).map(|(src, label, _)| (src, label)), Some((node, label)));
          }
          for (redge, label) in redges {
            assert_eq!(ws.edge(&mut txn, redge).map(|(src, label, _)| (src, label)), Some((node, label)));
          }
          count += 1;
        }
      }
      println!("{round} operations: {count} remaining");
    }
  }
}
