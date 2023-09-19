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

pub struct Constraints {
  sticky_nodes: BTreeSet<u64>,
  sticky_atoms: BTreeSet<u64>,
  sticky_edges: BTreeSet<u64>,
}

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
            nodes.insert(src); // `prev` is sticky, `curr` is removed (3)
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
          nodes.insert(src); // `prev` is sticky, `curr` is removed (3)
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
