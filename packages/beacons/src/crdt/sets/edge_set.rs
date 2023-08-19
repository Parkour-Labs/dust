//! A last-writer-win element set for storing edges.

use rusqlite::{OptionalExtension, Result, Row, Transaction};
use std::collections::HashMap;

use super::{Clock, Set, SetStore};
use crate::{insert, remove};

/// A last-writer-win element set for storing edges.
#[derive(Debug, Clone)]
pub struct EdgeSet {
  inner: Set<Edge>,
  subscriptions: HashMap<u128, Vec<u64>>,
  multiedge_subscriptions: HashMap<(u128, u64), Vec<u64>>,
  backedge_subscriptions: HashMap<(u128, u64), Vec<u64>>,
}

/// Database interface for [`EdgeSet`].
pub trait EdgeSetStore: SetStore<Edge> {
  fn query_id_value_by_label(&mut self, name: &str, label: u64) -> Vec<(u128, Edge)>;
  fn query_id_value_by_src(&mut self, name: &str, src: u128) -> Vec<(u128, Edge)>;
  fn query_id_dst_by_src_label(&mut self, name: &str, src: u128, label: u64) -> Vec<(u128, u128)>;
  fn query_id_src_by_dst_label(&mut self, name: &str, dst: u128, label: u64) -> Vec<(u128, u128)>;
}

/// Event bus interface for [`EdgeSet`].
pub trait EdgeSetEvents {
  fn push_edge(&mut self, port: u64, value: Option<Edge>);
  fn push_multiedge_insert(&mut self, port: u64, id: u128, dst: u128);
  fn push_multiedge_remove(&mut self, port: u64, id: u128, dst: u128);
  fn push_backedge_insert(&mut self, port: u64, id: u128, src: u128);
  fn push_backedge_remove(&mut self, port: u64, id: u128, src: u128);
}

/// Type alias for edges: `(src, label, dst)`.
type Edge = (u128, u64, u128);

/// Type alias for item: `(clock, bucket, value)`.
type Item = (Clock, u64, Option<Edge>);

impl EdgeSet {
  /// Creates or loads data.
  pub fn new(name: &'static str, store: &mut impl EdgeSetStore) -> Self {
    Self {
      inner: Set::new(name, store),
      subscriptions: HashMap::new(),
      multiedge_subscriptions: HashMap::new(),
      backedge_subscriptions: HashMap::new(),
    }
  }

  /// Returns the name of the structure.
  pub fn name(&self) -> &'static str {
    self.inner.name()
  }

  /// Returns this bucket ID.
  pub fn this(&self) -> u64 {
    self.inner.this()
  }

  /// Returns the current clock values values for each bucket.
  pub fn buckets(&self) -> &HashMap<u64, Clock> {
    self.inner.buckets()
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> Clock {
    self.inner.next()
  }

  /// Loads element.
  pub fn load(&mut self, store: &mut impl EdgeSetStore, id: u128) {
    self.inner.load(store, id)
  }

  /// Unloads element.
  pub fn unload(&mut self, id: u128) {
    self.inner.unload(id)
  }

  /// Obtains element value.
  pub fn value(&mut self, store: &mut impl EdgeSetStore, id: u128) -> Option<Edge> {
    self.inner.value(store, id).copied()
  }

  /// Adds observer.
  pub fn subscribe(&mut self, store: &mut impl EdgeSetStore, ctx: &mut impl EdgeSetEvents, id: u128, port: u64) {
    insert(&mut self.subscriptions, id, port);
    ctx.push_edge(port, self.inner.value(store, id).copied());
  }

  /// Adds observer.
  pub fn subscribe_multiedge(
    &mut self,
    store: &mut impl EdgeSetStore,
    ctx: &mut impl EdgeSetEvents,
    src: u128,
    label: u64,
    port: u64,
  ) {
    insert(&mut self.multiedge_subscriptions, (src, label), port);
    for (id, dst) in self.query_id_dst_by_src_label(store, src, label) {
      ctx.push_multiedge_insert(port, id, dst);
    }
  }

  /// Adds observer.
  pub fn subscribe_backedge(
    &mut self,
    store: &mut impl EdgeSetStore,
    ctx: &mut impl EdgeSetEvents,
    dst: u128,
    label: u64,
    port: u64,
  ) {
    insert(&mut self.backedge_subscriptions, (dst, label), port);
    for (id, src) in self.query_id_src_by_dst_label(store, dst, label) {
      ctx.push_backedge_insert(port, id, src);
    }
  }

  /// Removes observer.
  pub fn unsubscribe(&mut self, id: u128, port: u64) {
    remove(&mut self.subscriptions, id, &port);
  }

  /// Removes observer.
  pub fn unsubscribe_multiedge(&mut self, src: u128, label: u64, port: u64) {
    remove(&mut self.multiedge_subscriptions, (src, label), &port);
  }

  /// Removes observer.
  pub fn unsubscribe_backedge(&mut self, dst: u128, label: u64, port: u64) {
    remove(&mut self.backedge_subscriptions, (dst, label), &port);
  }

  fn notify_pre(&mut self, store: &mut impl EdgeSetStore, ctx: &mut impl EdgeSetEvents, id: u128) {
    if let Some((src, label, dst)) = self.inner.value(store, id).copied() {
      if let Some(ports) = self.multiedge_subscriptions.get(&(src, label)) {
        for &port in ports {
          ctx.push_multiedge_remove(port, id, dst);
        }
      }
      if let Some(ports) = self.backedge_subscriptions.get(&(dst, label)) {
        for &port in ports {
          ctx.push_backedge_remove(port, id, src);
        }
      }
    }
  }

  fn notify_post(&mut self, store: &mut impl EdgeSetStore, ctx: &mut impl EdgeSetEvents, id: u128) {
    if let Some(ports) = self.subscriptions.get(&id) {
      for &port in ports {
        ctx.push_edge(port, self.inner.value(store, id).copied());
      }
    }
    if let Some((src, label, dst)) = self.inner.value(store, id).copied() {
      if let Some(ports) = self.multiedge_subscriptions.get(&(src, label)) {
        for &port in ports {
          ctx.push_multiedge_insert(port, id, dst);
        }
      }
      if let Some(ports) = self.backedge_subscriptions.get(&(dst, label)) {
        for &port in ports {
          ctx.push_backedge_insert(port, id, src);
        }
      }
    }
  }

  /// Modifies element.
  pub fn set(&mut self, store: &mut impl EdgeSetStore, ctx: &mut impl EdgeSetEvents, id: u128, item: Item) -> bool {
    self.notify_pre(store, ctx, id);
    let res = self.inner.set(store, id, item);
    self.notify_post(store, ctx, id);
    res
  }

  /// Returns all actions strictly later than given clock values.
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl EdgeSetStore, version: HashMap<u64, Clock>) -> Vec<(u128, Item)> {
    self.inner.actions(store, version)
  }

  /// Applies a set of actions.
  pub fn gamma_join(
    &mut self,
    store: &mut impl EdgeSetStore,
    ctx: &mut impl EdgeSetEvents,
    mut actions: Vec<(u128, Item)>,
  ) -> Vec<(u128, Item)> {
    actions.retain(|(id, item)| self.set(store, ctx, *id, *item));
    actions
  }

  /// Queries all edges with given label.
  pub fn query_id_value_by_label(&mut self, store: &mut impl EdgeSetStore, label: u64) -> Vec<(u128, Edge)> {
    store.query_id_value_by_label(self.name(), label)
  }

  /// Queries all edges with given source.
  pub fn query_id_value_by_src(&mut self, store: &mut impl EdgeSetStore, src: u128) -> Vec<(u128, Edge)> {
    store.query_id_value_by_src(self.name(), src)
  }

  /// Queries all edges with given source and label.
  pub fn query_id_dst_by_src_label(
    &mut self,
    store: &mut impl EdgeSetStore,
    src: u128,
    label: u64,
  ) -> Vec<(u128, u128)> {
    store.query_id_dst_by_src_label(self.name(), src, label)
  }

  /// Queries all edges with given destination and label.
  pub fn query_id_src_by_dst_label(
    &mut self,
    store: &mut impl EdgeSetStore,
    dst: u128,
    label: u64,
  ) -> Vec<(u128, u128)> {
    store.query_id_src_by_dst_label(self.name(), dst, label)
  }
}

/// A helper function.
fn read_row(row: &Row<'_>) -> (u128, Item) {
  let id = row.get(0).unwrap();
  let clock = row.get(1).unwrap();
  let bucket = row.get(2).unwrap();
  let src: Option<_> = row.get(3).unwrap();
  let label: Option<_> = row.get(4).unwrap();
  let dst: Option<_> = row.get(5).unwrap();
  (
    u128::from_be_bytes(id),
    (
      Clock::from_be_bytes(clock),
      u64::from_be_bytes(bucket),
      label
        .map(|label| (u128::from_be_bytes(src.unwrap()), u64::from_be_bytes(label), u128::from_be_bytes(dst.unwrap()))),
    ),
  )
}

/// A helper function (non-nullable).
fn read_id_value_row(row: &Row<'_>) -> (u128, Edge) {
  let id = row.get(0).unwrap();
  let src = row.get(1).unwrap();
  let label = row.get(2).unwrap();
  let dst = row.get(3).unwrap();
  (u128::from_be_bytes(id), (u128::from_be_bytes(src), u64::from_be_bytes(label), u128::from_be_bytes(dst)))
}

/// A helper function (non-nullable).
fn read_id_dst_row(row: &Row<'_>) -> (u128, u128) {
  let id = row.get(0).unwrap();
  let dst = row.get(1).unwrap();
  (u128::from_be_bytes(id), u128::from_be_bytes(dst))
}

/// A helper function (non-nullable).
fn read_id_src_row(row: &Row<'_>) -> (u128, u128) {
  let id = row.get(0).unwrap();
  let src = row.get(1).unwrap();
  (u128::from_be_bytes(id), u128::from_be_bytes(src))
}

/// A helper function.
#[allow(clippy::type_complexity)]
fn make_row(
  id: u128,
  clock: Clock,
  bucket: u64,
  value: &Option<Edge>,
) -> ([u8; 16], [u8; 16], [u8; 8], Option<[u8; 16]>, Option<[u8; 8]>, Option<[u8; 16]>) {
  (
    id.to_be_bytes(),
    clock.to_be_bytes(),
    bucket.to_be_bytes(),
    value.map(|value| value.0.to_be_bytes()),
    value.map(|value| value.1.to_be_bytes()),
    value.map(|value| value.2.to_be_bytes()),
  )
}

impl<'a> SetStore<Edge> for Transaction<'a> {
  fn init_data(&mut self, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{name}.data\" (
          id BLOB NOT NULL,
          clock BLOB NOT NULL,
          bucket BLOB NOT NULL,
          src BLOB,
          label BLOB,
          dst BLOB,
          PRIMARY KEY (id)
        ) STRICT, WITHOUT ROWID;

        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_bucket_clock\" ON \"{name}.data\" (bucket, clock);
        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_src_label\" ON \"{name}.data\" (src, label);
        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_label_dst\" ON \"{name}.data\" (label, dst);
        "
      ))
      .unwrap();
  }

  fn get_data(&mut self, name: &str, id: u128) -> Option<Item> {
    self
      .prepare_cached(&format!("SELECT id, clock, bucket, src, label, dst FROM \"{name}.data\" WHERE id = ?"))
      .unwrap()
      .query_row((id.to_be_bytes(),), |row| Ok(read_row(row).1))
      .optional()
      .unwrap()
  }

  fn set_data(&mut self, name: &str, id: u128, bucket: u64, clock: Clock, value: &Option<Edge>) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.data\" VALUES (?, ?, ?, ?, ?, ?)"))
      .unwrap()
      .execute(make_row(id, clock, bucket, value))
      .unwrap();
  }

  fn query_data(&mut self, name: &str, bucket: u64, lower: Option<Clock>) -> Vec<(u128, Item)> {
    self
      .prepare_cached(&format!(
        "SELECT id, clock, bucket, src, label, dst FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_bucket_clock\"
        WHERE bucket = ? AND clock > ? ORDER BY clock ASC"
      ))
      .unwrap()
      .query_map((bucket.to_be_bytes(), lower.map(|lower| Clock::to_be_bytes(&lower))), |row| Ok(read_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}

impl<'a> EdgeSetStore for Transaction<'a> {
  fn query_id_value_by_label(&mut self, name: &str, label: u64) -> Vec<(u128, Edge)> {
    self
      .prepare_cached(&format!(
        "SELECT id, src, label, dst FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_label_dst\"
        WHERE label = ?"
      ))
      .unwrap()
      .query_map((label.to_be_bytes(),), |row| Ok(read_id_value_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn query_id_value_by_src(&mut self, name: &str, src: u128) -> Vec<(u128, Edge)> {
    self
      .prepare_cached(&format!(
        "SELECT id, src, label, dst FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_src_label\"
        WHERE src = ?"
      ))
      .unwrap()
      .query_map((src.to_be_bytes(),), |row| Ok(read_id_value_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn query_id_dst_by_src_label(&mut self, name: &str, src: u128, label: u64) -> Vec<(u128, u128)> {
    self
      .prepare_cached(&format!(
        "SELECT id, dst FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_src_label\"
        WHERE src = ? AND label = ?"
      ))
      .unwrap()
      .query_map((src.to_be_bytes(), label.to_be_bytes()), |row| Ok(read_id_dst_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn query_id_src_by_dst_label(&mut self, name: &str, dst: u128, label: u64) -> Vec<(u128, u128)> {
    self
      .prepare_cached(&format!(
        "SELECT id, src FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_label_dst\"
        WHERE label = ? AND dst = ?"
      ))
      .unwrap()
      .query_map((label.to_be_bytes(), dst.to_be_bytes()), |row| Ok(read_id_src_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}
