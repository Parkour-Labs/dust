use std::collections::{HashMap, VecDeque};

use super::Item;
use crate::joinable::{Clock, State};

#[cfg(test)]
use crate::joinable::Maximum;

/// A [`VectorHistory`] stores an action history for each replica.
pub struct VectorHistory<T: State, S: VectorHistoryStore<T>> {
  data: HashMap<u64, ReplicaHistory<T>>,
  store: S,
}

/// Action history and metadata for one replica.
struct ReplicaHistory<T: State> {
  actions: VecDeque<(Clock, T::Action)>,
  begin: Option<Clock>,
  latest: Option<Clock>,
}

impl<T: State, S: VectorHistoryStore<T>> VectorHistory<T, S>
where
  T::Action: Clone,
{
  #[cfg(test)]
  pub fn assert_invariants(&self) {
    // All replica metadata must be loaded.
    assert_eq!(self.store.get_replicas().len(), self.data.len());
    // Per-replica invariants:
    for (replica, entry) in self.data.iter() {
      // `begin` must be less than or equal to `latest`.
      assert!(entry.begin <= entry.latest);
      // The last element in store must agree with `latest`.
      assert_eq!(self.store.get_by_replica_clock_max(*replica).map(|(clock, _)| clock), entry.latest);
      // All actions with clock value strictly greater than `begin` must be loaded.
      assert_eq!(
        self.store.get_by_replica_clock_range(*replica, entry.begin, Clock::maximum()).len(),
        entry.actions.len()
      );
      // Clock values must be strictly monotone increasing.
      if !entry.actions.is_empty() {
        for ((fsta, _), (fstb, _)) in entry.actions.iter().zip(entry.actions.range(1..)) {
          assert!(fsta < fstb);
        }
      }
    }
  }

  /// Creates a vector history with a backing store.
  pub fn new(store: S) -> Self {
    let mut data = HashMap::new();
    for replica in store.get_replicas() {
      let latest = store.get_by_replica_clock_max(replica).map(|(clock, _)| clock);
      let entry = ReplicaHistory { actions: VecDeque::new(), begin: latest, latest };
      data.insert(replica, entry);
    }
    Self { data, store }
  }

  /// Returns the latest clock values for each replica.
  pub fn latests(&self) -> HashMap<u64, Option<Clock>> {
    self.data.iter().map(|(replica, entry)| (*replica, entry.latest)).collect()
  }

  /// Returns the latest clock value across all replicas.
  pub fn latest(&self) -> Option<Clock> {
    self.data.values().fold(None, |acc, entry| acc.max(entry.latest))
  }

  /// Returns a reference to the backing store.
  pub fn store(&self) -> &S {
    &self.store
  }

  /// Moves `begin` backwards.
  /// Absent entries from `begins` are ignored (equiv. assumed to be [`Some(Maximum::maximum())`]).
  pub fn load_until(&mut self, begins: &[(u64, Option<Clock>)]) {
    for (replica, begin) in begins.iter().copied() {
      if let Some(entry) = self.data.get_mut(&replica) {
        if begin < entry.begin {
          let items = self.store.get_by_replica_clock_range(replica, begin, entry.begin.unwrap()); // No panic.
          for (clock, action) in items.into_iter().rev() {
            entry.actions.push_front((clock, action));
          }
          entry.begin = begin;
        }
      }
    }
  }

  /// Moves `begin` forwards.
  /// Absent entries from `begins` are ignored (equiv. assumed to be [`None`]).
  pub fn unload_until(&mut self, begins: &[(u64, Option<Clock>)]) {
    for (replica, begin) in begins.iter().copied() {
      if let Some(entry) = self.data.get_mut(&replica) {
        let begin = begin.min(entry.latest);
        if begin > entry.begin {
          let start = entry.actions.partition_point(|(fst, _)| Some(*fst) <= begin);
          entry.actions.drain(..start);
          entry.begin = begin;
        }
      }
    }
  }

  /// Pushes to history. Clock values must be strictly monotone increasing. Invalid entries are ignored.
  pub fn push(&mut self, item: Item<T>) -> bool {
    let (replica, clock, action) = item;
    let entry = self.data.entry(replica).or_insert_with(|| {
      self.store.put_replica(replica);
      ReplicaHistory { actions: VecDeque::new(), begin: None, latest: None }
    });
    if entry.latest < Some(clock) {
      entry.latest = Some(clock);
      entry.actions.push_back((clock, action.clone()));
      self.store.put_by_replica(replica, (clock, action));
      true
    } else {
      false
    }
  }

  /// Appends to history. Clock values must be strictly monotone increasing. Invalid entries are ignored.
  pub fn append(&mut self, items: Vec<Item<T>>) -> Vec<Item<T>> {
    let mut res = Vec::new();
    for item in items {
      if self.push(item.clone()) {
        res.push(item);
      }
    }
    res
  }

  /// Returns all actions strictly later than given time stamps.
  /// Absent entries from `clocks` are assumed to be [`None`].
  pub fn collect(&mut self, clocks: &HashMap<u64, Option<Clock>>) -> Vec<Item<T>> {
    let mut res = Vec::new();
    let mut begins = Vec::new();
    for replica in self.data.keys() {
      begins.push((*replica, clocks.get(replica).copied().unwrap_or(None)));
    }
    self.load_until(begins.as_slice());
    for (replica, begin) in begins {
      let entry = self.data.get_mut(&replica).unwrap(); // No panic.
      let start = entry.actions.partition_point(|(fst, _)| Some(*fst) <= begin);
      for (clock, action) in entry.actions.range(start..).cloned() {
        res.push((replica, clock, action));
      }
    }
    res
  }
}

/// Database interface for [`VectorHistory`].
pub trait VectorHistoryStore<T: State> {
  fn get_replicas(&self) -> Vec<u64>;
  fn put_replica(&mut self, replica: u64);
  /// Left open, right closed, sorted by clock in ascending order.
  fn get_by_replica_clock_range(&self, replica: u64, lower: Option<Clock>, upper: Clock) -> Vec<(Clock, T::Action)>;
  fn get_by_replica_clock_max(&self, replica: u64) -> Option<(Clock, T::Action)>;
  fn put_by_replica(&mut self, replica: u64, item: (Clock, T::Action));
}
