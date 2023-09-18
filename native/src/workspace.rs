#![allow(clippy::type_complexity)]

pub mod atom_set;
pub mod edge_set;
pub mod metadata;
pub mod node_set;

use rusqlite::{Connection, DropBehavior, Transaction, TransactionBehavior};
use std::{borrow::Borrow, collections::HashMap};

use self::{atom_set::AtomSet, edge_set::EdgeSet, metadata::WorkspaceMetadata};
use crate::{
  deserialize,
  ffi::structs::{CAtom, CEdge, CEventData},
  serialize,
};

const ATOMS_NAME: &str = "atoms";
const EDGES_NAME: &str = "edges";

pub struct Workspace {
  conn: Connection,
  metadata: WorkspaceMetadata,
  atoms: AtomSet,
  edges: EdgeSet,
  events: Vec<CEventData>,
}

/// Starts an *auto-commit* transaction.
fn txn(conn: &mut Connection) -> Transaction<'_> {
  let mut res = conn.transaction_with_behavior(TransactionBehavior::Immediate).unwrap();
  res.set_drop_behavior(DropBehavior::Commit);
  res
}

impl Workspace {
  pub fn new(prefix: &'static str, mut conn: Connection) -> Self {
    let mut txn = txn(&mut conn);
    let metadata = WorkspaceMetadata::new(prefix, &mut txn);
    let atoms = AtomSet::new(prefix, ATOMS_NAME, &mut txn);
    let edges = EdgeSet::new(prefix, EDGES_NAME, &mut txn);
    std::mem::drop(txn);
    Self { conn, metadata, atoms, edges, events: Vec::new() }
  }

  pub fn atom(&mut self, id: u128) -> Option<(u128, u64, Box<[u8]>)> {
    self.atoms.get(&mut txn(&mut self.conn), id).and_then(|(_, _, _, slv)| slv)
  }
  pub fn atom_label_value_by_src(&mut self, src: u128) -> Vec<(u128, (u64, Box<[u8]>))> {
    self.atoms.label_value_by_src(&mut txn(&mut self.conn), src)
  }
  pub fn atom_value_by_src_label(&mut self, src: u128, label: u64) -> Vec<(u128, Box<[u8]>)> {
    self.atoms.value_by_src_label(&mut txn(&mut self.conn), src, label)
  }
  pub fn atom_src_value_by_label(&mut self, label: u64) -> Vec<(u128, (u128, Box<[u8]>))> {
    self.atoms.src_value_by_label(&mut txn(&mut self.conn), label)
  }
  pub fn atom_src_by_label_value(&mut self, label: u64, value: &[u8]) -> Vec<(u128, u128)> {
    self.atoms.src_by_label_value(&mut txn(&mut self.conn), label, value)
  }
  pub fn edge(&mut self, id: u128) -> Option<(u128, u64, u128)> {
    self.edges.get(&mut txn(&mut self.conn), id).and_then(|(_, _, _, sld)| sld)
  }
  pub fn edge_label_dst_by_src(&mut self, src: u128) -> Vec<(u128, (u64, u128))> {
    self.edges.label_dst_by_src(&mut txn(&mut self.conn), src)
  }
  pub fn edge_dst_by_src_label(&mut self, src: u128, label: u64) -> Vec<(u128, u128)> {
    self.edges.dst_by_src_label(&mut txn(&mut self.conn), src, label)
  }
  pub fn edge_src_label_by_dst(&mut self, dst: u128) -> Vec<(u128, (u128, u64))> {
    self.edges.src_label_by_dst(&mut txn(&mut self.conn), dst)
  }
  pub fn edge_src_by_dst_label(&mut self, dst: u128, label: u64) -> Vec<(u128, u128)> {
    self.edges.src_by_dst_label(&mut txn(&mut self.conn), dst, label)
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

  pub fn set_atom_ref(&mut self, id: u128, slv: Option<(u128, u64, &[u8])>) -> bool {
    let mut txn = txn(&mut self.conn);
    let this = self.metadata.this();
    let next = self.atoms.next();
    Self::set_atom_raw(&mut txn, &mut self.atoms, &mut self.events, id, this, next, slv)
  }
  pub fn set_atom(&mut self, id: u128, slv: Option<(u128, u64, Box<[u8]>)>) -> bool {
    let mut txn = txn(&mut self.conn);
    let this = self.metadata.this();
    let next = self.atoms.next();
    let slv = slv.as_ref().map(|(src, label, value)| (*src, *label, value.borrow()));
    Self::set_atom_raw(&mut txn, &mut self.atoms, &mut self.events, id, this, next, slv)
  }
  pub fn set_edge(&mut self, id: u128, sld: Option<(u128, u64, u128)>) -> bool {
    let mut txn = txn(&mut self.conn);
    let this = self.metadata.this();
    let next = self.edges.next();
    Self::set_edge_raw(&mut txn, &mut self.edges, &mut self.events, id, this, next, sld)
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

  /// To keep backward compatibility, do not change existing strings and type annotations below.
  /// Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_version(&mut self) -> Box<[u8]> {
    let atoms_version: &HashMap<u64, u64> = self.atoms.buckets();
    let edges_version: &HashMap<u64, u64> = self.edges.buckets();
    let all: HashMap<&str, Vec<u8>> =
      HashMap::from([(ATOMS_NAME, serialize(atoms_version).unwrap()), (EDGES_NAME, serialize(edges_version).unwrap())]);
    serialize(&all).unwrap().into()
  }

  /// To keep backward compatibility, do not change existing strings and type annotations below.
  /// Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_actions(&mut self, version: &[u8]) -> Box<[u8]> {
    let all: HashMap<String, &[u8]> = deserialize(version).unwrap();
    let atoms_version: HashMap<u64, u64> = all.get(ATOMS_NAME).map_or(HashMap::new(), |m| deserialize(m).unwrap());
    let edges_version: HashMap<u64, u64> = all.get(EDGES_NAME).map_or(HashMap::new(), |m| deserialize(m).unwrap());

    let mut txn = txn(&mut self.conn);
    let atoms_actions: Vec<(u128, u64, u64, Option<(u128, u64, Box<[u8]>)>)> =
      self.atoms.actions(&mut txn, atoms_version);
    let edges_actions: Vec<(u128, u64, u64, Option<(u128, u64, u128)>)> = self.edges.actions(&mut txn, edges_version);

    let all: HashMap<&str, Vec<u8>> = HashMap::from([
      (ATOMS_NAME, serialize(&atoms_actions).unwrap()),
      (EDGES_NAME, serialize(&edges_actions).unwrap()),
    ]);
    serialize(&all).unwrap().into()
  }

  /// To keep backward compatibility, do not change existing strings and type annotations below.
  /// Additional entries may be added.
  #[allow(clippy::type_complexity)]
  pub fn sync_join(&mut self, actions: &[u8]) -> Option<Box<[u8]>> {
    let all: HashMap<String, &[u8]> = deserialize(actions).unwrap();
    let atoms_actions: Vec<(u128, u64, u64, Option<(u128, u64, Box<[u8]>)>)> =
      all.get(ATOMS_NAME).map_or(Vec::new(), |m| deserialize(m).unwrap());
    let edges_actions: Vec<(u128, u64, u64, Option<(u128, u64, u128)>)> =
      all.get(EDGES_NAME).map_or(Vec::new(), |m| deserialize(m).unwrap());

    let mut txn = txn(&mut self.conn);
    let atoms_actions: Vec<(u128, u64, u64, Option<(u128, u64, Box<[u8]>)>)> =
      Self::gamma_join_atoms_raw(&mut txn, &mut self.atoms, &mut self.events, atoms_actions);
    let edges_actions: Vec<(u128, u64, u64, Option<(u128, u64, u128)>)> =
      Self::gamma_join_edges_raw(&mut txn, &mut self.edges, &mut self.events, edges_actions);

    if atoms_actions.is_empty() && edges_actions.is_empty() {
      None
    } else {
      let all: HashMap<&str, Vec<u8>> = HashMap::from([
        (ATOMS_NAME, serialize(&atoms_actions).unwrap()),
        (EDGES_NAME, serialize(&edges_actions).unwrap()),
      ]);
      Some(serialize(&all).unwrap().into())
    }
  }

  pub fn poll_events(&mut self) -> Vec<CEventData> {
    std::mem::take(&mut self.events)
  }
}
