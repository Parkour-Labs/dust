use rand::Rng;
use rusqlite::{
  types::{FromSql, ToSql},
  OptionalExtension, Transaction,
};
use std::collections::HashMap;

/// [`VersionClock`] must be serialised in a way that preserves total order.
pub trait VersionClock: Clone + Ord {
  type SqlType: FromSql + ToSql;

  fn serialize(&self) -> Self::SqlType;
  fn deserialize(data: Self::SqlType) -> Self;
}

/// Stores the metadata for Γ-joinable structures.
#[derive(Debug, Clone)]
pub struct Version<T: VersionClock> {
  name: &'static str,
  this: u64,
  buckets: HashMap<u64, T>,
}

impl<T: VersionClock> Version<T> {
  /// Creates or loads metadata.
  pub fn new(name: &'static str, store: &mut impl VersionStore<T>) -> Self {
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
  pub fn buckets(&self) -> &HashMap<u64, T> {
    &self.buckets
  }

  /// Updates clock for one bucket.
  pub fn update(&mut self, store: &mut impl VersionStore<T>, bucket: u64, clock: T) {
    if self.buckets.get(&bucket) < Some(&clock) {
      store.set_bucket(self.name, bucket, &clock);
      self.buckets.insert(bucket, clock);
    }
  }
}

/// Database interface for [`Version`].
pub trait VersionStore<T: VersionClock> {
  fn init_this(&mut self, name: &str);
  fn get_this(&mut self, name: &str) -> Option<u64>;
  fn put_this(&mut self, name: &str, this: u64);

  fn init_buckets(&mut self, name: &str);
  fn get_buckets(&mut self, name: &str) -> HashMap<u64, T>;
  fn set_bucket(&mut self, name: &str, bucket: u64, clock: &T);
}

impl<'a, T: VersionClock> VersionStore<T> for Transaction<'a> {
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

  fn get_buckets(&mut self, name: &str) -> HashMap<u64, T> {
    self
      .prepare_cached(&format!("SELECT bucket, clock FROM \"{name}.buckets\""))
      .unwrap()
      .query_map((), |row| {
        let bucket = row.get(0).unwrap();
        let clock = row.get(1).unwrap();
        Ok((u64::from_be_bytes(bucket), T::deserialize(clock)))
      })
      .unwrap()
      .map(Result::unwrap)
      .collect()
  }

  fn set_bucket(&mut self, name: &str, bucket: u64, clock: &T) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.buckets\" VALUES (?, ?)"))
      .unwrap()
      .execute((bucket.to_be_bytes(), clock.serialize()))
      .unwrap();
  }
}
