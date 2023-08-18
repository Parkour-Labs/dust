//! A last-writer-win element set for storing nodes.

use rusqlite::{OptionalExtension, Result, Row, Transaction};
use std::collections::HashMap;

use super::{Clock, Set, SetStore};
use crate::{insert, remove};

/// A last-writer-win element set for storing nodes.
#[derive(Debug, Clone)]
pub struct NodeSet {
  inner: Set<u64>,
  subscriptions: HashMap<u128, Vec<u64>>,
}

/// Database interface for [`NodeSet`].
pub trait NodeSetStore: SetStore<u64> {
  fn query_id_by_label(&mut self, name: &str, label: u64) -> Vec<u128>;
}

/// Event bus interface for [`NodeSet`].
pub trait NodeSetEvents {
  fn push(&mut self, port: u64, value: Option<u64>);
}

/// Type alias for item: `(clock, bucket, value)`.
type Item = (Clock, u64, Option<u64>);

impl NodeSet {
  /// Creates or loads data.
  pub fn new(name: &'static str, store: &mut impl NodeSetStore) -> Self {
    Self { inner: Set::new(name, store), subscriptions: HashMap::new() }
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
  pub fn load(&mut self, store: &mut impl NodeSetStore, id: u128) {
    self.inner.load(store, id)
  }

  /// Unloads element.
  pub fn unload(&mut self, id: u128) {
    self.inner.unload(id)
  }

  /// Obtains reference to element.
  pub fn get(&mut self, store: &mut impl NodeSetStore, id: u128) -> &Option<(Clock, u64, Option<u64>)> {
    self.inner.get(store, id)
  }

  /// Obtains reference to element value.
  pub fn value(&mut self, store: &mut impl NodeSetStore, id: u128) -> Option<&u64> {
    self.inner.value(store, id)
  }

  /// Adds observer.
  pub fn subscribe(&mut self, store: &mut impl NodeSetStore, ctx: &mut impl NodeSetEvents, id: u128, port: u64) {
    insert(&mut self.subscriptions, id, port);
    ctx.push(port, self.inner.value(store, id).copied());
  }

  /// Removes observer.
  pub fn unsubscribe(&mut self, id: u128, port: u64) {
    remove(&mut self.subscriptions, id, &port);
  }

  fn notify(&mut self, store: &mut impl NodeSetStore, ctx: &mut impl NodeSetEvents, id: u128) {
    if let Some(ports) = self.subscriptions.get(&id) {
      for &port in ports {
        ctx.push(port, self.inner.value(store, id).copied());
      }
    }
  }

  /// Modifies element.
  pub fn set(&mut self, store: &mut impl NodeSetStore, ctx: &mut impl NodeSetEvents, id: u128, item: Item) -> bool {
    let res = self.inner.set(store, id, item);
    self.notify(store, ctx, id);
    res
  }

  /// Returns all actions strictly later than given clock values.
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl NodeSetStore, version: HashMap<u64, Clock>) -> Vec<(u128, Item)> {
    self.inner.actions(store, version)
  }

  /// Applies a set of actions.
  pub fn gamma_join(
    &mut self,
    store: &mut impl NodeSetStore,
    ctx: &mut impl NodeSetEvents,
    mut actions: Vec<(u128, Item)>,
  ) -> Vec<(u128, Item)> {
    actions.retain(|(id, item)| self.set(store, ctx, *id, *item));
    actions
  }

  /// Queries all nodes with given label.
  pub fn query_id_by_label(&mut self, store: &mut impl NodeSetStore, label: u64) -> Vec<u128> {
    store.query_id_by_label(self.name(), label)
  }
}

/// A helper function.
fn read_row(row: &Row<'_>) -> (u128, Item) {
  let id = row.get(0).unwrap();
  let clock = row.get(1).unwrap();
  let bucket = row.get(2).unwrap();
  let value: Option<_> = row.get(3).unwrap();
  (u128::from_be_bytes(id), (Clock::from_be_bytes(clock), u64::from_be_bytes(bucket), value.map(u64::from_be_bytes)))
}

/// A helper function.
fn read_id_row(row: &Row<'_>) -> u128 {
  u128::from_be_bytes(row.get(0).unwrap())
}

/// A helper function.
#[allow(clippy::type_complexity)]
fn make_row(
  id: u128,
  clock: Clock,
  bucket: u64,
  value: &Option<u64>,
) -> ([u8; 16], [u8; 16], [u8; 8], Option<[u8; 8]>) {
  (id.to_be_bytes(), clock.to_be_bytes(), bucket.to_be_bytes(), value.map(u64::to_be_bytes))
}

impl<'a> SetStore<u64> for Transaction<'a> {
  fn init_data(&mut self, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{name}.data\" (
          id BLOB NOT NULL,
          clock BLOB NOT NULL,
          bucket BLOB NOT NULL,
          label BLOB,
          PRIMARY KEY (id)
        ) STRICT, WITHOUT ROWID;

        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_bucket_clock\" ON \"{name}.data\" (bucket, clock);
        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_label\" ON \"{name}.data\" (label);
        "
      ))
      .unwrap();
  }

  fn get_data(&mut self, name: &str, id: u128) -> Option<Item> {
    self
      .prepare_cached(&format!("SELECT id, clock, bucket, label FROM \"{name}.data\" WHERE id = ?"))
      .unwrap()
      .query_row((id.to_be_bytes(),), |row| Ok(read_row(row).1))
      .optional()
      .unwrap()
  }

  fn set_data(&mut self, name: &str, id: u128, bucket: u64, clock: Clock, value: &Option<u64>) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.data\" VALUES (?, ?, ?, ?)"))
      .unwrap()
      .execute(make_row(id, clock, bucket, value))
      .unwrap();
  }

  fn query_data(&mut self, name: &str, bucket: u64, lower: Option<Clock>) -> Vec<(u128, Item)> {
    self
      .prepare_cached(&format!(
        "SELECT id, clock, bucket, label FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_bucket_clock\"
        WHERE bucket = ? AND clock > ? ORDER BY clock ASC"
      ))
      .unwrap()
      .query_map((bucket.to_be_bytes(), lower.map(|lower| Clock::to_be_bytes(&lower))), |row| Ok(read_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}

impl<'a> NodeSetStore for Transaction<'a> {
  fn query_id_by_label(&mut self, name: &str, label: u64) -> Vec<u128> {
    self
      .prepare_cached(&format!(
        "SELECT id FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_label\"
        WHERE label = ?"
      ))
      .unwrap()
      .query_map((label.to_be_bytes(),), |row| Ok(read_id_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}
