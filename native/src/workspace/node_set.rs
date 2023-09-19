//! A last-writer-wins element set for storing nodes.

use rusqlite::{OptionalExtension, Result, Row, Transaction};
use std::{
  collections::BTreeMap,
  time::{SystemTime, UNIX_EPOCH},
};

use super::metadata::{StructureMetadata, StructureMetadataStore};

/// A last-writer-wins element set for storing nodes.
#[derive(Debug)]
pub struct NodeSet {
  version: StructureMetadata,
}

/// Type alias for item: `(id, bucket, (clock, label))`.
type Item = (u128, u64, u64, Option<u64>);

/// Database interface for [`NodeSet`].
pub trait NodeSetStore: StructureMetadataStore {
  fn init(&mut self, prefix: &str, name: &str);
  fn get(&mut self, prefix: &str, name: &str, id: u128) -> Option<Item>;
  fn set(&mut self, prefix: &str, name: &str, id: u128, bucket: u64, clock: u64, label: Option<u64>);
  fn by_label(&mut self, prefix: &str, name: &str, label: u64) -> Vec<u128>;
  fn item_by_bucket_clock_range(&mut self, prefix: &str, name: &str, bucket: u64, lower: Option<u64>) -> Vec<Item>;
}

impl NodeSet {
  /// Creates or loads data.
  pub fn new(prefix: &'static str, name: &'static str, store: &mut impl NodeSetStore) -> Self {
    let version = StructureMetadata::new(prefix, name, store);
    store.init(prefix, name);
    Self { version }
  }

  /// Returns the name of the workspace.
  pub fn prefix(&self) -> &'static str {
    self.version.prefix()
  }

  /// Returns the name of the structure.
  pub fn name(&self) -> &'static str {
    self.version.name()
  }

  /// Returns the current clock values for each bucket.
  pub fn buckets(&self) -> &BTreeMap<u64, u64> {
    self.version.buckets()
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> u64 {
    let measured = SystemTime::now().duration_since(UNIX_EPOCH).ok().and_then(|d| u64::try_from(d.as_nanos()).ok());
    self.version.next().max(measured.unwrap_or(0))
  }

  pub fn exists(&mut self, store: &mut impl NodeSetStore, id: u128) -> bool {
    store.get(self.prefix(), self.name(), id).and_then(|(_, _, _, label)| label).is_some()
  }

  pub fn get(&mut self, store: &mut impl NodeSetStore, id: u128) -> Option<Item> {
    store.get(self.prefix(), self.name(), id)
  }

  pub fn by_label(&mut self, store: &mut impl NodeSetStore, label: u64) -> Vec<u128> {
    store.by_label(self.prefix(), self.name(), label)
  }

  /// Returns all actions strictly later than given clock values (sorted by clock value).
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl NodeSetStore, version: BTreeMap<u64, u64>) -> Vec<Item> {
    let mut res = Vec::new();
    for &bucket in self.buckets().keys() {
      let lower = version.get(&bucket).copied();
      for elem in store.item_by_bucket_clock_range(self.prefix(), self.name(), bucket, lower) {
        res.push(elem);
      }
    }
    res
  }

  /// Modifies item. Returns previous value if updated.
  pub fn set(
    &mut self,
    store: &mut impl NodeSetStore,
    id: u128,
    bucket: u64,
    clock: u64,
    l: Option<u64>,
  ) -> Option<Option<Item>> {
    if self.version.update(store, bucket, clock) {
      let prev = store.get(self.prefix(), self.name(), id);
      if prev.as_ref().map(|(_, bucket, clock, _)| (*clock, *bucket)) < Some((clock, bucket)) {
        store.set(self.prefix(), self.name(), id, bucket, clock, l);
        return Some(prev);
      }
    }
    None
  }
}

fn read_row(row: &Row<'_>) -> Item {
  let id = row.get(0).unwrap();
  let bucket = row.get(1).unwrap();
  let clock = row.get(2).unwrap();
  let label: Option<_> = row.get(3).unwrap();
  (u128::from_be_bytes(id), u64::from_be_bytes(bucket), u64::from_be_bytes(clock), label.map(u64::from_be_bytes))
}

fn read_row_id(row: &Row<'_>) -> u128 {
  let id = row.get(0).unwrap();
  u128::from_be_bytes(id)
}

#[allow(clippy::type_complexity)]
fn make_row(id: u128, bucket: u64, clock: u64, label: Option<u64>) -> ([u8; 16], [u8; 8], [u8; 8], Option<[u8; 8]>) {
  (id.to_be_bytes(), bucket.to_be_bytes(), clock.to_be_bytes(), label.map(|label| label.to_be_bytes()))
}

impl<'a> NodeSetStore for Transaction<'a> {
  fn init(&mut self, prefix: &str, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{prefix}.{name}.data\" (
          id BLOB NOT NULL,
          bucket BLOB NOT NULL,
          clock BLOB NOT NULL,
          label BLOB,
          PRIMARY KEY (id)
        ) STRICT, WITHOUT ROWID;

        CREATE INDEX IF NOT EXISTS \"{prefix}.{name}.data.idx_label\" ON \"{prefix}.{name}.data\" (label);
        CREATE INDEX IF NOT EXISTS \"{prefix}.{name}.data.idx_bucket_clock\" ON \"{prefix}.{name}.data\" (bucket, clock);
        "
      ))
      .unwrap();
  }

  fn get(&mut self, prefix: &str, name: &str, id: u128) -> Option<Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, label FROM \"{prefix}.{name}.data\"
        WHERE id = ?"
      ))
      .unwrap()
      .query_row((id.to_be_bytes(),), |row| Ok(read_row(row)))
      .optional()
      .unwrap()
  }

  fn set(&mut self, prefix: &str, name: &str, id: u128, bucket: u64, clock: u64, label: Option<u64>) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{prefix}.{name}.data\" VALUES (?, ?, ?, ?)"))
      .unwrap()
      .execute(make_row(id, bucket, clock, label))
      .unwrap();
  }

  fn by_label(&mut self, prefix: &str, name: &str, label: u64) -> Vec<u128> {
    self
      .prepare_cached(&format!(
        "SELECT id FROM \"{prefix}.{name}.data\" INDEXED BY \"{prefix}.{name}.data.idx_label\"
        WHERE label = ?"
      ))
      .unwrap()
      .query_map((label.to_be_bytes(),), |row| Ok(read_row_id(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn item_by_bucket_clock_range(&mut self, prefix: &str, name: &str, bucket: u64, lower: Option<u64>) -> Vec<Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, label FROM \"{prefix}.{name}.data\" INDEXED BY \"{prefix}.{name}.data.idx_bucket_clock\"
        WHERE bucket = ? AND clock > ? ORDER BY clock ASC"
      ))
      .unwrap()
      .query_map((bucket.to_be_bytes(), lower.map(u64::to_be_bytes)), |row| Ok(read_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}
