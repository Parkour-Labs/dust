use std::collections::{HashMap, VecDeque};

use super::controller::ReplicaId;
use crate::joinable::{Clock, Minimum, State};

pub struct VectorHistory<T: State>
where
  T::Action: Clone,
{
  data: HashMap<ReplicaId, VecDeque<(Clock, T::Action)>>,
}

#[allow(clippy::type_complexity)]
impl<T: State> VectorHistory<T>
where
  T::Action: Clone,
{
  #[cfg(test)]
  pub fn assert_invariants(&self) {
    // Clock values must be monotone increasing.
    for value in self.data.values() {
      for ((fsta, _), (fstb, _)) in value.iter().zip(value.range(1..)) {
        assert!(fsta < fstb);
      }
    }
  }

  /// Returns the latest clock value.
  pub fn clock(&self) -> Clock {
    let mut res = Clock::minimum();
    for value in self.data.values() {
      if let Some((clock, _)) = value.back() {
        res = res.max(*clock)
      }
    }
    res
  }

  /// Pushes to history. Clock values must be monotone increasing (unchecked).
  pub fn push(&mut self, replica: ReplicaId, clock: Clock, action: T::Action) {
    self.data.entry(replica).or_default().push_back((clock, action));
  }

  /// Appends to history. Clock values must be monotone increasing (unchecked).
  pub fn append(&mut self, data: Vec<(ReplicaId, Vec<(Clock, T::Action)>)>) {
    for (key, value) in data {
      let curr = self.data.entry(key).or_default();
      for item in value {
        curr.push_back(item);
      }
    }
  }

  /// Returns all actions strictly later than a given time stamp.
  pub fn slice(&self, clock: Clock) -> Vec<(ReplicaId, Vec<(Clock, T::Action)>)> {
    let mut res = Vec::new();
    for (key, value) in &self.data {
      let start = value.partition_point(|(fst, _)| *fst <= clock);
      let curr = Vec::from_iter(value.range(start..).cloned());
      if !curr.is_empty() {
        res.push((*key, curr));
      }
    }
    res
  }
}
