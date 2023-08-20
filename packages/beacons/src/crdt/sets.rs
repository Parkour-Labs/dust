//! Set-like CRDTs.

pub mod atom_set;
pub mod edge_set;
pub mod node_set;

pub use atom_set::{AtomSet, AtomSetEvents, AtomSetStore};
pub use edge_set::{EdgeSet, EdgeSetEvents, EdgeSetStore};
pub use node_set::{NodeSet, NodeSetEvents, NodeSetStore};

use serde::{Deserialize, Serialize};
use std::{
  borrow::Borrow,
  collections::HashMap,
  marker::PhantomData,
  time::{SystemTime, UNIX_EPOCH},
};

use super::metadata::{Version, VersionClock, VersionStore};

/// Implementation of the [hybrid logical clock](https://muratbuffalo.blogspot.com/2014/07/hybrid-logical-clocks.html).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct Clock {
  measured: u64,
  count: u64,
}

impl Clock {
  /// Constructs an HLC from current system time and an optional predecessor.
  pub fn new(pred: Option<Clock>) -> Self {
    let measured = match SystemTime::now().duration_since(UNIX_EPOCH) {
      Ok(n) => n.as_secs(),
      Err(_) => 0,
    };
    let mut pair = (measured, 0);
    if let Some(pred) = pred {
      let pred = if pred.count == u64::MAX { (pred.measured + 1, 0) } else { (pred.measured, pred.count + 1) };
      pair = pair.max(pred);
    }
    Self { measured: pair.0, count: pair.1 }
  }

  pub fn from_be_bytes(value: [u8; 16]) -> Self {
    Self::from(u128::from_be_bytes(value))
  }

  pub fn to_be_bytes(&self) -> [u8; 16] {
    u128::from(*self).to_be_bytes()
  }
}

impl From<u128> for Clock {
  fn from(value: u128) -> Self {
    let measured = (value >> 64) as u64;
    let count = value as u64;
    Self { measured, count }
  }
}

impl From<Clock> for u128 {
  fn from(value: Clock) -> Self {
    ((value.measured as u128) << 64) ^ (value.count as u128)
  }
}

impl VersionClock for Clock {
  type SqlType = [u8; 16];

  fn serialize(&self) -> Self::SqlType {
    self.to_be_bytes()
  }

  fn deserialize(data: Self::SqlType) -> Self {
    Clock::from_be_bytes(data)
  }
}

/// A base class for last-writer-win element sets.
#[derive(Debug)]
pub struct Set<T: Ord + Borrow<R>, R: Ord + ?Sized> {
  version: Version<Clock>,
  _t: PhantomData<T>,
  _r: PhantomData<R>,
}

/// Type alias for item: `(bucket, clock, value)`.
type Item<T> = (u64, Clock, Option<T>);

impl<T: Ord + Borrow<R>, R: Ord + ?Sized> Set<T, R> {
  /// Creates or loads data.
  pub fn new(name: &'static str, store: &mut impl SetStore<T, R>) -> Self {
    let version = Version::new(name, store);
    store.init_data(name);
    Self { version, _t: PhantomData, _r: PhantomData }
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
  pub fn buckets(&self) -> &HashMap<u64, Clock> {
    self.version.buckets()
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> Clock {
    Clock::new(self.version.buckets().values().fold(None, |acc, &clock| acc.max(Some(clock))))
  }

  /// Obtains element.
  pub fn get(&mut self, store: &mut impl SetStore<T, R>, id: u128) -> Option<Item<T>> {
    store.get_data(self.name(), id)
  }

  /// Obtains element value.
  pub fn value(&mut self, store: &mut impl SetStore<T, R>, id: u128) -> Option<T> {
    self.get(store, id).and_then(|(_, _, value)| value)
  }

  /// Modifies element.
  pub fn set(
    &mut self,
    store: &mut impl SetStore<T, R>,
    id: u128,
    bucket: u64,
    clock: Clock,
    value: Option<&R>,
  ) -> bool {
    let name = self.name();
    let item = self.get(store, id);
    let item = item.as_ref().map(|(bucket, clock, value)| (*clock, *bucket, value.as_ref().map(Borrow::borrow)));
    if item < Some((clock, bucket, value)) {
      self.version.update(store, bucket, clock);
      store.set_data(name, id, bucket, clock, value);
      true
    } else {
      false
    }
  }

  /// Returns all actions strictly later than given clock values.
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl SetStore<T, R>, version: HashMap<u64, Clock>) -> Vec<(u128, Item<T>)> {
    let mut res = Vec::new();
    for &bucket in self.buckets().keys() {
      let lower = version.get(&bucket).copied();
      for elem in store.query_data(self.name(), bucket, lower) {
        res.push(elem);
      }
    }
    res
  }
}

/// Database interface for [`Set`].
pub trait SetStore<T: Ord + Borrow<R>, R: Ord + ?Sized>: VersionStore<Clock> {
  fn init_data(&mut self, name: &str);
  fn get_data(&mut self, name: &str, id: u128) -> Option<Item<T>>;
  fn set_data(&mut self, name: &str, id: u128, bucket: u64, clock: Clock, value: Option<&R>);
  fn query_data(&mut self, name: &str, bucket: u64, lower: Option<Clock>) -> Vec<(u128, Item<T>)>; // Exclusive.
}
