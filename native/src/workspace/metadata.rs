use rand::Rng;
use rusqlite::OptionalExtension;
use std::{
  collections::BTreeMap,
  time::{SystemTime, UNIX_EPOCH},
};

use crate::Transactor;

/// Base schema version.
pub const CURRENT_VERSION: u64 = 1;

/// Stores the metadata for workspaces.
#[derive(Debug, Clone)]
pub struct WorkspaceMetadata {
  prefix: &'static str,
  this: u64,
}

/// Database interface for [`WorkspaceMetadata`].
pub trait WorkspaceMetadataTransactor {
  fn init_version(&mut self, prefix: &str);
  fn init_this(&mut self, prefix: &str);
  fn get_version(&self, prefix: &str) -> Option<u64>;
  fn get_this(&self, prefix: &str) -> Option<u64>;
  fn put_version(&mut self, prefix: &str, version: u64);
  fn put_this(&mut self, prefix: &str, this: u64);
}

impl WorkspaceMetadata {
  /// Creates or loads metadata.
  pub fn new(prefix: &'static str, txr: &mut impl WorkspaceMetadataTransactor) -> Self {
    txr.init_version(prefix);
    txr.init_this(prefix);
    let version = txr.get_version(prefix).unwrap_or_else(|| {
      txr.put_version(prefix, CURRENT_VERSION);
      CURRENT_VERSION
    });
    let this = txr.get_this(prefix).unwrap_or_else(|| {
      let random = rand::thread_rng().gen();
      txr.put_this(prefix, random);
      random
    });
    if version != CURRENT_VERSION {
      // Reserved for future use.
      panic!("Unsupported schema version {version}.");
    }
    Self { prefix, this }
  }

  /// Returns the name of the workspace.
  pub fn prefix(&self) -> &'static str {
    self.prefix
  }

  /// Returns this client's ID.
  pub fn this(&self) -> u64 {
    self.this
  }
}

impl WorkspaceMetadataTransactor for Transactor {
  fn init_version(&mut self, prefix: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{prefix}.version\" (
          version BLOB NOT NULL,
          PRIMARY KEY (version)
        ) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
  }

  fn init_this(&mut self, prefix: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{prefix}.this\" (
          this BLOB NOT NULL,
          PRIMARY KEY (this)
        ) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
  }

  fn get_version(&self, prefix: &str) -> Option<u64> {
    self
      .prepare_cached(&format!("SELECT version FROM \"{prefix}.version\""))
      .unwrap()
      .query_row((), |row| {
        let version = row.get(0).unwrap();
        Ok(u64::from_be_bytes(version))
      })
      .optional()
      .unwrap()
  }

  fn get_this(&self, prefix: &str) -> Option<u64> {
    self
      .prepare_cached(&format!("SELECT this FROM \"{prefix}.this\""))
      .unwrap()
      .query_row((), |row| {
        let this = row.get(0).unwrap();
        Ok(u64::from_be_bytes(this))
      })
      .optional()
      .unwrap()
  }

  fn put_version(&mut self, prefix: &str, version: u64) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{prefix}.version\" VALUES (?)"))
      .unwrap()
      .execute((version.to_be_bytes(),))
      .unwrap();
  }

  fn put_this(&mut self, prefix: &str, this: u64) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{prefix}.this\" VALUES (?)"))
      .unwrap()
      .execute((this.to_be_bytes(),))
      .unwrap();
  }
}

/// Stores the metadata for individual Γ-joinable structures.
#[derive(Debug, Clone)]
pub struct StructureMetadata {
  prefix: &'static str,
  name: &'static str,
  buckets: BTreeMap<u64, u64>, // Saved, exhaustive
  mods: BTreeMap<u64, u64>,    // Pending, exhaustive
  next: u64,
}

/// Database interface for [`StructureMetadata`].
pub trait StructureMetadataTransactor {
  fn init_buckets(&mut self, prefix: &str, name: &str);
  fn get_buckets(&self, prefix: &str, name: &str) -> BTreeMap<u64, u64>;
  fn set_bucket(&mut self, prefix: &str, name: &str, bucket: u64, clock: u64);
}

impl StructureMetadata {
  /// Creates or loads metadata.
  pub fn new(prefix: &'static str, name: &'static str, txr: &mut impl StructureMetadataTransactor) -> Self {
    txr.init_buckets(prefix, name);
    let buckets = txr.get_buckets(prefix, name);
    let mods = BTreeMap::new();
    let next = buckets.values().fold(0, |acc, &clock| acc.max(clock + 1));
    Self { prefix, name, buckets, mods, next }
  }

  /// Returns the name of the workspace.
  pub fn prefix(&self) -> &'static str {
    self.prefix
  }

  /// Returns the name of the structure.
  pub fn name(&self) -> &'static str {
    self.name
  }

  /// Returns the current clock value for given bucket.
  pub fn get(&self, bucket: u64) -> Option<u64> {
    let mut res = self.buckets.get(&bucket).copied();
    if let Some(&value) = self.mods.get(&bucket) {
      let _ = res.insert(value);
    }
    res
  }

  /// Returns the current clock values for each bucket.
  pub fn buckets(&self) -> BTreeMap<u64, u64> {
    let mut res = self.buckets.clone();
    for (&key, &value) in &self.mods {
      let _ = res.insert(key, value);
    }
    res
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> u64 {
    let measured = SystemTime::now().duration_since(UNIX_EPOCH).ok().and_then(|d| u64::try_from(d.as_nanos()).ok());
    self.next.max(measured.unwrap_or(0))
  }

  /// Updates clock for one bucket.
  pub fn update(&mut self, bucket: u64, clock: u64) -> bool {
    if self.get(bucket) < Some(clock) {
      self.mods.insert(bucket, clock);
      self.next = self.next.max(clock + 1);
      return true;
    }
    false
  }

  /// Saves all pending modifications.
  pub fn save(&mut self, txr: &mut impl StructureMetadataTransactor) {
    for (key, value) in std::mem::take(&mut self.mods) {
      self.buckets.insert(key, value);
      txr.set_bucket(self.prefix, self.name, key, value);
    }
  }
}

impl StructureMetadataTransactor for Transactor {
  fn init_buckets(&mut self, prefix: &str, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{prefix}.{name}.buckets\" (
          bucket BLOB NOT NULL,
          clock BLOB NOT NULL,
          PRIMARY KEY (bucket)
        ) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
  }

  fn get_buckets(&self, prefix: &str, name: &str) -> BTreeMap<u64, u64> {
    self
      .prepare_cached(&format!("SELECT bucket, clock FROM \"{prefix}.{name}.buckets\""))
      .unwrap()
      .query_map((), |row| {
        let bucket = row.get(0).unwrap();
        let clock = row.get(1).unwrap();
        Ok((u64::from_be_bytes(bucket), u64::from_be_bytes(clock)))
      })
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn set_bucket(&mut self, prefix: &str, name: &str, bucket: u64, clock: u64) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{prefix}.{name}.buckets\" VALUES (?, ?)"))
      .unwrap()
      .execute((bucket.to_be_bytes(), clock.to_be_bytes()))
      .unwrap();
  }
}

#[cfg(test)]
mod tests {
  use super::*;
  use rusqlite::Connection;

  #[test]
  fn workspace_metadata_simple() {
    let mut txr: Transactor = Connection::open_in_memory().unwrap().try_into().unwrap();

    let workspace = WorkspaceMetadata::new("workspace", &mut txr);
    assert_eq!(workspace.prefix(), "workspace");
    let this = workspace.this();

    let another_workspace = WorkspaceMetadata::new("another_workspace", &mut txr);
    assert_eq!(another_workspace.prefix(), "another_workspace");
    assert_ne!(another_workspace.this(), this);

    let workspace = WorkspaceMetadata::new("workspace", &mut txr);
    assert_eq!(workspace.prefix(), "workspace");
    assert_eq!(workspace.this(), this);
  }

  #[test]
  fn structure_metadata_simple() {
    let mut txr: Transactor = Connection::open_in_memory().unwrap().try_into().unwrap();

    let mut structure = StructureMetadata::new("workspace", "name", &mut txr);
    assert_eq!(structure.prefix(), "workspace");
    assert_eq!(structure.name(), "name");
    assert_eq!(structure.buckets().len(), 0);

    structure.update(1, 3u64);
    assert_eq!(structure.buckets().get(&1).unwrap(), &3);
    structure.update(1, 2u64);
    assert_eq!(structure.buckets().get(&1).unwrap(), &3);
    structure.update(1, 3u64);
    assert_eq!(structure.buckets().get(&1).unwrap(), &3);
    structure.update(1, 4u64);
    assert_eq!(structure.buckets().get(&1).unwrap(), &4);
    structure.update(2, 3u64);
    assert_eq!(structure.buckets().get(&2).unwrap(), &3);
    structure.update(2, 2u64);
    assert_eq!(structure.buckets().get(&2).unwrap(), &3);

    structure.save(&mut txr);
    assert_eq!(structure.buckets().get(&1).unwrap(), &4);
    assert_eq!(structure.buckets().get(&2).unwrap(), &3);

    let mut structure = StructureMetadata::new("workspace", "name", &mut txr);
    assert_eq!(structure.prefix(), "workspace");
    assert_eq!(structure.name(), "name");
    assert_eq!(structure.buckets(), BTreeMap::from([(1, 4u64), (2, 3u64)]));

    structure.update(3, 3u64);
    assert_eq!(structure.buckets(), BTreeMap::from([(1, 4u64), (2, 3u64), (3, 3u64)]));

    let structure = StructureMetadata::new("workspace", "name", &mut txr);
    assert_eq!(structure.buckets(), BTreeMap::from([(1, 4u64), (2, 3u64)]));

    let structure = StructureMetadata::new("workspace", "another_name", &mut txr);
    assert_eq!(structure.prefix(), "workspace");
    assert_eq!(structure.name(), "another_name");
    assert_eq!(structure.buckets().len(), 0);
  }
}
