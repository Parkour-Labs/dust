use rand::Rng;
use rusqlite::Connection;
use std::{cell::RefCell, collections::HashMap};

use super::{
  vector_history::{VectorHistory, VectorHistoryStore},
  Serde,
};
use crate::joinable::{ByMax, Clock, State};

struct MockVectorHistoryStore {
  replicas: Vec<u128>,
  data: Vec<(u128, Clock, String, Vec<u8>)>,
}

impl VectorHistoryStore for RefCell<MockVectorHistoryStore> {
  fn init(&self, _name: &str) {}
  fn get_replicas(&self, _name: &str) -> Vec<u128> {
    self.borrow().replicas.clone()
  }
  fn put_replica(&self, _name: &str, replica: u128) {
    self.borrow_mut().replicas.push(replica);
  }
  fn get_by_replica_clock_range(
    &self,
    _name: &str,
    replica: u128,
    lower: Option<Clock>,
    upper: Clock,
  ) -> Vec<(Clock, String, Vec<u8>)> {
    let mut res: Vec<(Clock, String, Vec<u8>)> = self
      .borrow()
      .data
      .iter()
      .filter(|(r, c, _, _)| *r == replica && Some(*c) > lower && *c <= upper)
      .map(|(_, c, n, a)| (*c, n.clone(), a.clone()))
      .collect();
    res.sort_unstable_by_key(|(c, _, _)| *c);
    res
  }
  fn get_by_replica_clock_max(&self, _name: &str, replica: u128) -> Option<(Clock, String, Vec<u8>)> {
    self
      .borrow()
      .data
      .iter()
      .filter(|(r, _, _, _)| *r == replica)
      .max_by_key(|(_, c, _, _)| *c)
      .map(|(_, c, n, a)| (*c, n.clone(), a.clone()))
  }
  fn put_by_replica(&self, _name: &str, replica: u128, item: (Clock, String, Vec<u8>)) {
    self.borrow_mut().data.push((replica, item.0, item.1, item.2));
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
  let store = RefCell::new(MockVectorHistoryStore { replicas: Vec::new(), data: Vec::new() });
  let mut history = VectorHistory::new(&store, "");
  history.assert_invariants(&store);

  assert!(history.push(&store, 1, clock!(3), string!(""), vec![1]));
  assert!(!history.push(&store, 1, clock!(2), string!(""), vec![2]));
  assert!(!history.push(&store, 1, clock!(3), string!(""), vec![3]));
  assert!(history.push(&store, 1, clock!(4), string!(""), vec![4]));
  assert!(history.push(&store, 1, clock!(5), string!(""), vec![5]));
  assert!(history.push(&store, 1, clock!(6), string!(""), vec![6]));
  assert!(history.push(&store, 2, clock!(3), string!(""), vec![7]));
  assert!(!history.push(&store, 2, clock!(2), string!(""), vec![8]));
  history.assert_invariants(&store);

  assert_eq!(
    store.borrow().data,
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
  let store = RefCell::new(MockVectorHistoryStore {
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
  });
  let mut history = VectorHistory::new(&store, "");
  history.assert_invariants(&store);
  assert_eq!(history.latest(), Some(clock!(6)));

  assert!(!history.push(&store, 1, clock!(4), string!(""), vec![9]));
  assert!(!history.push(&store, 1, clock!(6), string!(""), vec![9]));
  assert!(!history.push(&store, 3, clock!(4), string!(""), vec![9]));
  assert!(history.push(&store, 3, clock!(6), string!(""), vec![9]));
  assert!(history.push(&store, 5, clock!(7), string!(""), vec![10]));
  assert_eq!(history.latest(), Some(clock!(7)));
  history.assert_invariants(&store);

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
  history.assert_invariants(&store);
  assert_eq!(history.latest(), Some(clock!(7)));

  assert_eq!(
    {
      let mut lhs = history.collect(&store, HashMap::from([(1, Some(clock!(3))), (2, Some(clock!(3)))]));
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
  history.assert_invariants(&store);

  assert_eq!(
    {
      let mut lhs = history.collect(&store, HashMap::from([(1, Some(clock!(2))), (2, Some(clock!(2)))]));
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
  history.assert_invariants(&store);
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

  fn push(&mut self, item: (u128, Clock, String, Vec<u8>)) -> bool {
    let (replica, clock, name, action) = item;
    let entry = self.data.entry(replica).or_insert_with(Vec::new);
    if entry.last().map(|(fst, _, _)| *fst) < Some(clock) {
      entry.push((clock, name, action));
      true
    } else {
      false
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

fn random_option_clock() -> Option<Clock> {
  let value = rand::thread_rng().gen_range(0..10);
  if value % 20 == 0 {
    None
  } else {
    Some(Clock::from_u128(value))
  }
}

fn vector_history_random_core<T: State, S: VectorHistoryStore>(
  mut rand_action: impl FnMut() -> T::Action,
  action_eq: impl Fn(T::Action, T::Action) -> bool,
  store: S,
) where
  T::Action: Clone + Serde,
{
  let mut history = VectorHistory::new(&store, "");
  let mut mock = MockVectorHistory::new();
  let mut rng = rand::thread_rng();

  for _ in 0..1000 {
    match rng.gen_range(0..=6) {
      0 => history = VectorHistory::new(&store, ""),
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
        history.load_until(&store, &begins);
        history.assert_invariants(&store);
      }
      4 => {
        let begins = mock.data.keys().map(|key| (*key, random_option_clock())).collect::<Vec<_>>();
        history.unload_until(&begins);
        history.assert_invariants(&store);
      }
      5 => {
        let replica = rng.gen_range(0..10);
        let clock = Clock::from_u128(rng.gen_range(0..10));
        let name = String::from("");
        let action = rand_action();
        assert_eq!(
          history.push(&store, replica, clock, name.clone(), postcard::to_allocvec(&action).unwrap()),
          mock.push((replica, clock, name, postcard::to_allocvec(&action).unwrap()))
        );
        history.assert_invariants(&store);
      }
      6 => {
        let clocks = mock.data.keys().map(|key| (*key, random_option_clock())).collect::<HashMap<_, _>>();
        let mut lhs = history.collect(&store, clocks.clone());
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
fn vector_history_with_sqlite_random() {
  type T = ByMax<u64>;
  let mut db = Connection::open_in_memory().unwrap();
  let txn = db.transaction().unwrap();
  vector_history_random_core::<T, _>(|| rand::thread_rng().gen(), |lhs, rhs| lhs == rhs, txn);
}
