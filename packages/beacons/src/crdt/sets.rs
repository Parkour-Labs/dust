//! Set-like CRDTs.

pub mod atom_set;
pub mod edge_set;
pub mod node_set;

pub use atom_set::{AtomSet, AtomSetEvents, AtomSetStore};
pub use edge_set::{EdgeSet, EdgeSetEvents, EdgeSetStore};
pub use node_set::{NodeSet, NodeSetEvents, NodeSetStore};

use serde::{Deserialize, Serialize};
use std::{
  collections::HashMap,
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
#[derive(Debug, Clone)]
pub struct Set<T: Ord + Clone> {
  version: Version<Clock>,
  inner: HashMap<u128, Option<(Clock, u64, Option<T>)>>,
}

/// Type alias for action: `(id, clock, bucket, value)`.
type Action<T> = (u128, Clock, u64, Option<T>);

/// A helper function.
#[allow(clippy::type_complexity)]
fn load<'a, T>(
  name: &'static str,
  inner: &'a mut HashMap<u128, Option<(Clock, u64, Option<T>)>>,
  store: &mut impl SetStore<T>,
  id: u128,
) -> &'a mut Option<(Clock, u64, Option<T>)> {
  inner.entry(id).or_insert_with(|| store.get_data(name, id).map(|(_, clock, bucket, value)| (clock, bucket, value)))
}

impl<T: Ord + Clone> Set<T> {
  /// Creates or loads data.
  pub fn new(name: &'static str, store: &mut impl SetStore<T>) -> Self {
    let version = Version::new(name, store);
    store.init_data(name);
    Self { version, inner: HashMap::new() }
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

  /// Loads element.
  pub fn load(&mut self, store: &mut impl SetStore<T>, id: u128) {
    load(self.name(), &mut self.inner, store, id);
  }

  /// Unloads element.
  pub fn unload(&mut self, id: u128) {
    self.inner.remove(&id);
  }

  /// Obtains reference to element.
  pub fn get(&mut self, store: &mut impl SetStore<T>, id: u128) -> &Option<(Clock, u64, Option<T>)> {
    load(self.name(), &mut self.inner, store, id)
  }

  /// Obtains reference to element value.
  pub fn value(&mut self, store: &mut impl SetStore<T>, id: u128) -> Option<&T> {
    match self.get(store, id) {
      Some((_, _, value)) => value.as_ref(),
      None => None,
    }
  }

  /// Modifies element.
  pub fn set(&mut self, store: &mut impl SetStore<T>, action: Action<T>) -> bool {
    let (id, clock, bucket, value) = action;
    let mut new = (clock, bucket, value);
    let name = self.name();
    let entry = load(name, &mut self.inner, store, id);
    let less = match entry {
      Some(inner) => inner < &mut new,
      None => true,
    };
    if less {
      self.version.update(store, bucket, clock);
      store.set_data(name, id, new.0, new.1, &new.2);
      *entry = Some(new);
    }
    less
  }

  /// Returns all actions strictly later than given clock values.
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl SetStore<T>, version: HashMap<u64, Clock>) -> Vec<Action<T>> {
    let mut res = Vec::new();
    for &bucket in self.buckets().keys() {
      let lower = version.get(&bucket).copied();
      for elem in store.query_data(self.name(), lower, bucket) {
        res.push(elem);
      }
    }
    res
  }
}

/// Database interface for [`Set`].
pub trait SetStore<T>: VersionStore<Clock> {
  fn init_data(&mut self, name: &str);
  fn get_data(&mut self, name: &str, id: u128) -> Option<Action<T>>;
  fn set_data(&mut self, name: &str, id: u128, clock: Clock, bucket: u64, value: &Option<T>);
  fn query_data(&mut self, name: &str, lower: Option<Clock>, bucket: u64) -> Vec<Action<T>>;
}
