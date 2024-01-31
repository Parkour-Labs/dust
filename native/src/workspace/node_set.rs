// Copyright 2024 ParkourLabs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

use rusqlite::{OptionalExtension, Result, Row};
use std::collections::{btree_map::Entry, BTreeMap};

use super::metadata::{StructureMetadata, StructureMetadataTransactor};
use crate::Transactor;

/// A last-writer-wins element set for storing nodes.
#[derive(Debug)]
pub struct NodeSet {
  metadata: StructureMetadata,
  mods: BTreeMap<u128, (Option<Item>, Item)>,
}

/// `(bucket, clock, label)`.
type Item = (u64, u64, Option<u64>);

fn item_lt(lhs: &Item, rhs: &Item) -> bool {
  (lhs.1, lhs.0) < (rhs.1, rhs.0)
}

/// Database interface for [`NodeSet`].
pub trait NodeSetTransactor: StructureMetadataTransactor {
  fn init(&mut self, prefix: &str, name: &str);
  fn get(&self, prefix: &str, name: &str, id: u128) -> Option<Item>;
  fn set(&mut self, prefix: &str, name: &str, id: u128, item: Item);
  fn id_by_label(&self, prefix: &str, name: &str, label: u64) -> BTreeMap<u128, ()>;
  fn by_bucket_clock_range(&self, prefix: &str, name: &str, bucket: u64, lower: Option<u64>) -> BTreeMap<u128, Item>;
}

impl NodeSet {
  /// Creates or loads data.
  pub fn new(prefix: &'static str, name: &'static str, txr: &mut impl NodeSetTransactor) -> Self {
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
  pub fn mods(&self) -> Vec<(u128, Option<u64>, Option<u64>)> {
    let mut res = Vec::new();
    for (id, (prev, curr)) in &self.mods {
      res.push((*id, prev.and_then(|(_, _, l)| l), curr.2));
    }
    res
  }

  pub fn exists(&self, txr: &impl NodeSetTransactor, id: u128) -> bool {
    self.get(txr, id).and_then(|(_, _, label)| label).is_some()
  }

  pub fn get(&self, txr: &impl NodeSetTransactor, id: u128) -> Option<Item> {
    self.mods.get(&id).map_or_else(|| txr.get(self.prefix(), self.name(), id), |(_, curr)| Some(*curr))
  }

  pub fn id_by_label(&self, txr: &impl NodeSetTransactor, label: u64) -> BTreeMap<u128, ()> {
    let mut res = txr.id_by_label(self.prefix(), self.name(), label);
    for (id, (_, (_, _, l))) in &self.mods {
      match l {
        Some(label_) if label_ == &label => res.insert(*id, ()),
        _ => res.remove(id),
      };
    }
    res
  }

  /// Returns all actions strictly later than given clock values.
  /// Absent entries are assumed to be `None`.
  pub fn actions(&self, txr: &impl NodeSetTransactor, version: BTreeMap<u64, u64>) -> BTreeMap<u128, Item> {
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
  pub fn set(&mut self, txr: &impl NodeSetTransactor, id: u128, bucket: u64, clock: u64, l: Option<u64>) -> bool {
    if self.metadata.update(bucket, clock) {
      let item = (bucket, clock, l);
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
  pub fn save(&mut self, txr: &mut impl NodeSetTransactor) {
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
  let label: Option<_> = row.get(3).unwrap();
  (u128::from_be_bytes(id), (u64::from_be_bytes(bucket), u64::from_be_bytes(clock), label.map(u64::from_be_bytes)))
}

fn read_row_id(row: &Row<'_>) -> (u128, ()) {
  let id = row.get(0).unwrap();
  (u128::from_be_bytes(id), ())
}

fn make_row(id: u128, item: Item) -> ([u8; 16], [u8; 8], [u8; 8], Option<[u8; 8]>) {
  let (bucket, clock, l) = item;
  (id.to_be_bytes(), bucket.to_be_bytes(), clock.to_be_bytes(), l.map(|label| label.to_be_bytes()))
}

impl NodeSetTransactor for Transactor {
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

  fn get(&self, prefix: &str, name: &str, id: u128) -> Option<Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, label FROM \"{prefix}.{name}.data\"
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
      .prepare_cached(&format!("REPLACE INTO \"{prefix}.{name}.data\" VALUES (?, ?, ?, ?)"))
      .unwrap()
      .execute(make_row(id, item))
      .unwrap();
  }

  fn id_by_label(&self, prefix: &str, name: &str, label: u64) -> BTreeMap<u128, ()> {
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

  fn by_bucket_clock_range(&self, prefix: &str, name: &str, bucket: u64, lower: Option<u64>) -> BTreeMap<u128, Item> {
    self
      .prepare_cached(&format!(
        "SELECT id, bucket, clock, label FROM \"{prefix}.{name}.data\" INDEXED BY \"{prefix}.{name}.data.idx_bucket_clock\"
        WHERE bucket = ? AND clock > ?"
      ))
      .unwrap()
      .query_map((bucket.to_be_bytes(), lower.map(u64::to_be_bytes)), |row| Ok(read_row(row)))
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }
}
