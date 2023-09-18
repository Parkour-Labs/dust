//! A last-writer-wins element set for storing edges.

use rusqlite::{OptionalExtension, Result, Row, Transaction};
use std::{
  collections::HashMap,
  time::{SystemTime, UNIX_EPOCH},
};

use super::metadata::{StructureMetadata, StructureMetadataStore};

/// A last-writer-wins element set for storing edges.
#[derive(Debug)]
pub struct EdgeSet {
  version: StructureMetadata,
}

/// Type alias for item: `(id, bucket, (clock, src, label, dst))`.
type Item = (u128, u64, u64, Option<(u128, u64, u128)>);

/// Database interface for [`EdgeSet`].
pub trait EdgeSetStore: StructureMetadataStore {
  fn init(&mut self, prefix: &str, name: &str);
  fn get(&mut self, prefix: &str, name: &str, id: u128) -> Option<Item>;
  fn set(&mut self, prefix: &str, name: &str, id: u128, bucket: u64, clock: u64, sld: Option<(u128, u64, u128)>);
  fn label_dst_by_src(&mut self, prefix: &str, name: &str, src: u128) -> Vec<(u128, (u64, u128))>;
  fn dst_by_src_label(&mut self, prefix: &str, name: &str, src: u128, label: u64) -> Vec<(u128, u128)>;
  fn src_label_by_dst(&mut self, prefix: &str, name: &str, dst: u128) -> Vec<(u128, (u128, u64))>;
  fn src_by_dst_label(&mut self, prefix: &str, name: &str, dst: u128, label: u64) -> Vec<(u128, u128)>;
  fn item_by_bucket_clock_range(&mut self, prefix: &str, name: &str, bucket: u64, lower: Option<u64>) -> Vec<Item>;
}

impl EdgeSet {
  /// Creates or loads data.
  pub fn new(prefix: &'static str, name: &'static str, store: &mut impl EdgeSetStore) -> Self {
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
  pub fn buckets(&self) -> &HashMap<u64, u64> {
    self.version.buckets()
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> u64 {
    let measured = SystemTime::now().duration_since(UNIX_EPOCH).ok().and_then(|d| u64::try_from(d.as_nanos()).ok());
    self.version.next().max(measured.unwrap_or(0))
  }

  pub fn get(&mut self, store: &mut impl EdgeSetStore, id: u128) -> Option<Item> {
    store.get(self.prefix(), self.name(), id)
  }

  pub fn label_dst_by_src(&mut self, store: &mut impl EdgeSetStore, src: u128) -> Vec<(u128, (u64, u128))> {
    store.label_dst_by_src(self.prefix(), self.name(), src)
  }

  pub fn dst_by_src_label(&mut self, store: &mut impl EdgeSetStore, src: u128, label: u64) -> Vec<(u128, u128)> {
    store.dst_by_src_label(self.prefix(), self.name(), src, label)
  }

  pub fn src_label_by_dst(&mut self, store: &mut impl EdgeSetStore, dst: u128) -> Vec<(u128, (u128, u64))> {
    store.src_label_by_dst(self.prefix(), self.name(), dst)
  }

  pub fn src_by_dst_label(&mut self, store: &mut impl EdgeSetStore, dst: u128, label: u64) -> Vec<(u128, u128)> {
    store.src_by_dst_label(self.prefix(), self.name(), dst, label)
  }

  /// Returns all actions strictly later than given clock values (sorted by clock value).
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl EdgeSetStore, version: HashMap<u64, u64>) -> Vec<Item> {
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
    store: &mut impl EdgeSetStore,
    id: u128,
    bucket: u64,
    clock: u64,
    sld: Option<(u128, u64, u128)>,
  ) -> Option<Option<Item>> {
    if self.version.update(store, bucket, clock) {
      let prev = store.get(self.prefix(), self.name(), id);
      if prev.as_ref().map(|(_, bucket, clock, _)| (*clock, *bucket)) < Some((clock, bucket)) {
        store.set(self.prefix(), self.name(), id, bucket, clock, sld);
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
  let src: Option<_> = row.get(3).unwrap();
  let label: Option<_> = row.get(4).unwrap();
  let dst: Option<_> = row.get(5).unwrap();
  (
    u128::from_be_bytes(id),
    u64::from_be_bytes(bucket),
    u64::from_be_bytes(clock),
    dst.map(|dst| (u128::from_be_bytes(src.unwrap()), u64::from_be_bytes(label.unwrap()), u128::from_be_bytes(dst))),
  )
}

fn read_row_id_label_dst(row: &Row<'_>) -> (u128, (u64, u128)) {
  let id = row.get(0).unwrap();
  let label = row.get(1).unwrap();
  let dst = row.get(2).unwrap();
  (u128::from_be_bytes(id), (u64::from_be_bytes(label), u128::from_be_bytes(dst)))
}

fn read_row_id_dst(row: &Row<'_>) -> (u128, u128) {
  let id = row.get(0).unwrap();
  let dst = row.get(1).unwrap();
  (u128::from_be_bytes(id), u128::from_be_bytes(dst))
}

fn read_row_id_src_label(row: &Row<'_>) -> (u128, (u128, u64)) {
  let id = row.get(0).unwrap();
  let src = row.get(1).unwrap();
  let label = row.get(2).unwrap();
  (u128::from_be_bytes(id), (u128::from_be_bytes(src), u64::from_be_bytes(label)))
}

fn read_row_id_src(row: &Row<'_>) -> (u128, u128) {
  let id = row.get(0).unwrap();
  let src = row.get(1).unwrap();
  (u128::from_be_bytes(id), u128::from_be_bytes(src))
}

#[allow(clippy::type_complexity)]
fn make_row(
  id: u128,
  bucket: u64,
  clock: u64,
  sld: Option<(u128, u64, u128)>,
) -> ([u8; 16], [u8; 8], [u8; 8], Option<[u8; 16]>, Option<[u8; 8]>, Option<[u8; 16]>) {
  (
    id.to_be_bytes(),
    bucket.to_be_bytes(),
    clock.to_be_bytes(),
    sld.map(|(src, _, _)| src.to_be_bytes()),
    sld.map(|(_, label, _)| label.to_be_bytes()),
    sld.map(|(_, _, dst)| dst.to_be_bytes()),
  )
}

impl<'a> EdgeSetStore for Transaction<'a> {
  fn init(&mut self, prefix: &str, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{prefix}.{name}.data\" (
          id BLOB NOT NULL,
          bucket BLOB NOT NULL,
          clock BLOB NOT NULL,
          src BLOB,
          label BLOB,
          dst BLOB,
          PRIMARY KEY (id)
        ) STRICT, WITHOUT ROWID;

        CREATE INDEX IF NOT EXISTS \"{prefix}.{name}.data.idx_src_label\" ON \"{prefix}.{name}.data\" (src, label);
        CREATE INDEX IF NOT EXISTS \"{prefix}.{name}.data.idx_dst_label\" ON \"{prefix}.{name}.data\" (dst, label);
        CREATE INDEX IF NOT EXISTS \"{prefix}.{name}.data.idx_bucket_clock\" ON \"{prefix}.{name}.data\" (bucket, clock);
        "
      ))
      .unwrap();
  }

  fn get(&mut self, prefix: &str, name: &str, id: u128) -> Option<Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, src, label, dst FROM \"{prefix}.{name}.data\"
        WHERE id = ?"
      ))
      .unwrap()
      .query_row((id.to_be_bytes(),), |row| Ok(read_row(row)))
      .optional()
      .unwrap()
  }

  fn set(&mut self, prefix: &str, name: &str, id: u128, bucket: u64, clock: u64, sld: Option<(u128, u64, u128)>) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{prefix}.{name}.data\" VALUES (?, ?, ?, ?, ?, ?)"))
      .unwrap()
      .execute(make_row(id, bucket, clock, sld))
      .unwrap();
  }

  fn label_dst_by_src(&mut self, prefix: &str, name: &str, src: u128) -> Vec<(u128, (u64, u128))> {
    self
      .prepare_cached(&format!(
        "SELECT id, label, dst FROM \"{prefix}.{name}.data\" INDEXED BY \"{prefix}.{name}.data.idx_src_label\"
        WHERE src = ?"
      ))
      .unwrap()
      .query_map((src.to_be_bytes(),), |row| Ok(read_row_id_label_dst(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn dst_by_src_label(&mut self, prefix: &str, name: &str, src: u128, label: u64) -> Vec<(u128, u128)> {
    self
      .prepare_cached(&format!(
        "SELECT id, dst FROM \"{prefix}.{name}.data\" INDEXED BY \"{prefix}.{name}.data.idx_src_label\"
        WHERE src = ? AND label = ?"
      ))
      .unwrap()
      .query_map((src.to_be_bytes(), label.to_be_bytes()), |row| Ok(read_row_id_dst(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn src_label_by_dst(&mut self, prefix: &str, name: &str, dst: u128) -> Vec<(u128, (u128, u64))> {
    self
      .prepare_cached(&format!(
        "SELECT id, src, label FROM \"{prefix}.{name}.data\" INDEXED BY \"{prefix}.{name}.data.idx_dst_label\"
        WHERE dst = ?"
      ))
      .unwrap()
      .query_map((dst.to_be_bytes(),), |row| Ok(read_row_id_src_label(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn src_by_dst_label(&mut self, prefix: &str, name: &str, dst: u128, label: u64) -> Vec<(u128, u128)> {
    self
      .prepare_cached(&format!(
        "SELECT id, src FROM \"{prefix}.{name}.data\" INDEXED BY \"{prefix}.{name}.data.idx_dst_label\"
        WHERE dst = ? AND label = ?"
      ))
      .unwrap()
      .query_map((dst.to_be_bytes(), label.to_be_bytes()), |row| Ok(read_row_id_src(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn item_by_bucket_clock_range(&mut self, prefix: &str, name: &str, bucket: u64, lower: Option<u64>) -> Vec<Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, src, label, dst FROM \"{prefix}.{name}.data\" INDEXED BY \"{prefix}.{name}.data.idx_bucket_clock\"
        WHERE bucket = ? AND clock > ? ORDER BY clock ASC"
      ))
      .unwrap()
      .query_map((bucket.to_be_bytes(), lower.map(u64::to_be_bytes)), |row| Ok(read_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}
