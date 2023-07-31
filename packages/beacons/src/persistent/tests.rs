use rand::Rng;
use rusqlite::Connection;
use serde::{de::DeserializeOwned, ser::Serialize};
use std::collections::HashMap;

use super::vector_history::{VectorHistory, VectorHistoryStore};
use crate::joinable::{ByMax, Clock, State};

struct MockVectorHistoryStore {
  replicas: Vec<u128>,
  data: Vec<(u128, Clock, String, Vec<u8>)>,
}

impl VectorHistoryStore for MockVectorHistoryStore {
  fn init(&mut self, _name: &str) -> u128 {
    rand::thread_rng().gen()
  }

  fn get_replicas(&mut self, _name: &str) -> Vec<u128> {
    self.replicas.clone()
  }

  fn put_replica(&mut self, _name: &str, replica: u128) {
    self.replicas.push(replica);
  }

  fn get_by_replica_clock_range(
    &mut self,
    _name: &str,
    replica: u128,
    lower: Option<Clock>,
    upper: Clock,
  ) -> Vec<(Clock, String, Vec<u8>)> {
    let mut res: Vec<(Clock, String, Vec<u8>)> = self
      .data
      .iter()
      .filter(|(r, c, _, _)| *r == replica && Some(*c) > lower && *c <= upper)
      .map(|(_, c, n, a)| (*c, n.clone(), a.clone()))
      .collect();
    res.sort_unstable_by_key(|(c, _, _)| *c);
    res
  }

  fn get_by_replica_clock_max(&mut self, _name: &str, replica: u128) -> Option<(Clock, String, Vec<u8>)> {
    self
      .data
      .iter()
      .filter(|(r, _, _, _)| *r == replica)
      .max_by_key(|(_, c, _, _)| *c)
      .map(|(_, c, n, a)| (*c, n.clone(), a.clone()))
  }

  fn put_by_replica(&mut self, _name: &str, replica: u128, item: (Clock, &str, &[u8])) {
    self.data.push((replica, item.0, String::from(item.1), Vec::from(item.2)));
  }
}

struct MockVectorHistory {
  data: HashMap<u128, Vec<(Clock, String, Vec<u8>)>>,
}

impl MockVectorHistory {
  fn new() -> Self {
    Self { data: HashMap::new() }
  }

  fn clocks(&self) -> HashMap<u128, Option<Clock>> {
    self.data.iter().map(|(replica, entry)| (*replica, entry.last().map(|(fst, _, _)| *fst))).collect()
  }

  fn clock(&self) -> Option<Clock> {
    self.data.values().fold(None, |acc, entry| acc.max(entry.last().map(|(fst, _, _)| *fst)))
  }

  fn push(&mut self, item: (u128, Clock, String, Vec<u8>)) -> Option<(u128, Clock, String, Vec<u8>)> {
    let (replica, clock, name, action) = item.clone();
    let entry = self.data.entry(replica).or_insert_with(Vec::new);
    if entry.last().map(|(fst, _, _)| *fst) < Some(clock) {
      entry.push((clock, name, action));
      Some(item)
    } else {
      None
    }
  }

  fn actions(&mut self, mut clocks: HashMap<u128, Option<Clock>>) -> Vec<(u128, Clock, String, Vec<u8>)> {
    let mut res = Vec::new();
    for (replica, entry) in self.data.iter_mut() {
      let begin = clocks.remove(replica).unwrap_or(None);
      let start = entry.partition_point(|(fst, _, _)| Some(*fst) <= begin);
      for (clock, name, action) in entry[start..].iter().cloned() {
        res.push((*replica, clock, name, action));
      }
    }
    res
  }
}

macro_rules! clock {
  ( $val:expr ) => {
    Clock::from_u128($val)
  };
}

macro_rules! string {
  ( $val:expr ) => {
    String::from($val)
  };
}

#[test]
fn vector_history_push_simple() {
  let mut store = MockVectorHistoryStore { replicas: Vec::new(), data: Vec::new() };
  let mut history = VectorHistory::new(&mut store, "");
  history.assert_invariants(&mut store);

  assert!(history.push(&mut store, (1, clock!(3), string!(""), vec![1])).is_some());
  assert!(history.push(&mut store, (1, clock!(2), string!(""), vec![2])).is_none());
  assert!(history.push(&mut store, (1, clock!(3), string!(""), vec![3])).is_none());
  assert!(history.push(&mut store, (1, clock!(4), string!(""), vec![4])).is_some());
  assert!(history.push(&mut store, (1, clock!(5), string!(""), vec![5])).is_some());
  assert!(history.push(&mut store, (1, clock!(6), string!(""), vec![6])).is_some());
  assert!(history.push(&mut store, (2, clock!(3), string!(""), vec![7])).is_some());
  assert!(history.push(&mut store, (2, clock!(2), string!(""), vec![8])).is_none());
  history.assert_invariants(&mut store);

  assert_eq!(
    store.data,
    vec![
      (1, clock!(3), string!(""), vec![1]),
      (1, clock!(4), string!(""), vec![4]),
      (1, clock!(5), string!(""), vec![5]),
      (1, clock!(6), string!(""), vec![6]),
      (2, clock!(3), string!(""), vec![7])
    ]
  );
}

#[test]
fn vector_history_load_unload_collect_simple() {
  let mut store = MockVectorHistoryStore {
    replicas: vec![1, 2, 3, 4],
    data: vec![
      (1, clock!(3), string!(""), vec![1]),
      (1, clock!(4), string!(""), vec![2]),
      (1, clock!(5), string!(""), vec![3]),
      (1, clock!(6), string!(""), vec![4]),
      (2, clock!(3), string!(""), vec![5]),
      (2, clock!(5), string!(""), vec![6]),
      (2, clock!(6), string!(""), vec![7]),
      (3, clock!(5), string!(""), vec![8]),
    ],
  };
  let mut history = VectorHistory::new(&mut store, "");
  history.assert_invariants(&mut store);
  assert_eq!(history.latest(), Some(clock!(6)));

  assert!(history.push(&mut store, (1, clock!(4), string!(""), vec![9])).is_none());
  assert!(history.push(&mut store, (1, clock!(6), string!(""), vec![9])).is_none());
  assert!(history.push(&mut store, (3, clock!(4), string!(""), vec![9])).is_none());
  assert!(history.push(&mut store, (3, clock!(6), string!(""), vec![9])).is_some());
  assert!(history.push(&mut store, (5, clock!(7), string!(""), vec![10])).is_some());
  assert_eq!(history.latest(), Some(clock!(7)));
  history.assert_invariants(&mut store);

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
  history.assert_invariants(&mut store);
  assert_eq!(history.latest(), Some(clock!(7)));

  assert_eq!(
    {
      let mut lhs = history.collect(&mut store, HashMap::from([(1, Some(clock!(3))), (2, Some(clock!(3)))]));
      lhs.sort_by_key(|(replica, _, _, _)| *replica);
      lhs
    },
    vec![
      (1, clock!(4), string!(""), vec![2]),
      (1, clock!(5), string!(""), vec![3]),
      (1, clock!(6), string!(""), vec![4]),
      (2, clock!(5), string!(""), vec![6]),
      (2, clock!(6), string!(""), vec![7]),
      (3, clock!(5), string!(""), vec![8]),
      (3, clock!(6), string!(""), vec![9]),
      (5, clock!(7), string!(""), vec![10]),
    ]
  );
  assert_eq!(history.latest(), Some(clock!(7)));
  history.assert_invariants(&mut store);

  assert_eq!(
    {
      let mut lhs = history.collect(&mut store, HashMap::from([(1, Some(clock!(2))), (2, Some(clock!(2)))]));
      lhs.sort_by_key(|(replica, _, _, _)| *replica);
      lhs
    },
    vec![
      (1, clock!(3), string!(""), vec![1]),
      (1, clock!(4), string!(""), vec![2]),
      (1, clock!(5), string!(""), vec![3]),
      (1, clock!(6), string!(""), vec![4]),
      (2, clock!(3), string!(""), vec![5]),
      (2, clock!(5), string!(""), vec![6]),
      (2, clock!(6), string!(""), vec![7]),
      (3, clock!(5), string!(""), vec![8]),
      (3, clock!(6), string!(""), vec![9]),
      (5, clock!(7), string!(""), vec![10]),
    ]
  );
  assert_eq!(history.latest(), Some(clock!(7)));
  history.assert_invariants(&mut store);
}

fn random_option_clock() -> Option<Clock> {
  let value = rand::thread_rng().gen_range(0..10);
  if value % 20 == 0 {
    None
  } else {
    Some(Clock::from_u128(value))
  }
}

fn vector_history_random_core<T: State>(
  mut rand_action: impl FnMut() -> T::Action,
  mut action_eq: impl FnMut(T::Action, T::Action) -> bool,
  mut store: impl VectorHistoryStore,
) where
  T::Action: Clone + Serialize + DeserializeOwned,
{
  let mut history = VectorHistory::new(&mut store, "");
  let mut mock = MockVectorHistory::new();
  let mut rng = rand::thread_rng();

  for _ in 0..1000 {
    match rng.gen_range(0..=6) {
      0 => {
        let this = history.this();
        history = VectorHistory::new(&mut store, "");
        assert_ne!(history.this(), 0);
        assert_eq!(this, history.this());
      }
      1 => {
        let mut lhs = history.latests();
        let mut rhs = mock.clocks();
        lhs.retain(|_, v| v.is_some());
        rhs.retain(|_, v| v.is_some());
        assert_eq!(lhs, rhs);
      }
      2 => assert_eq!(history.latest(), mock.clock()),
      3 => {
        let begins = mock.data.keys().map(|key| (*key, random_option_clock())).collect::<Vec<_>>();
        history.load_until(&mut store, &begins);
        history.assert_invariants(&mut store);
      }
      4 => {
        let begins = mock.data.keys().map(|key| (*key, random_option_clock())).collect::<Vec<_>>();
        history.unload_until(&begins);
        history.assert_invariants(&mut store);
      }
      5 => {
        let replica = rng.gen_range(0..10);
        let clock = Clock::from_u128(rng.gen_range(0..10));
        let name = String::from("");
        let action = rand_action();
        assert_eq!(
          history.push(&mut store, (replica, clock, name.clone(), postcard::to_allocvec(&action).unwrap())).is_some(),
          mock.push((replica, clock, name, postcard::to_allocvec(&action).unwrap())).is_some()
        );
        history.assert_invariants(&mut store);
      }
      6 => {
        let clocks = mock.data.keys().map(|key| (*key, random_option_clock())).collect::<HashMap<_, _>>();
        let mut lhs = history.collect(&mut store, clocks.clone());
        let mut rhs = mock.actions(clocks.clone());
        lhs.sort_by_key(|(fst, snd, _, _)| (*fst, *snd));
        rhs.sort_by_key(|(fst, snd, _, _)| (*fst, *snd));
        assert_eq!(lhs.len(), rhs.len());
        for (lhs, rhs) in std::iter::zip(lhs.into_iter(), rhs.into_iter()) {
          assert_eq!(lhs.0, rhs.0);
          assert_eq!(lhs.1, rhs.1);
          assert_eq!(lhs.2, rhs.2);
          assert!(action_eq(postcard::from_bytes(&lhs.3).unwrap(), postcard::from_bytes(&rhs.3).unwrap()));
        }
      }
      _ => panic!(),
    }
  }
}

#[test]
fn vector_history_random() {
  type T = ByMax<u64>;
  let mut db = Connection::open_in_memory().unwrap();
  let txn = db.transaction().unwrap();
  vector_history_random_core::<T>(|| rand::thread_rng().gen(), |lhs, rhs| lhs == rhs, txn);
}
