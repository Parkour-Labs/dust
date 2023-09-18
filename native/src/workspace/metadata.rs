use rand::Rng;
use rusqlite::{OptionalExtension, Transaction};
use std::collections::HashMap;

/// Base schema version.
pub const CURRENT_VERSION: u64 = 1;

/// Stores the metadata for workspaces.
#[derive(Debug, Clone)]
pub struct WorkspaceMetadata {
  prefix: &'static str,
  this: u64,
}

/// Database interface for [`WorkspaceMetadata`].
pub trait WorkspaceMetadataStore {
  fn init_version(&mut self, prefix: &str);
  fn init_this(&mut self, prefix: &str);
  fn get_version(&mut self, prefix: &str) -> Option<u64>;
  fn get_this(&mut self, prefix: &str) -> Option<u64>;
  fn put_version(&mut self, prefix: &str, version: u64);
  fn put_this(&mut self, prefix: &str, this: u64);
}

impl WorkspaceMetadata {
  pub fn new(prefix: &'static str, store: &mut impl WorkspaceMetadataStore) -> Self {
    store.init_version(prefix);
    store.init_this(prefix);
    let version = store.get_version(prefix).unwrap_or_else(|| {
      store.put_version(prefix, CURRENT_VERSION);
      CURRENT_VERSION
    });
    let this = store.get_this(prefix).unwrap_or_else(|| {
      let random = rand::thread_rng().gen();
      store.put_this(prefix, random);
      random
    });
    if version != CURRENT_VERSION {
      // Reserved for future use.
      panic!("Unsupported schema version {version}.");
    }
    Self { prefix, this }
  }

  pub fn prefix(&self) -> &'static str {
    self.prefix
  }

  pub fn this(&self) -> u64 {
    self.this
  }
}

impl<'a> WorkspaceMetadataStore for Transaction<'a> {
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

  fn get_version(&mut self, prefix: &str) -> Option<u64> {
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

  fn get_this(&mut self, prefix: &str) -> Option<u64> {
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
  buckets: HashMap<u64, u64>,
}

/// Database interface for [`StructureMetadata`].
pub trait StructureMetadataStore {
  fn init_buckets(&mut self, prefix: &str, name: &str);
  fn get_buckets(&mut self, prefix: &str, name: &str) -> HashMap<u64, u64>;
  fn set_bucket(&mut self, prefix: &str, name: &str, bucket: u64, clock: u64);
}

impl StructureMetadata {
  /// Creates or loads metadata.
  pub fn new(prefix: &'static str, name: &'static str, store: &mut impl StructureMetadataStore) -> Self {
    store.init_buckets(prefix, name);
    let buckets = store.get_buckets(prefix, name);
    Self { prefix, name, buckets }
  }

  /// Returns the prefix of the structure.
  pub fn prefix(&self) -> &'static str {
    self.prefix
  }

  /// Returns the name of the structure.
  pub fn name(&self) -> &'static str {
    self.name
  }

  /// Returns the current clock values values for each bucket.
  pub fn buckets(&self) -> &HashMap<u64, u64> {
    &self.buckets
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> u64 {
    self.buckets.values().fold(0, |acc, &clock| acc.max(clock + 1))
  }

  /// Updates clock for one bucket.
  pub fn update(&mut self, store: &mut impl StructureMetadataStore, bucket: u64, clock: u64) -> bool {
    if self.buckets.get(&bucket) < Some(&clock) {
      store.set_bucket(self.prefix, self.name, bucket, clock);
      self.buckets.insert(bucket, clock);
      true
    } else {
      false
    }
  }
}

impl<'a> StructureMetadataStore for Transaction<'a> {
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

  fn get_buckets(&mut self, prefix: &str, name: &str) -> HashMap<u64, u64> {
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
    let mut conn = Connection::open_in_memory().unwrap();
    let mut txn = conn.transaction().unwrap();

    let workspace = WorkspaceMetadata::new("workspace", &mut txn);
    assert_eq!(workspace.prefix(), "workspace");
    let this = workspace.this();

    let another_workspace = WorkspaceMetadata::new("another_workspace", &mut txn);
    assert_eq!(another_workspace.prefix(), "another_workspace");
    assert_ne!(another_workspace.this(), this);

    let workspace = WorkspaceMetadata::new("workspace", &mut txn);
    assert_eq!(workspace.prefix(), "workspace");
    assert_eq!(workspace.this(), this);
  }

  #[test]
  fn structure_metadata_simple() {
    let mut conn = Connection::open_in_memory().unwrap();
    let mut txn = conn.transaction().unwrap();

    let mut structure = StructureMetadata::new("workspace", "name", &mut txn);
    assert_eq!(structure.prefix(), "workspace");
    assert_eq!(structure.name(), "name");
    assert_eq!(structure.buckets().len(), 0);

    structure.update(&mut txn, 1, 3u64);
    assert_eq!(structure.buckets().get(&1).unwrap(), &3);
    structure.update(&mut txn, 1, 2u64);
    assert_eq!(structure.buckets().get(&1).unwrap(), &3);
    structure.update(&mut txn, 1, 3u64);
    assert_eq!(structure.buckets().get(&1).unwrap(), &3);
    structure.update(&mut txn, 1, 4u64);
    assert_eq!(structure.buckets().get(&1).unwrap(), &4);
    structure.update(&mut txn, 2, 3u64);
    assert_eq!(structure.buckets().get(&2).unwrap(), &3);
    structure.update(&mut txn, 2, 2u64);
    assert_eq!(structure.buckets().get(&2).unwrap(), &3);

    let mut structure = StructureMetadata::new("workspace", "name", &mut txn);
    assert_eq!(structure.prefix(), "workspace");
    assert_eq!(structure.name(), "name");
    assert_eq!(structure.buckets(), &HashMap::from([(1, 4u64), (2, 3u64)]));

    structure.update(&mut txn, 3, 3u64);
    assert_eq!(structure.buckets(), &HashMap::from([(1, 4u64), (2, 3u64), (3, 3u64)]));

    let structure = StructureMetadata::new("workspace", "another_name", &mut txn);
    assert_eq!(structure.prefix(), "workspace");
    assert_eq!(structure.name(), "another_name");
    assert_eq!(structure.buckets().len(), 0);
  }
}
