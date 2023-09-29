use rusqlite::{OptionalExtension, Result, Row};
use std::collections::{btree_map::Entry, BTreeMap};

use super::metadata::{StructureMetadata, StructureMetadataTransactor};
use crate::Transactor;

/// A last-writer-wins element set for storing edges.
#[derive(Debug)]
pub struct EdgeSet {
  metadata: StructureMetadata,
  mods: BTreeMap<u128, (Option<Item>, Item)>,
}

/// `(bucket, clock, (src, label, dst))`.
type Item = (u64, u64, Option<(u128, u64, u128)>);

fn item_lt(lhs: &Item, rhs: &Item) -> bool {
  (lhs.1, lhs.0) < (rhs.1, rhs.0)
}

/// Database interface for [`EdgeSet`].
pub trait EdgeSetTransactor: StructureMetadataTransactor {
  fn init(&mut self, prefix: &str, name: &str);
  fn get(&self, prefix: &str, name: &str, id: u128) -> Option<Item>;
  fn set(&mut self, prefix: &str, name: &str, id: u128, item: Item);
  fn id_label_dst_by_src(&self, prefix: &str, name: &str, src: u128) -> BTreeMap<u128, (u64, u128)>;
  fn id_dst_by_src_label(&self, prefix: &str, name: &str, src: u128, label: u64) -> BTreeMap<u128, u128>;
  fn id_src_label_by_dst(&self, prefix: &str, name: &str, dst: u128) -> BTreeMap<u128, (u128, u64)>;
  fn id_src_by_dst_label(&self, prefix: &str, name: &str, dst: u128, label: u64) -> BTreeMap<u128, u128>;
  fn by_bucket_clock_range(&self, prefix: &str, name: &str, bucket: u64, lower: Option<u64>) -> Vec<(u128, Item)>;
}

impl EdgeSet {
  /// Creates or loads data.
  pub fn new(prefix: &'static str, name: &'static str, txr: &mut impl EdgeSetTransactor) -> Self {
    let metadata = StructureMetadata::new(prefix, name, txr);
    let mods = BTreeMap::new();
    txr.init(prefix, name);
    Self { metadata, mods }
  }

  /// Returns the name of the workspace.
  pub fn prefix(&self) -> &'static str {
    self.metadata.prefix()
  }

  /// Returns the name of the structure.
  pub fn name(&self) -> &'static str {
    self.metadata.name()
  }

  /// Returns the current clock values for each bucket.
  pub fn buckets(&self) -> BTreeMap<u64, u64> {
    self.metadata.buckets()
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> u64 {
    self.metadata.next()
  }

  /// Returns pending modifications.
  pub fn mods(&self) -> Vec<(u128, Option<(u128, u64, u128)>, Option<(u128, u64, u128)>)> {
    let mut res = Vec::new();
    for (id, (prev, curr)) in &self.mods {
      res.push((*id, prev.and_then(|(_, _, sld)| sld), curr.2));
    }
    res
  }

  pub fn get(&self, txr: &impl EdgeSetTransactor, id: u128) -> Option<Item> {
    self.mods.get(&id).map_or_else(|| txr.get(self.prefix(), self.name(), id), |(_, curr)| Some(*curr))
  }

  pub fn id_label_dst_by_src(&self, txr: &impl EdgeSetTransactor, src: u128) -> BTreeMap<u128, (u64, u128)> {
    let mut res = txr.id_label_dst_by_src(self.prefix(), self.name(), src);
    for (id, (_, (_, _, sld))) in &self.mods {
      match sld {
        Some((src_, label, dst)) if src_ == &src => res.insert(*id, (*label, *dst)),
        _ => res.remove(id),
      };
    }
    res
  }

  pub fn id_dst_by_src_label(&self, txr: &impl EdgeSetTransactor, src: u128, label: u64) -> BTreeMap<u128, u128> {
    let mut res = txr.id_dst_by_src_label(self.prefix(), self.name(), src, label);
    for (id, (_, (_, _, sld))) in &self.mods {
      match sld {
        Some((src_, label_, dst)) if src_ == &src && label_ == &label => res.insert(*id, *dst),
        _ => res.remove(id),
      };
    }
    res
  }

  pub fn id_src_label_by_dst(&self, txr: &impl EdgeSetTransactor, dst: u128) -> BTreeMap<u128, (u128, u64)> {
    let mut res = txr.id_src_label_by_dst(self.prefix(), self.name(), dst);
    for (id, (_, (_, _, sld))) in &self.mods {
      match sld {
        Some((src, label, dst_)) if dst_ == &dst => res.insert(*id, (*src, *label)),
        _ => res.remove(id),
      };
    }
    res
  }

  pub fn id_src_by_dst_label(&self, txr: &impl EdgeSetTransactor, dst: u128, label: u64) -> BTreeMap<u128, u128> {
    let mut res = txr.id_src_by_dst_label(self.prefix(), self.name(), dst, label);
    for (id, (_, (_, _, sld))) in &self.mods {
      match sld {
        Some((src, label_, dst_)) if dst_ == &dst && label_ == &label => res.insert(*id, *src),
        _ => res.remove(id),
      };
    }
    res
  }

  /// Returns all actions strictly later than given clock values.
  /// Absent entries are assumed to be `None`.
  pub fn actions(&self, txr: &impl EdgeSetTransactor, version: BTreeMap<u64, u64>) -> BTreeMap<u128, Item> {
    let mut res = BTreeMap::new();
    for &bucket in self.buckets().keys() {
      let lower = version.get(&bucket).copied();
      for (id, item) in txr.by_bucket_clock_range(self.prefix(), self.name(), bucket, lower) {
        res.insert(id, item);
      }
    }
    for (id, (_, item)) in &self.mods {
      let (bucket, clock, _) = item;
      if Some(clock) > version.get(bucket) {
        res.insert(*id, *item);
      } else {
        res.remove(id);
      }
    }
    res
  }

  /// Modifies item.
  pub fn set(
    &mut self,
    txr: &impl EdgeSetTransactor,
    id: u128,
    bucket: u64,
    clock: u64,
    sld: Option<(u128, u64, u128)>,
  ) -> bool {
    if self.metadata.update(bucket, clock) {
      let item = (bucket, clock, sld);
      match self.mods.entry(id) {
        Entry::Vacant(entry) => {
          let prev = txr.get(self.metadata.prefix(), self.metadata.name(), id);
          if prev.is_none() || item_lt(prev.as_ref().unwrap(), &item) {
            entry.insert((prev, item));
            return true;
          }
        }
        Entry::Occupied(mut entry) => {
          if item_lt(&entry.get().1, &item) {
            entry.get_mut().1 = item;
            return true;
          }
        }
      }
    }
    false
  }

  /// Saves all pending modifications.
  pub fn save(&mut self, txr: &mut impl EdgeSetTransactor) {
    self.metadata.save(txr);
    for (id, (_, curr)) in std::mem::take(&mut self.mods) {
      txr.set(self.prefix(), self.name(), id, curr);
    }
  }
}

fn read_row(row: &Row<'_>) -> (u128, Item) {
  let id = row.get(0).unwrap();
  let bucket = row.get(1).unwrap();
  let clock = row.get(2).unwrap();
  let src: Option<_> = row.get(3).unwrap();
  let label: Option<_> = row.get(4).unwrap();
  let dst: Option<_> = row.get(5).unwrap();
  (
    u128::from_be_bytes(id),
    (
      u64::from_be_bytes(bucket),
      u64::from_be_bytes(clock),
      dst.map(|dst| (u128::from_be_bytes(src.unwrap()), u64::from_be_bytes(label.unwrap()), u128::from_be_bytes(dst))),
    ),
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

fn make_row(id: u128, item: Item) -> ([u8; 16], [u8; 8], [u8; 8], Option<[u8; 16]>, Option<[u8; 8]>, Option<[u8; 16]>) {
  let (bucket, clock, sld) = item;
  let (src, label, dst) = match sld {
    Some((src, label, dst)) => (Some(src.to_be_bytes()), Some(label.to_be_bytes()), Some(dst.to_be_bytes())),
    None => (None, None, None),
  };
  (id.to_be_bytes(), bucket.to_be_bytes(), clock.to_be_bytes(), src, label, dst)
}

impl EdgeSetTransactor for Transactor {
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

  fn get(&self, prefix: &str, name: &str, id: u128) -> Option<Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, src, label, dst FROM \"{prefix}.{name}.data\"
        WHERE id = ?"
      ))
      .unwrap()
      .query_row((id.to_be_bytes(),), |row| Ok(read_row(row)))
      .optional()
      .unwrap()
      .map(|(_, item)| item)
  }

  fn set(&mut self, prefix: &str, name: &str, id: u128, item: Item) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{prefix}.{name}.data\" VALUES (?, ?, ?, ?, ?, ?)"))
      .unwrap()
      .execute(make_row(id, item))
      .unwrap();
  }

  fn id_label_dst_by_src(&self, prefix: &str, name: &str, src: u128) -> BTreeMap<u128, (u64, u128)> {
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

  fn id_dst_by_src_label(&self, prefix: &str, name: &str, src: u128, label: u64) -> BTreeMap<u128, u128> {
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

  fn id_src_label_by_dst(&self, prefix: &str, name: &str, dst: u128) -> BTreeMap<u128, (u128, u64)> {
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

  fn id_src_by_dst_label(&self, prefix: &str, name: &str, dst: u128, label: u64) -> BTreeMap<u128, u128> {
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

  fn by_bucket_clock_range(&self, prefix: &str, name: &str, bucket: u64, lower: Option<u64>) -> Vec<(u128, Item)> {
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
