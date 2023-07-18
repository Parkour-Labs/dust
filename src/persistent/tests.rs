use rand::Rng;
use rusqlite::Connection;
use std::{cell::RefCell, collections::HashMap};

use super::{
  vector_history::{SqliteVectorHistoryStore, VectorHistory, VectorHistoryStore},
  Item,
};
use crate::{
  joinable::{ByMax, Clock, State},
  persistent::{
    database::{sqlite::SqliteDatabase, Database},
    vector_history::DatabaseVectorHistoryStore,
  },
};

struct MockVectorHistoryStore<T: State> {
  replicas: Vec<u64>,
  data: Vec<Item<T>>,
}

impl<T: State> VectorHistoryStore<T> for RefCell<MockVectorHistoryStore<T>>
where
  T::Action: Clone,
{
  fn init(&self) {}
  fn get_replicas(&self) -> Vec<u64> {
    self.borrow().replicas.clone()
  }
  fn put_replica(&self, replica: u64) {
    self.borrow_mut().replicas.push(replica);
  }
  fn get_by_replica_clock_range(&self, replica: u64, lower: Option<Clock>, upper: Clock) -> Vec<(Clock, T::Action)> {
    let mut res: Vec<(Clock, T::Action)> = self
      .borrow()
      .data
      .iter()
      .filter(|(r, c, _)| *r == replica && Some(*c) > lower && *c <= upper)
      .map(|(_, c, a)| (*c, a.clone()))
      .collect();
    res.sort_unstable_by_key(|(c, _)| *c);
    res
  }
  fn get_by_replica_clock_max(&self, replica: u64) -> Option<(Clock, T::Action)> {
    self
      .borrow()
      .data
      .iter()
      .filter(|(r, _, _)| *r == replica)
      .max_by_key(|(_, c, _)| *c)
      .map(|(_, c, a)| (*c, a.clone()))
  }
  fn put_by_replica(&self, replica: u64, item: (Clock, T::Action)) {
    self.borrow_mut().data.push((replica, item.0, item.1));
  }
}

macro_rules! clock {
  ( $val:expr ) => {
    Clock::from_u128($val)
  };
}

#[test]
fn vector_history_push_simple() {
  type T = ByMax<u64>;
  let store = RefCell::new(MockVectorHistoryStore::<T> { replicas: Vec::new(), data: Vec::new() });
  let mut history = VectorHistory::new(&store);
  history.assert_invariants(&store);

  assert!(history.push(&store, (1, clock!(3), 1)));
  assert!(!history.push(&store, (1, clock!(2), 2)));
  assert!(!history.push(&store, (1, clock!(3), 3)));
  assert!(history.push(&store, (1, clock!(4), 4)));
  assert!(history.push(&store, (1, clock!(5), 5)));
  assert!(history.push(&store, (1, clock!(6), 6)));
  assert!(history.push(&store, (2, clock!(3), 7)));
  assert!(!history.push(&store, (2, clock!(2), 8)));
  history.assert_invariants(&store);

  assert_eq!(
    store.borrow().data,
    vec![(1, clock!(3), 1), (1, clock!(4), 4), (1, clock!(5), 5), (1, clock!(6), 6), (2, clock!(3), 7)]
  );
}

#[test]
fn vector_history_load_unload_collect_simple() {
  type T = ByMax<u64>;
  let store = RefCell::new(MockVectorHistoryStore::<T> {
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
  });
  let mut history = VectorHistory::new(&store);
  history.assert_invariants(&store);
  assert_eq!(history.latest(), Some(clock!(6)));

  assert!(!history.push(&store, (1, clock!(4), 9)));
  assert!(!history.push(&store, (1, clock!(6), 9)));
  assert!(!history.push(&store, (3, clock!(4), 9)));
  assert!(history.push(&store, (3, clock!(6), 9)));
  assert!(history.push(&store, (5, clock!(7), 10)));
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
      let mut lhs = history.collect(&store, &HashMap::from([(1, Some(clock!(3))), (2, Some(clock!(3)))]));
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
  history.assert_invariants(&store);

  assert_eq!(
    {
      let mut lhs = history.collect(&store, &HashMap::from([(1, Some(clock!(2))), (2, Some(clock!(2)))]));
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
  history.assert_invariants(&store);
}

struct MockVectorHistory<T: State> {
  data: HashMap<u64, Vec<(Clock, T::Action)>>,
}

impl<T: State> MockVectorHistory<T>
where
  T::Action: Clone,
{
  fn new() -> Self {
    Self { data: HashMap::new() }
  }

  fn latests(&self) -> HashMap<u64, Option<Clock>> {
    self.data.iter().map(|(replica, entry)| (*replica, entry.last().map(|(fst, _)| *fst))).collect()
  }

  fn latest(&self) -> Option<Clock> {
    self.data.values().fold(None, |acc, entry| acc.max(entry.last().map(|(fst, _)| *fst)))
  }

  fn push(&mut self, item: Item<T>) -> bool {
    let (replica, clock, action) = item;
    let entry = self.data.entry(replica).or_insert_with(Vec::new);
    if entry.last().map(|(fst, _)| *fst) < Some(clock) {
      entry.push((clock, action));
      true
    } else {
      false
    }
  }

  fn collect(&mut self, clocks: &HashMap<u64, Option<Clock>>) -> Vec<Item<T>> {
    let mut res = Vec::new();
    for (replica, entry) in self.data.iter_mut() {
      let begin = clocks.get(replica).copied().unwrap_or(None);
      let start = entry.partition_point(|(fst, _)| Some(*fst) <= begin);
      for (clock, action) in entry[start..].iter().cloned() {
        res.push((*replica, clock, action));
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

fn vector_history_random_core<T: State, S: VectorHistoryStore<T>>(
  mut rand_action: impl FnMut() -> T::Action,
  action_eq: impl Fn(T::Action, T::Action) -> bool,
  store: S,
) where
  T::Action: Clone,
{
  let mut history = VectorHistory::new(&store);
  let mut mock = MockVectorHistory::<T>::new();
  let mut rng = rand::thread_rng();

  for _ in 0..1000 {
    match rng.gen_range(0..=6) {
      0 => history = VectorHistory::new(&store),
      1 => {
        let mut lhs = history.latests();
        let mut rhs = mock.latests();
        lhs.retain(|_, v| v.is_some());
        rhs.retain(|_, v| v.is_some());
        assert_eq!(lhs, rhs);
      }
      2 => assert_eq!(history.latest(), mock.latest()),
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
        let action = rand_action();
        assert_eq!(history.push(&store, (replica, clock, action.clone())), mock.push((replica, clock, action)));
        history.assert_invariants(&store);
      }
      6 => {
        let clocks = mock.data.keys().map(|key| (*key, random_option_clock())).collect::<HashMap<_, _>>();
        let mut lhs = history.collect(&store, &clocks);
        let mut rhs = mock.collect(&clocks);
        lhs.sort_by_key(|(fst, snd, _)| (*fst, *snd));
        rhs.sort_by_key(|(fst, snd, _)| (*fst, *snd));
        assert_eq!(lhs.len(), rhs.len());
        for (lhs, rhs) in std::iter::zip(lhs.into_iter(), rhs.into_iter()) {
          assert_eq!(lhs.0, rhs.0);
          assert_eq!(lhs.1, rhs.1);
          assert!(action_eq(lhs.2, rhs.2));
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
  let store = SqliteVectorHistoryStore::<T>::new(0, &txn);
  vector_history_random_core(|| rand::thread_rng().gen(), |lhs, rhs| lhs == rhs, store);
}

#[test]
fn vector_history_with_database_random() {
  type T = ByMax<u64>;
  let mut db = SqliteDatabase::open_in_memory();
  let replica_table = DatabaseVectorHistoryStore::<T, _>::replica_table(&db);
  let replica_history_table = DatabaseVectorHistoryStore::<T, _>::replica_history_table(&db);
  let txn = db.transaction();
  let store = DatabaseVectorHistoryStore::<T, SqliteDatabase>::new(0, &txn, &replica_table, &replica_history_table);
  vector_history_random_core(|| rand::thread_rng().gen(), |lhs, rhs| lhs == rhs, store);
}
