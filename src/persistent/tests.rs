use std::collections::HashMap;

use super::{
  vector_history::{VectorHistory, VectorHistoryStore},
  Item,
};
use crate::joinable::{ByMax, Clock, Id, State};

pub struct MockVectorHistoryStore<T: State> {
  replicas: Vec<u64>,
  data: Vec<Item<T>>,
}

impl<T: State> VectorHistoryStore<T> for MockVectorHistoryStore<T>
where
  T::Action: Clone,
{
  fn get_replicas(&self) -> Vec<u64> {
    self.replicas.clone()
  }
  fn put_replica(&mut self, replica: u64) {
    self.replicas.push(replica);
  }
  fn get_by_replica_clock_range(&self, replica: u64, lower: Option<Clock>, upper: Clock) -> Vec<(Clock, T::Action)> {
    let mut res: Vec<(Clock, T::Action)> = self
      .data
      .iter()
      .filter(|(r, c, _)| *r == replica && Some(*c) > lower && *c <= upper)
      .map(|(_, c, a)| (*c, a.clone()))
      .collect();
    res.sort_unstable_by_key(|(c, _)| *c);
    res
  }
  fn get_by_replica_clock_max(&self, replica: u64) -> Option<(Clock, T::Action)> {
    self.data.iter().filter(|(r, _, _)| *r == replica).max_by_key(|(_, c, _)| *c).map(|(_, c, a)| (*c, a.clone()))
  }
  fn put_by_replica(&mut self, replica: u64, item: (Clock, T::Action)) {
    self.data.push((replica, item.0, item.1));
  }
}

macro_rules! clock {
  ( $val:expr ) => {
    Clock::from(Id::from($val))
  };
}

#[test]
fn vector_history_push_simple() {
  type T = ByMax<u64>;
  let store = MockVectorHistoryStore::<T> { replicas: Vec::new(), data: Vec::new() };
  let mut history = VectorHistory::new(store);
  history.assert_invariants();

  assert!(history.push((1, clock!(3), 1)));
  assert!(!history.push((1, clock!(2), 2)));
  assert!(!history.push((1, clock!(3), 3)));
  assert!(history.push((1, clock!(4), 4)));
  assert!(history.push((1, clock!(5), 5)));
  assert!(history.push((1, clock!(6), 6)));
  assert!(history.push((2, clock!(3), 7)));
  assert!(!history.push((2, clock!(2), 8)));
  history.assert_invariants();

  assert_eq!(
    history.store().data,
    vec![(1, clock!(3), 1), (1, clock!(4), 4), (1, clock!(5), 5), (1, clock!(6), 6), (2, clock!(3), 7)]
  );
}

#[test]
fn vector_history_load_unload_collect_simple() {
  type T = ByMax<u64>;
  let store = MockVectorHistoryStore::<T> {
    replicas: vec![1, 2, 3, 4],
    data: vec![
      (1, clock!(3), 1),
      (1, clock!(4), 2),
      (1, clock!(5), 3),
      (1, clock!(6), 4),
      (2, clock!(3), 5),
      (2, clock!(5), 6),
      (2, clock!(6), 7),
      (3, clock!(5), 8),
    ],
  };
  let mut history = VectorHistory::new(store);
  history.assert_invariants();
  assert_eq!(history.latest(), Some(clock!(6)));

  assert!(!history.push((1, clock!(4), 9)));
  assert!(!history.push((1, clock!(6), 9)));
  assert!(!history.push((3, clock!(4), 9)));
  assert!(history.push((3, clock!(6), 9)));
  assert!(history.push((5, clock!(7), 10)));
  assert_eq!(history.latest(), Some(clock!(7)));
  history.assert_invariants();

  history.unload_until(
    vec![
      (0, Some(clock!(7))),
      (1, Some(clock!(7))),
      (2, Some(clock!(7))),
      (3, Some(clock!(7))),
      (4, Some(clock!(7))),
      (5, Some(clock!(7))),
    ]
    .as_slice(),
  );
  history.assert_invariants();
  assert_eq!(history.latest(), Some(clock!(7)));

  assert_eq!(
    {
      let mut lhs = history.collect(&HashMap::from([(1, Some(clock!(3))), (2, Some(clock!(3)))]));
      lhs.sort_by_key(|(replica, _, _)| *replica);
      lhs
    },
    vec![
      (1, clock!(4), 2),
      (1, clock!(5), 3),
      (1, clock!(6), 4),
      (2, clock!(5), 6),
      (2, clock!(6), 7),
      (3, clock!(5), 8),
      (3, clock!(6), 9),
      (5, clock!(7), 10),
    ]
  );
  assert_eq!(history.latest(), Some(clock!(7)));
  history.assert_invariants();

  assert_eq!(
    {
      let mut lhs = history.collect(&HashMap::from([(1, Some(clock!(2))), (2, Some(clock!(2)))]));
      lhs.sort_by_key(|(replica, _, _)| *replica);
      lhs
    },
    vec![
      (1, clock!(3), 1),
      (1, clock!(4), 2),
      (1, clock!(5), 3),
      (1, clock!(6), 4),
      (2, clock!(3), 5),
      (2, clock!(5), 6),
      (2, clock!(6), 7),
      (3, clock!(5), 8),
      (3, clock!(6), 9),
      (5, clock!(7), 10),
    ]
  );
  assert_eq!(history.latest(), Some(clock!(7)));
  history.assert_invariants();
}
