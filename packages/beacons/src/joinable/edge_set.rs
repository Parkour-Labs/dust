//! A last-writer-wins element set for storing edges.

use rusqlite::{OptionalExtension, Result, Row, Transaction};
use std::{
  collections::HashMap,
  time::{SystemTime, UNIX_EPOCH},
};

use super::metadata::{Metadata, MetadataStore};

/// A last-writer-wins element set for storing edges.
#[derive(Debug)]
pub struct EdgeSet {
  version: Metadata,
}

/// Type alias for item: `(id, bucket, clock, (src, label, dst))`.
type Item = (u128, u64, u64, Option<(u128, u64, u128)>);

/// Database interface for [`EdgeSet`].
pub trait EdgeSetStore: MetadataStore {
  fn init(&mut self, name: &str);
  fn get(&mut self, name: &str, id: u128) -> Option<Item>;
  fn set(&mut self, name: &str, id: u128, bucket: u64, clock: u64, sld: Option<(u128, u64, u128)>);
  fn label_dst_by_src(&mut self, name: &str, src: u128) -> Vec<(u128, (u64, u128))>;
  fn dst_by_src_label(&mut self, name: &str, src: u128, label: u64) -> Vec<(u128, u128)>;
  fn src_dst_by_label(&mut self, name: &str, label: u64) -> Vec<(u128, (u128, u128))>;
  fn src_by_label_dst(&mut self, name: &str, label: u64, dst: u128) -> Vec<(u128, u128)>;
  fn item_by_bucket_clock_range(&mut self, name: &str, bucket: u64, lower: Option<u64>) -> Vec<Item>;
}

impl EdgeSet {
  /// Creates or loads data.
  pub fn new(name: &'static str, store: &mut impl EdgeSetStore) -> Self {
    let version = Metadata::new(name, store);
    store.init(name);
    Self { version }
  }

  /// Returns the name of the structure.
  pub fn name(&self) -> &'static str {
    self.version.name()
  }

  /// Returns this bucket ID.
  pub fn this(&self) -> u64 {
    self.version.this()
  }

  /// Returns the current clock values for each bucket.
  pub fn buckets(&self) -> &HashMap<u64, u64> {
    self.version.buckets()
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> u64 {
    let measured = match SystemTime::now().duration_since(UNIX_EPOCH) {
      Ok(n) => n.as_secs(),
      Err(_) => 0,
    };
    self.version.next().max(measured)
  }

  pub fn get(&mut self, store: &mut impl EdgeSetStore, id: u128) -> Option<Item> {
    store.get(self.name(), id)
  }

  pub fn label_dst_by_src(&mut self, store: &mut impl EdgeSetStore, src: u128) -> Vec<(u128, (u64, u128))> {
    store.label_dst_by_src(self.name(), src)
  }

  pub fn dst_by_src_label(&mut self, store: &mut impl EdgeSetStore, src: u128, label: u64) -> Vec<(u128, u128)> {
    store.dst_by_src_label(self.name(), src, label)
  }

  pub fn src_dst_by_label(&mut self, store: &mut impl EdgeSetStore, label: u64) -> Vec<(u128, (u128, u128))> {
    store.src_dst_by_label(self.name(), label)
  }

  pub fn src_by_label_dst(&mut self, store: &mut impl EdgeSetStore, label: u64, dst: u128) -> Vec<(u128, u128)> {
    store.src_by_label_dst(self.name(), label, dst)
  }

  /// Returns all actions strictly later than given clock values (sorted by clock value).
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl EdgeSetStore, version: HashMap<u64, u64>) -> Vec<Item> {
    let mut res = Vec::new();
    for &bucket in self.buckets().keys() {
      let lower = version.get(&bucket).copied();
      for elem in store.item_by_bucket_clock_range(self.name(), bucket, lower) {
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
      let prev = store.get(self.name(), id);
      if prev.as_ref().map(|(_, bucket, clock, _)| (*clock, *bucket)) < Some((clock, bucket)) {
        store.set(self.name(), id, bucket, clock, sld);
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

fn read_row_id_src_dst(row: &Row<'_>) -> (u128, (u128, u128)) {
  let id = row.get(0).unwrap();
  let src = row.get(1).unwrap();
  let dst = row.get(2).unwrap();
  (u128::from_be_bytes(id), (u128::from_be_bytes(src), u128::from_be_bytes(dst)))
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
  fn init(&mut self, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{name}.data\" (
          id BLOB NOT NULL,
          bucket BLOB NOT NULL,
          clock BLOB NOT NULL,
          src BLOB,
          label BLOB,
          dst BLOB,
          PRIMARY KEY (id)
        ) STRICT, WITHOUT ROWID;

        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_src_label\" ON \"{name}.data\" (src, label);
        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_label_dst\" ON \"{name}.data\" (label, dst);
        CREATE INDEX IF NOT EXISTS \"{name}.data.idx_bucket_clock\" ON \"{name}.data\" (bucket, clock);
        "
      ))
      .unwrap();
  }

  fn get(&mut self, name: &str, id: u128) -> Option<Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, src, label, dst FROM \"{name}.data\"
        WHERE id = ?"
      ))
      .unwrap()
      .query_row((id.to_be_bytes(),), |row| Ok(read_row(row)))
      .optional()
      .unwrap()
  }

  fn set(&mut self, name: &str, id: u128, bucket: u64, clock: u64, sld: Option<(u128, u64, u128)>) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.data\" VALUES (?, ?, ?, ?, ?, ?)"))
      .unwrap()
      .execute(make_row(id, bucket, clock, sld))
      .unwrap();
  }

  fn label_dst_by_src(&mut self, name: &str, src: u128) -> Vec<(u128, (u64, u128))> {
    self
      .prepare_cached(&format!(
        "SELECT id, label, dst FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_src_label\"
        WHERE src = ?"
      ))
      .unwrap()
      .query_map((src.to_be_bytes(),), |row| Ok(read_row_id_label_dst(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn dst_by_src_label(&mut self, name: &str, src: u128, label: u64) -> Vec<(u128, u128)> {
    self
      .prepare_cached(&format!(
        "SELECT id, dst FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_src_label\"
        WHERE src = ? AND label = ?"
      ))
      .unwrap()
      .query_map((src.to_be_bytes(), label.to_be_bytes()), |row| Ok(read_row_id_dst(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn src_dst_by_label(&mut self, name: &str, label: u64) -> Vec<(u128, (u128, u128))> {
    self
      .prepare_cached(&format!(
        "SELECT id, src, dst FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_label_dst\"
        WHERE label = ?"
      ))
      .unwrap()
      .query_map((label.to_be_bytes(),), |row| Ok(read_row_id_src_dst(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn src_by_label_dst(&mut self, name: &str, label: u64, dst: u128) -> Vec<(u128, u128)> {
    self
      .prepare_cached(&format!(
        "SELECT id, src FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_label_dst\"
        WHERE label = ? AND dst = ?"
      ))
      .unwrap()
      .query_map((label.to_be_bytes(), dst.to_be_bytes()), |row| Ok(read_row_id_src(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn item_by_bucket_clock_range(&mut self, name: &str, bucket: u64, lower: Option<u64>) -> Vec<Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, src, label, dst FROM \"{name}.data\" INDEXED BY \"{name}.data.idx_bucket_clock\"
        WHERE bucket = ? AND clock > ? ORDER BY clock ASC"
      ))
      .unwrap()
      .query_map((bucket.to_be_bytes(), lower.map(u64::to_be_bytes)), |row| Ok(read_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}
