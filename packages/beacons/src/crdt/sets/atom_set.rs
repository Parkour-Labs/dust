//! A last-writer-win element set for storing atomic data.

use rusqlite::{OptionalExtension, Result, Row, Transaction};
use std::collections::HashMap;

use super::{Clock, Set, SetStore};
use crate::{insert, remove};

/// A last-writer-win element set for storing atomic data.
#[derive(Debug, Clone)]
pub struct AtomSet {
  inner: Set<Vec<u8>>,
  subscriptions: HashMap<u128, Vec<u64>>,
}

/// Database interface for [`AtomSet`].
pub trait AtomSetStore: SetStore<Vec<u8>> {}

/// Event bus interface for [`AtomSet`].
pub trait AtomSetEvents {
  fn push(&mut self, port: u64, value: Option<Vec<u8>>);
}

/// Type alias for action: `(id, clock, bucket, value)`.
type Action = (u128, Clock, u64, Option<Vec<u8>>);

impl AtomSet {
  /// Creates or loads data.
  pub fn new(name: &'static str, store: &mut impl AtomSetStore) -> Self {
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
  pub fn load(&mut self, store: &mut impl AtomSetStore, id: u128) {
    self.inner.load(store, id)
  }

  /// Unloads element.
  pub fn unload(&mut self, id: u128) {
    self.inner.unload(id)
  }

  /// Obtains reference to element.
  pub fn get(&mut self, store: &mut impl AtomSetStore, id: u128) -> &Option<(Clock, u64, Option<Vec<u8>>)> {
    self.inner.get(store, id)
  }

  /// Obtains reference to element value.
  pub fn value(&mut self, store: &mut impl AtomSetStore, id: u128) -> Option<&Vec<u8>> {
    self.inner.value(store, id)
  }

  /// Adds observer.
  pub fn subscribe(&mut self, store: &mut impl AtomSetStore, ctx: &mut impl AtomSetEvents, id: u128, port: u64) {
    insert(&mut self.subscriptions, id, port);
    ctx.push(port, self.inner.value(store, id).map(Vec::clone));
  }

  /// Removes observer.
  pub fn unsubscribe(&mut self, id: u128, port: u64) {
    remove(&mut self.subscriptions, id, &port);
  }

  fn notify(&mut self, store: &mut impl AtomSetStore, ctx: &mut impl AtomSetEvents, id: u128) {
    if let Some(ports) = self.subscriptions.get(&id) {
      for &port in ports {
        ctx.push(port, self.inner.value(store, id).map(Vec::clone));
      }
    }
  }

  /// Modifies element.
  pub fn set(&mut self, store: &mut impl AtomSetStore, ctx: &mut impl AtomSetEvents, action: Action) -> bool {
    let id = action.0;
    let res = self.inner.set(store, action);
    self.notify(store, ctx, id);
    res
  }

  /// Returns all actions strictly later than given clock values.
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl AtomSetStore, version: HashMap<u64, Clock>) -> Vec<Action> {
    self.inner.actions(store, version)
  }

  /// Applies a set of actions.
  pub fn gamma_join(
    &mut self,
    store: &mut impl AtomSetStore,
    ctx: &mut impl AtomSetEvents,
    mut actions: Vec<Action>,
  ) -> Vec<Action> {
    actions.retain(|action| self.set(store, ctx, action.clone()));
    actions
  }
}

/// A helper function.
fn read_row(row: &Row<'_>) -> Result<Action> {
  let id = row.get(0).unwrap();
  let clock = row.get(1).unwrap();
  let bucket = row.get(2).unwrap();
  let value = row.get(3).unwrap();
  Ok((u128::from_be_bytes(id), Clock::from_be_bytes(clock), u64::from_be_bytes(bucket), value))
}

/// A helper function.
#[allow(clippy::type_complexity)]
fn make_row(
  id: u128,
  clock: Clock,
  bucket: u64,
  value: &Option<Vec<u8>>,
) -> ([u8; 16], [u8; 16], [u8; 8], &Option<Vec<u8>>) {
  (id.to_be_bytes(), clock.to_be_bytes(), bucket.to_be_bytes(), value)
}

impl<'a> SetStore<Vec<u8>> for Transaction<'a> {
  fn init_data(&mut self, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{name}.data\" (
          id BLOB NOT NULL,
          clock BLOB NOT NULL,
          bucket BLOB NOT NULL,
          value BLOB,
          PRIMARY KEY (id)
        ) STRICT, WITHOUT ROWID;

        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_bucket_clock\" ON \"{name}.data\" (bucket, clock);
        "
      ))
      .unwrap();
  }

  fn get_data(&mut self, name: &str, id: u128) -> Option<Action> {
    self
      .prepare_cached(&format!("SELECT id, clock, bucket, value FROM \"{name}.data\" WHERE id = ?"))
      .unwrap()
      .query_row((id.to_be_bytes(),), read_row)
      .optional()
      .unwrap()
  }

  fn set_data(&mut self, name: &str, id: u128, clock: Clock, bucket: u64, value: &Option<Vec<u8>>) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.data\" VALUES (?, ?, ?, ?)"))
      .unwrap()
      .execute(make_row(id, clock, bucket, value))
      .unwrap();
  }

  fn query_data(&mut self, name: &str, lower: Option<Clock>, bucket: u64) -> Vec<Action> {
    self
      .prepare_cached(&format!(
        "SELECT id, clock, bucket, value FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_bucket_clock\"
        WHERE bucket = ? AND clock > ? ORDER BY clock ASC"
      ))
      .unwrap()
      .query_map((bucket.to_be_bytes(), lower.map(|lower| Clock::to_be_bytes(&lower))), read_row)
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}

impl<'a> AtomSetStore for Transaction<'a> {}
