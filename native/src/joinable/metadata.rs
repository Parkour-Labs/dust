use rand::Rng;
use rusqlite::{OptionalExtension, Transaction};
use std::collections::HashMap;

/// Stores the metadata for Γ-joinable structures.
#[derive(Debug, Clone)]
pub struct Metadata {
  name: &'static str,
  this: u64,
  buckets: HashMap<u64, u64>,
}

impl Metadata {
  /// Creates or loads metadata.
  pub fn new(name: &'static str, store: &mut impl MetadataStore) -> Self {
    store.init_buckets(name);
    store.init_this(name);
    let buckets = store.get_buckets(name);
    let this = store.get_this(name).unwrap_or_else(|| {
      let random = rand::thread_rng().gen();
      store.put_this(name, random);
      random
    });
    Self { name, this, buckets }
  }

  /// Returns the name of the structure.
  pub fn name(&self) -> &'static str {
    self.name
  }

  /// Returns this bucket ID.
  pub fn this(&self) -> u64 {
    self.this
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
  pub fn update(&mut self, store: &mut impl MetadataStore, bucket: u64, clock: u64) -> bool {
    if self.buckets.get(&bucket) < Some(&clock) {
      store.set_bucket(self.name, bucket, clock);
      self.buckets.insert(bucket, clock);
      true
    } else {
      false
    }
  }
}

/// Database interface for [`Metadata`].
pub trait MetadataStore {
  fn init_this(&mut self, name: &str);
  fn get_this(&mut self, name: &str) -> Option<u64>;
  fn put_this(&mut self, name: &str, this: u64);
  fn init_buckets(&mut self, name: &str);
  fn get_buckets(&mut self, name: &str) -> HashMap<u64, u64>;
  fn set_bucket(&mut self, name: &str, bucket: u64, clock: u64);
}

impl<'a> MetadataStore for Transaction<'a> {
  fn init_this(&mut self, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{name}.this\" (
          bucket BLOB NOT NULL,
          PRIMARY KEY (bucket)
        ) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
  }

  fn get_this(&mut self, name: &str) -> Option<u64> {
    self
      .prepare_cached(&format!("SELECT bucket FROM \"{name}.this\""))
      .unwrap()
      .query_row((), |row| {
        let bucket = row.get(0).unwrap();
        Ok(u64::from_be_bytes(bucket))
      })
      .optional()
      .unwrap()
  }

  fn put_this(&mut self, name: &str, this: u64) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.this\" VALUES (?)"))
      .unwrap()
      .execute((this.to_be_bytes(),))
      .unwrap();
  }

  fn init_buckets(&mut self, name: &str) {
    self
      .execute_batch(&format!(
        "
        CREATE TABLE IF NOT EXISTS \"{name}.buckets\" (
          bucket BLOB NOT NULL,
          clock BLOB NOT NULL,
          PRIMARY KEY (bucket)
        ) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
  }

  fn get_buckets(&mut self, name: &str) -> HashMap<u64, u64> {
    self
      .prepare_cached(&format!("SELECT bucket, clock FROM \"{name}.buckets\""))
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

  fn set_bucket(&mut self, name: &str, bucket: u64, clock: u64) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.buckets\" VALUES (?, ?)"))
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
  fn metadata_store_simple() {
    let mut conn = Connection::open_in_memory().unwrap();
    let mut txn = conn.transaction().unwrap();
    let mut metadata = Metadata::new("name", &mut txn);
    let this = metadata.this();
    assert_eq!(metadata.name(), "name");
    assert_eq!(metadata.buckets().len(), 0);

    metadata.update(&mut txn, 1, 3u64);
    assert_eq!(metadata.buckets().get(&1).unwrap(), &3);
    metadata.update(&mut txn, 1, 2u64);
    assert_eq!(metadata.buckets().get(&1).unwrap(), &3);
    metadata.update(&mut txn, 1, 3u64);
    assert_eq!(metadata.buckets().get(&1).unwrap(), &3);
    metadata.update(&mut txn, 1, 4u64);
    assert_eq!(metadata.buckets().get(&1).unwrap(), &4);
    metadata.update(&mut txn, 2, 3u64);
    assert_eq!(metadata.buckets().get(&2).unwrap(), &3);
    metadata.update(&mut txn, 2, 2u64);
    assert_eq!(metadata.buckets().get(&2).unwrap(), &3);

    let mut metadata = Metadata::new("name", &mut txn);
    assert_eq!(metadata.name(), "name");
    assert_eq!(metadata.this(), this);
    assert_eq!(metadata.buckets(), &HashMap::from([(1, 4u64), (2, 3u64)]));

    metadata.update(&mut txn, 3, 3u64);
    assert_eq!(metadata.buckets(), &HashMap::from([(1, 4u64), (2, 3u64), (3, 3u64)]));

    let metadata = Metadata::new("another_name", &mut txn);
    assert_eq!(metadata.name(), "another_name");
    assert_ne!(metadata.this(), this);
    assert_eq!(metadata.buckets().len(), 0);
  }
}
