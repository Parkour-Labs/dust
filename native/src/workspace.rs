#![allow(clippy::type_complexity)]

pub mod atom_set;
pub mod edge_set;
pub mod metadata;
pub mod node_set;

use std::collections::{BTreeMap, BTreeSet};

use self::{atom_set::AtomSet, edge_set::EdgeSet, metadata::WorkspaceMetadata, node_set::NodeSet};
use crate::{deserialize, ffi::structs::CEventData, serialize, Transactor};

pub const NODES_NAME: &str = "nodes";
pub const ATOMS_NAME: &str = "atoms";
pub const EDGES_NAME: &str = "edges";

#[derive(Debug, Clone, Default)]
pub struct Constraints {
  sticky_nodes: BTreeSet<u64>,
  sticky_atoms: BTreeSet<u64>,
  sticky_edges: BTreeSet<u64>,
  acyclic_edges: BTreeSet<u64>,
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
  pub fn add_acyclic_edge(&mut self, label: u64) {
    self.acyclic_edges.insert(label);
  }
}

#[derive(Debug)]
pub struct Workspace {
  metadata: WorkspaceMetadata,
  constraints: Constraints,
  nodes: NodeSet,
  atoms: AtomSet,
  edges: EdgeSet,
}

impl Workspace {
  pub fn new(prefix: &'static str, constraints: Constraints, txr: &mut Transactor) -> Self {
    let metadata = WorkspaceMetadata::new(prefix, txr);
    let nodes = NodeSet::new(prefix, NODES_NAME, txr);
    let atoms = AtomSet::new(prefix, ATOMS_NAME, txr);
    let edges = EdgeSet::new(prefix, EDGES_NAME, txr);
    Self { metadata, constraints, nodes, atoms, edges }
  }

  pub fn node(&self, txr: &Transactor, id: u128) -> Option<u64> {
    self.nodes.get(txr, id).and_then(|(_, _, label)| label)
  }
  pub fn node_id_by_label(&self, txr: &Transactor, label: u64) -> BTreeMap<u128, ()> {
    self.nodes.id_by_label(txr, label)
  }
  pub fn atom(&self, txr: &Transactor, id: u128) -> Option<(u128, u64, Box<[u8]>)> {
    self.atoms.get(txr, id).and_then(|(_, _, slv)| slv)
  }
  pub fn atom_id_label_value_by_src(&self, txr: &Transactor, src: u128) -> BTreeMap<u128, (u64, Box<[u8]>)> {
    self.atoms.id_label_value_by_src(txr, src)
  }
  pub fn atom_id_value_by_src_label(&self, txr: &Transactor, src: u128, label: u64) -> BTreeMap<u128, Box<[u8]>> {
    self.atoms.id_value_by_src_label(txr, src, label)
  }
  pub fn atom_id_src_value_by_label(&self, txr: &Transactor, label: u64) -> BTreeMap<u128, (u128, Box<[u8]>)> {
    self.atoms.id_src_value_by_label(txr, label)
  }
  pub fn atom_id_src_by_label_value(&self, txr: &Transactor, label: u64, value: &[u8]) -> BTreeMap<u128, u128> {
    self.atoms.id_src_by_label_value(txr, label, value)
  }
  pub fn edge(&self, txr: &Transactor, id: u128) -> Option<(u128, u64, u128)> {
    self.edges.get(txr, id).and_then(|(_, _, sld)| sld)
  }
  pub fn edge_id_label_dst_by_src(&self, txr: &Transactor, src: u128) -> BTreeMap<u128, (u64, u128)> {
    self.edges.id_label_dst_by_src(txr, src)
  }
  pub fn edge_id_dst_by_src_label(&self, txr: &Transactor, src: u128, label: u64) -> BTreeMap<u128, u128> {
    self.edges.id_dst_by_src_label(txr, src, label)
  }
  pub fn edge_id_src_label_by_dst(&self, txr: &Transactor, dst: u128) -> BTreeMap<u128, (u128, u64)> {
    self.edges.id_src_label_by_dst(txr, dst)
  }
  pub fn edge_id_src_by_dst_label(&self, txr: &Transactor, dst: u128, label: u64) -> BTreeMap<u128, u128> {
    self.edges.id_src_by_dst_label(txr, dst, label)
  }

  pub fn set_node(&mut self, txr: &Transactor, id: u128, label: Option<u64>) {
    let this = self.metadata.this();
    let next = self.nodes.next();
    assert!(self.nodes.set(txr, id, this, next, label));
  }

  pub fn set_atom(&mut self, txr: &Transactor, id: u128, slv: Option<(u128, u64, Box<[u8]>)>) {
    let this = self.metadata.this();
    let next = self.atoms.next();
    assert!(self.atoms.set(txr, id, this, next, slv));
  }

  pub fn set_edge(&mut self, txr: &Transactor, id: u128, sld: Option<(u128, u64, u128)>) {
    let this = self.metadata.this();
    let next = self.edges.next();
    assert!(self.edges.set(txr, id, this, next, sld));
  }

  /// Issues write-read barrier: goes through all recent modifications,
  /// performing any additional action required to maintain invariants:
  ///
  /// 1. `atom_implies_node`: all atoms must start from a node.
  /// 2. `edge_implies_node`: all edges must start from and ends at nodes.
  /// 3. `sticky_or_none`: for each node, if it has "sticky" atoms or edges
  ///     attached to it at the previous barrier, those must be preserved,
  ///     otherwise the node must be removed.
  /// 4. `acyclic_or_none`: edges marked as "acyclic" cannot form cycles,
  ///     otherwise some edges must be removed to break the cycle.
  pub fn barrier(&mut self, txr: &mut Transactor) -> Vec<CEventData> {
    // Assuming all conditions were true before any of the modifications,
    // we only need to focus on changes which cause violations.

    // The set of nodes which definitely violate (3), or possibly are endpoints of atoms/edges violating (1) (2).
    let mut nodes = BTreeSet::<u128>::new();
    // The set of atoms which definitely violate (1).
    let mut atoms = BTreeSet::<u128>::new();
    // The set of edges which definitely violate (2) or (4).
    let mut edges = BTreeSet::<u128>::new();

    for (id, prev, curr) in self.nodes.mods() {
      if let Some(label) = prev {
        if self.constraints.sticky_nodes.contains(&label) && !matches!(curr, Some(label_) if label_ == label) {
          nodes.insert(id); // `prev` is sticky, `curr` does not exist or have `label` changed (3)
        }
      }
      if prev.is_some() && curr.is_none() {
        nodes.insert(id); // `curr` node does not exist (1) (2)
      }
    }

    for (id, prev, curr) in self.atoms.mods() {
      if let Some((src, label, _)) = prev {
        if self.constraints.sticky_atoms.contains(&label)
          && !matches!(curr, Some((src_, label_, _)) if src_ == src && label_ == label)
        {
          nodes.insert(src); // `prev` is sticky, `curr` does not exist or have `src` or `label` changed (3)
        }
      }
      if let Some((src, _, _)) = curr {
        if !self.nodes.exists(txr, src) {
          atoms.insert(id); // `curr` exists, `src` node does not exist (1)
        }
      }
    }

    for (id, prev, curr) in self.edges.mods() {
      if let Some((src, label, _)) = prev {
        if self.constraints.sticky_atoms.contains(&label)
          && !matches!(curr, Some((src_, label_, _)) if src_ == src && label_ == label)
        {
          nodes.insert(src); // `prev` is sticky, `curr` does not exist or have `src` or `label` changed (3)
        }
      }
      if let Some((src, label, dst)) = curr {
        if !(self.nodes.exists(txr, src) && self.nodes.exists(txr, dst))
          || (self.constraints.acyclic_edges.contains(&label)
            && self.reachable(txr, label, dst, src, &mut BTreeSet::new()))
        {
          edges.insert(id); // `curr` exists, `src` or `dst` node does not exist (2) or cyclic (4)
          if self.constraints.sticky_edges.contains(&label) {
            nodes.insert(src); // `curr` is sticky, `curr` is removed
          }
        }
      }
    }

    while let Some(id) = atoms.pop_first() {
      self.set_atom(txr, id, None);
    }
    while let Some(id) = edges.pop_first() {
      self.set_edge(txr, id, None);
    }
    while let Some(id) = nodes.pop_first() {
      if self.nodes.exists(txr, id) {
        self.set_node(txr, id, None);
      }
      for (atom, _) in self.atom_id_label_value_by_src(txr, id) {
        self.set_atom(txr, atom, None);
      }
      for (edge, _) in self.edge_id_label_dst_by_src(txr, id) {
        self.set_edge(txr, edge, None);
      }
      for (edge, (src, label)) in self.edge_id_src_label_by_dst(txr, id) {
        self.set_edge(txr, edge, None);
        if self.constraints.sticky_edges.contains(&label) {
          nodes.insert(src); // `curr` is sticky, `curr` is removed
        }
      }
    }

    // Collect all modifications.
    let mut res = Vec::new();
    for (id, prev, curr) in self.nodes.mods() {
      res.push(CEventData::Node { id: id.into(), prev: prev.map(Into::into).into(), curr: curr.map(Into::into).into() })
    }
    for (id, prev, curr) in self.atoms.mods() {
      res.push(CEventData::Atom { id: id.into(), prev: prev.map(Into::into).into(), curr: curr.map(Into::into).into() })
    }
    for (id, prev, curr) in self.edges.mods() {
      res.push(CEventData::Edge { id: id.into(), prev: prev.map(Into::into).into(), curr: curr.map(Into::into).into() })
    }

    // Apply and save all modifications.
    self.nodes.save(txr);
    self.atoms.save(txr);
    self.edges.save(txr);

    res
  }

  /// Used in checking acyclicity constraints.
  fn reachable(&self, txr: &Transactor, label: u64, src: u128, dst: u128, v: &mut BTreeSet<u128>) -> bool {
    if src == dst {
      return true;
    }
    v.insert(src);
    for (_, next) in self.edge_id_dst_by_src_label(txr, src, label) {
      if !v.contains(&next) && self.reachable(txr, label, next, dst, v) {
        return true;
      }
    }
    false
  }

  /// To keep backward compatibility, do not change existing strings and type
  /// annotations below. Additional entries may be added.
  pub fn sync_version(&self, _: &Transactor) -> Box<[u8]> {
    let nodes_version: BTreeMap<u64, u64> = self.nodes.buckets();
    let atoms_version: BTreeMap<u64, u64> = self.atoms.buckets();
    let edges_version: BTreeMap<u64, u64> = self.edges.buckets();

    let all: BTreeMap<&str, Vec<u8>> = BTreeMap::from([
      (NODES_NAME, serialize(&nodes_version).unwrap()),
      (ATOMS_NAME, serialize(&atoms_version).unwrap()),
      (EDGES_NAME, serialize(&edges_version).unwrap()),
    ]);

    serialize(&all).unwrap().into()
  }

  /// To keep backward compatibility, do not change existing strings and type
  /// annotations below. Additional entries may be added.
  pub fn sync_actions(&self, txr: &Transactor, version: &[u8]) -> Box<[u8]> {
    let all: BTreeMap<String, &[u8]> = deserialize(version).unwrap();

    let nodes_version: BTreeMap<u64, u64> = all.get(NODES_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());
    let atoms_version: BTreeMap<u64, u64> = all.get(ATOMS_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());
    let edges_version: BTreeMap<u64, u64> = all.get(EDGES_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());

    let nodes_actions: BTreeMap<u128, (u64, u64, Option<u64>)> = self.nodes.actions(txr, nodes_version);
    let atoms_actions: BTreeMap<u128, (u64, u64, Option<(u128, u64, Box<[u8]>)>)> =
      self.atoms.actions(txr, atoms_version);
    let edges_actions: BTreeMap<u128, (u64, u64, Option<(u128, u64, u128)>)> = self.edges.actions(txr, edges_version);

    let all: BTreeMap<&str, Vec<u8>> = BTreeMap::from([
      (NODES_NAME, serialize(&nodes_actions).unwrap()),
      (ATOMS_NAME, serialize(&atoms_actions).unwrap()),
      (EDGES_NAME, serialize(&edges_actions).unwrap()),
    ]);

    serialize(&all).unwrap().into()
  }

  /// To keep backward compatibility, do not change existing strings and type
  /// annotations below. Additional entries may be added.
  pub fn sync_join(&mut self, txr: &Transactor, actions: &[u8]) {
    let all: BTreeMap<String, &[u8]> = deserialize(actions).unwrap();

    let nodes_actions: BTreeMap<u128, (u64, u64, Option<u64>)> =
      all.get(NODES_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());
    let atoms_actions: BTreeMap<u128, (u64, u64, Option<(u128, u64, Box<[u8]>)>)> =
      all.get(ATOMS_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());
    let edges_actions: BTreeMap<u128, (u64, u64, Option<(u128, u64, u128)>)> =
      all.get(EDGES_NAME).map_or_else(BTreeMap::new, |m| deserialize(m).unwrap());

    let mut nodes_actions = nodes_actions.into_iter().collect::<Vec<_>>();
    nodes_actions.sort_by_key(|(_, (bucket, clock, _))| (*bucket, *clock));
    let mut atoms_actions = atoms_actions.into_iter().collect::<Vec<_>>();
    atoms_actions.sort_by_key(|(_, (bucket, clock, _))| (*bucket, *clock));
    let mut edges_actions = edges_actions.into_iter().collect::<Vec<_>>();
    edges_actions.sort_by_key(|(_, (bucket, clock, _))| (*bucket, *clock));

    for (id, (bucket, clock, l)) in nodes_actions {
      self.nodes.set(txr, id, bucket, clock, l);
    }
    for (id, (bucket, clock, slv)) in atoms_actions {
      self.atoms.set(txr, id, bucket, clock, slv);
    }
    for (id, (bucket, clock, sld)) in edges_actions {
      self.edges.set(txr, id, bucket, clock, sld);
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
  fn sticky_simple() {
    let mut txr: Transactor = Connection::open_in_memory().unwrap().try_into().unwrap();
    let mut rng = rand::thread_rng();
    let mut constraints = Constraints::new();
    constraints.add_sticky_node(100);
    constraints.add_sticky_atom(200);
    constraints.add_sticky_edge(300);
    let mut ws = Workspace::new("", constraints, &mut txr);

    let node0 = rng.gen();
    let node1 = rng.gen();
    let node2 = rng.gen();
    let node3 = rng.gen();
    ws.set_node(&txr, node0, Some(0));
    ws.set_node(&txr, node1, Some(100));
    ws.set_node(&txr, node2, Some(0));
    ws.set_node(&txr, node3, Some(100));
    ws.set_edge(&txr, rng.gen(), Some((node0, 2, node0)));
    ws.set_edge(&txr, rng.gen(), Some((node0, 3, node1)));
    ws.set_edge(&txr, rng.gen(), Some((node1, 2, node1)));
    ws.set_edge(&txr, rng.gen(), Some((node1, 3, node0)));
    ws.set_edge(&txr, rng.gen(), Some((node1, 2, 2333))); // Invalid
    ws.set_edge(&txr, rng.gen(), Some((2333, 2, node1))); // Invalid
    ws.barrier(&mut txr);
    assert_eq!(ws.node(&txr, node0), Some(0));
    assert_eq!(ws.node(&txr, node1), Some(100));
    assert_eq!(ws.edge_id_label_dst_by_src(&txr, node0).len(), 2);
    assert_eq!(ws.edge_id_src_label_by_dst(&txr, node0).len(), 2);
    assert_eq!(ws.edge_id_label_dst_by_src(&txr, node1).len(), 2);
    assert_eq!(ws.edge_id_src_label_by_dst(&txr, node1).len(), 2);

    ws.set_node(&txr, node0, Some(2333));
    ws.set_node(&txr, node1, Some(2333)); // Invalid
    ws.set_edge(&txr, rng.gen(), Some((node0, 3, node1))); // Invalid
    ws.set_edge(&txr, rng.gen(), Some((node1, 3, node0))); // Invalid
    ws.barrier(&mut txr);
    assert_eq!(ws.node(&txr, node0), Some(2333));
    assert_eq!(ws.node(&txr, node1), None);
    assert_eq!(ws.edge_id_label_dst_by_src(&txr, node0).len(), 1);
    assert_eq!(ws.edge_id_src_label_by_dst(&txr, node0).len(), 1);
    assert_eq!(ws.edge_id_label_dst_by_src(&txr, node1).len(), 0);
    assert_eq!(ws.edge_id_src_label_by_dst(&txr, node1).len(), 0);

    let atom0 = rng.gen();
    let atom1 = rng.gen();
    let atom2 = rng.gen();
    ws.set_atom(&txr, atom0, Some((node0, 1, vec![1, 2, 3, 4].into())));
    ws.set_atom(&txr, atom1, Some((node0, 200, vec![].into()))); // Overwritten
    ws.set_atom(&txr, atom1, Some((node0, 0, vec![].into()))); // Overwritten
    ws.set_atom(&txr, atom1, Some((node0, 200, vec![5, 6, 7].into())));
    ws.set_atom(&txr, atom2, Some((node2, 2, vec![].into())));
    ws.barrier(&mut txr);
    assert!(ws.atom(&txr, atom0).is_some());
    assert!(ws.atom(&txr, atom1).is_some());
    assert!(ws.atom(&txr, atom2).is_some());

    ws.set_atom(&txr, atom0, Some((node2, 1, vec![].into())));
    ws.set_atom(&txr, atom1, Some((node2, 200, vec![].into()))); // Invalid, delete `node0`
    ws.set_atom(&txr, atom2, Some((node0, 2, vec![].into()))); // Invalid, `node0` deleted
    ws.barrier(&mut txr);
    assert!(ws.node(&txr, node0).is_none());
    assert!(ws.atom(&txr, atom0).is_some());
    assert!(ws.atom(&txr, atom1).is_some());
    assert!(ws.atom(&txr, atom2).is_none());

    let edge0 = rng.gen();
    let edge1 = rng.gen();
    let edge2 = rng.gen();
    let edge3 = rng.gen();
    ws.set_edge(&txr, edge0, Some((node3, 1, node0))); // Invalid
    ws.set_edge(&txr, edge1, Some((node3, 2, node1))); // Invalid
    ws.set_edge(&txr, edge2, Some((node3, 300, node2)));
    ws.set_edge(&txr, edge3, Some((node3, 300, node3)));
    ws.barrier(&mut txr);
    assert!(ws.node(&txr, node2).is_some());
    assert!(ws.node(&txr, node3).is_some());
    assert!(ws.edge(&txr, edge0).is_none());
    assert!(ws.edge(&txr, edge1).is_none());
    assert!(ws.edge(&txr, edge2).is_some());
    assert!(ws.edge(&txr, edge3).is_some());

    ws.set_edge(&txr, rng.gen(), Some((node2, 300, node0))); // Invalid, delete `node2` (?) and `node3`
    ws.barrier(&mut txr);
    assert!(ws.node(&txr, node2).is_none());
    assert!(ws.node(&txr, node3).is_none());

    const N: usize = 2333;
    let nodes: Vec<u128> = (0..N + 1).map(|_| rng.gen()).collect();
    let edges: Vec<u128> = (0..N).map(|_| rng.gen()).collect();
    let atom = rng.gen();
    for i in 0..N {
      ws.set_node(&txr, nodes[i], Some(0));
      ws.set_edge(&txr, edges[i], Some((nodes[i], 300, nodes[i + rng.gen_range(1..=(N - i))])));
    }
    ws.set_node(&txr, nodes[N], Some(0));
    ws.set_atom(&txr, atom, Some((nodes[N], 200, vec![].into())));
    ws.barrier(&mut txr);
    for i in 0..N {
      assert!(ws.node(&txr, nodes[i]).is_some());
      assert!(ws.edge(&txr, edges[i]).is_some());
    }
    ws.set_atom(&txr, atom, Some((nodes[N], 2333, vec![].into()))); // Invalid, delete `nodes` and `edges`
    ws.barrier(&mut txr);
    for i in 0..N {
      assert!(ws.node(&txr, nodes[i]).is_none());
      assert!(ws.edge(&txr, edges[i]).is_none());
    }
  }

  #[test]
  fn sticky_random() {
    const K: u64 = 20;
    let mut constraints = Constraints::new();
    for i in 0..K {
      constraints.add_sticky_node(i);
      constraints.add_sticky_atom(i);
      constraints.add_sticky_edge(i);
    }

    for round in 50..100 {
      let mut txr: Transactor = Connection::open_in_memory().unwrap().try_into().unwrap();
      let mut rng = rand::thread_rng();
      let mut ws = Workspace::new("", constraints.clone(), &mut txr);

      let mut nodes = vec![];
      let mut atoms = vec![];
      let mut edges = vec![];

      // Generate nodes.
      for _ in 0..300 {
        let node = rng.gen();
        let label = rng.gen_range(0..K * 2);
        ws.set_node(&txr, node, Some(label));
        nodes.push((node, vec![], vec![]));
      }

      // Generate atoms from nodes.
      for _ in 0..1000 {
        let atom = rng.gen();
        let i = rng.gen_range(0..nodes.len());
        let label = rng.gen_range(0..K * 2);
        ws.set_atom(&txr, atom, Some((nodes[i].0, label, vec![].into())));
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
        ws.set_edge(&txr, edge, Some((nodes[i].0, label, nodes[j].0)));
        if label < K {
          nodes[i].2.push((edge, label));
        }
        edges.push(edge);
      }

      // Done.
      ws.barrier(&mut txr);

      // Generate operations.
      for _ in 0..round {
        match rng.gen_range(0..3) {
          0 => {
            // Randomly mutate node.
            let mut node = nodes.choose(&mut rng).unwrap().0;
            if rng.gen_ratio(1, 16) {
              node = rng.gen();
            }
            let mut value = ws.node(&txr, node);
            if rng.gen_ratio(1, 16) {
              value = None;
            }
            if let Some(inner) = &mut value {
              if rng.gen_ratio(1, 2) {
                *inner = rng.gen_range(0..K * 2);
              }
            }
            ws.set_node(&txr, node, value);
          }
          1 => {
            // Randomly mutate atom.
            let mut atom = *atoms.choose(&mut rng).unwrap();
            if rng.gen_ratio(1, 16) {
              atom = rng.gen();
            }
            let mut value = ws.atom(&txr, atom);
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
            ws.set_atom(&txr, atom, value);
          }
          2 => {
            // Randomly mutate edge.
            let mut edge = *edges.choose(&mut rng).unwrap();
            if rng.gen_ratio(1, 16) {
              edge = rng.gen();
            }
            let mut value = ws.edge(&txr, edge);
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
            ws.set_edge(&txr, edge, value);
          }
          _ => panic!(),
        }
      }

      // Done.
      ws.barrier(&mut txr);

      // Check invariants.
      // (1)
      for atom in atoms {
        if let Some((src, _, _)) = ws.atom(&txr, atom) {
          assert!(ws.node(&txr, src).is_some());
        }
      }
      // (2)
      for edge in edges {
        if let Some((src, _, dst)) = ws.edge(&txr, edge) {
          assert!(ws.node(&txr, src).is_some());
          assert!(ws.node(&txr, dst).is_some());
        }
      }
      // (3)
      let mut count = 0;
      for (node, ratoms, redges) in nodes {
        if ws.node(&txr, node).is_some() {
          for (ratom, label) in ratoms {
            assert_eq!(ws.atom(&txr, ratom).map(|(src, label, _)| (src, label)), Some((node, label)));
          }
          for (redge, label) in redges {
            assert_eq!(ws.edge(&txr, redge).map(|(src, label, _)| (src, label)), Some((node, label)));
          }
          count += 1;
        }
      }
      println!("{round} operations: {count} remaining");
    }
  }

  #[test]
  fn acyclic_simple() {
    let mut txr: Transactor = Connection::open_in_memory().unwrap().try_into().unwrap();
    let mut rng = rand::thread_rng();
    let mut constraints = Constraints::new();
    constraints.add_sticky_edge(0);
    constraints.add_acyclic_edge(0);
    let mut ws = Workspace::new("", constraints, &mut txr);

    let node0 = rng.gen();
    let node1 = rng.gen();
    let node2 = rng.gen();
    let node3 = rng.gen();
    ws.set_node(&txr, node0, Some(0));
    ws.set_node(&txr, node1, Some(0));
    ws.set_node(&txr, node2, Some(0));
    ws.set_node(&txr, node3, Some(0));
    let edge0 = rng.gen();
    let edge1 = rng.gen();
    let edge2 = rng.gen();
    let edge3 = rng.gen();
    ws.set_edge(&txr, edge0, Some((node0, 0, node1)));
    ws.set_edge(&txr, edge1, Some((node1, 0, node2)));
    ws.set_edge(&txr, edge2, Some((node2, 0, node3)));
    ws.barrier(&mut txr);
    assert!(ws.node(&txr, node0).is_some());
    assert!(ws.node(&txr, node1).is_some());
    assert!(ws.node(&txr, node2).is_some());
    assert!(ws.node(&txr, node3).is_some());
    assert!(ws.edge(&txr, edge0).is_some());
    assert!(ws.edge(&txr, edge1).is_some());
    assert!(ws.edge(&txr, edge2).is_some());

    ws.set_edge(&txr, edge3, Some((node2, 0, node0)));
    ws.barrier(&mut txr);
    assert!(ws.node(&txr, node0).is_none());
    assert!(ws.node(&txr, node1).is_none());
    assert!(ws.node(&txr, node2).is_none());
    assert!(ws.node(&txr, node3).is_some());
    assert!(ws.edge(&txr, edge0).is_none());
    assert!(ws.edge(&txr, edge1).is_none());
    assert!(ws.edge(&txr, edge2).is_none());
  }
}
