use rand::Rng;
use rusqlite::Connection;
use serde::{de::DeserializeOwned, ser::Serialize};
use std::collections::HashMap;

use super::vector_history::{VectorHistory, VectorHistoryStore};
use crate::joinable::{ByMax, State};
use crate::{deserialize, serialize};

struct MockVectorHistoryStore {
  replicas: Vec<u64>,
  data: Vec<(u64, u64, String, Vec<u8>)>,
}

impl VectorHistoryStore for MockVectorHistoryStore {
  fn init(&mut self, _name: &str) -> u64 {
    rand::thread_rng().gen()
  }

  fn get_replicas(&mut self, _name: &str) -> Vec<u64> {
    self.replicas.clone()
  }

  fn put_replica(&mut self, _name: &str, replica: u64) {
    self.replicas.push(replica);
  }

  fn get_action_latest(&mut self, _name: &str, replica: u64) -> Option<(u64, String, Vec<u8>)> {
    self
      .data
      .iter()
      .filter(|(r, _, _, _)| *r == replica)
      .max_by_key(|(_, c, _, _)| *c)
      .map(|(_, c, n, a)| (*c, n.clone(), a.clone()))
  }

  fn get_actions(&mut self, _name: &str, replica: u64, lower: u64, upper: u64) -> Vec<(u64, String, Vec<u8>)> {
    let mut res: Vec<(u64, String, Vec<u8>)> = self
      .data
      .iter()
      .filter(|(r, c, _, _)| *r == replica && *c > lower && *c <= upper)
      .map(|(_, c, n, a)| (*c, n.clone(), a.clone()))
      .collect();
    res.sort_unstable_by_key(|(c, _, _)| *c);
    res
  }

  fn put_action(&mut self, _name: &str, replica: u64, item: (u64, &str, &[u8])) {
    self.data.push((replica, item.0, String::from(item.1), Vec::from(item.2)));
  }
}

struct MockVectorHistory {
  data: HashMap<u64, Vec<(u64, String, Vec<u8>)>>,
}

impl MockVectorHistory {
  fn new() -> Self {
    Self { data: HashMap::new() }
  }

  fn nexts(&self) -> HashMap<u64, u64> {
    self.data.iter().map(|(replica, entry)| (*replica, entry.last().map(|(fst, _, _)| *fst).unwrap_or(0))).collect()
  }

  fn push(&mut self, item: (u64, u64, String, Vec<u8>)) -> Option<(u64, u64, String, Vec<u8>)> {
    let (replica, serial, name, action) = item.clone();
    let entry = self.data.entry(replica).or_insert_with(Vec::new);
    if entry.last().map(|(fst, _, _)| *fst).unwrap_or(0) < serial {
      entry.push((serial, name, action));
      Some(item)
    } else {
      None
    }
  }

  fn actions(&mut self, mut clocks: HashMap<u64, u64>) -> Vec<(u64, u64, String, Vec<u8>)> {
    let mut res = Vec::new();
    for (replica, entry) in self.data.iter_mut() {
      let begin = clocks.remove(replica).unwrap_or(0);
      let start = entry.partition_point(|(fst, _, _)| *fst <= begin);
      for (clock, name, action) in entry[start..].iter().cloned() {
        res.push((*replica, clock, name, action));
      }
    }
    res
  }
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

  assert!(history.push(&mut store, (1, 3, string!(""), vec![1])).is_some());
  assert!(history.push(&mut store, (1, 2, string!(""), vec![2])).is_none());
  assert!(history.push(&mut store, (1, 3, string!(""), vec![3])).is_none());
  assert!(history.push(&mut store, (1, 4, string!(""), vec![4])).is_some());
  assert!(history.push(&mut store, (1, 5, string!(""), vec![5])).is_some());
  assert!(history.push(&mut store, (1, 6, string!(""), vec![6])).is_some());
  assert!(history.push(&mut store, (2, 3, string!(""), vec![7])).is_some());
  assert!(history.push(&mut store, (2, 2, string!(""), vec![8])).is_none());
  history.assert_invariants(&mut store);

  assert_eq!(
    store.data,
    vec![
      (1, 3, string!(""), vec![1]),
      (1, 4, string!(""), vec![4]),
      (1, 5, string!(""), vec![5]),
      (1, 6, string!(""), vec![6]),
      (2, 3, string!(""), vec![7])
    ]
  );
}

#[test]
fn vector_history_load_unload_collect_simple() {
  let mut store = MockVectorHistoryStore {
    replicas: vec![1, 2, 3, 4],
    data: vec![
      (1, 3, string!(""), vec![1]),
      (1, 4, string!(""), vec![2]),
      (1, 5, string!(""), vec![3]),
      (1, 6, string!(""), vec![4]),
      (2, 3, string!(""), vec![5]),
      (2, 5, string!(""), vec![6]),
      (2, 6, string!(""), vec![7]),
      (3, 5, string!(""), vec![8]),
    ],
  };
  let mut history = VectorHistory::new(&mut store, "");
  history.assert_invariants(&mut store);

  assert!(history.push(&mut store, (1, 4, string!(""), vec![9])).is_none());
  assert!(history.push(&mut store, (1, 6, string!(""), vec![9])).is_none());
  assert!(history.push(&mut store, (3, 4, string!(""), vec![9])).is_none());
  assert!(history.push(&mut store, (3, 6, string!(""), vec![9])).is_some());
  assert!(history.push(&mut store, (5, 7, string!(""), vec![10])).is_some());
  history.assert_invariants(&mut store);

  history.unload_until(vec![(0, 7), (1, 7), (2, 7), (3, 7), (4, 7), (5, 7)].as_slice());
  history.assert_invariants(&mut store);

  assert_eq!(
    {
      let mut lhs = history.collect(&mut store, HashMap::from([(1, 3), (2, 3)]));
      lhs.sort_by_key(|(replica, _, _, _)| *replica);
      lhs
    },
    vec![
      (1, 4, string!(""), vec![2]),
      (1, 5, string!(""), vec![3]),
      (1, 6, string!(""), vec![4]),
      (2, 5, string!(""), vec![6]),
      (2, 6, string!(""), vec![7]),
      (3, 5, string!(""), vec![8]),
      (3, 6, string!(""), vec![9]),
      (5, 7, string!(""), vec![10]),
    ]
  );
  history.assert_invariants(&mut store);

  assert_eq!(
    {
      let mut lhs = history.collect(&mut store, HashMap::from([(1, 2), (2, 2)]));
      lhs.sort_by_key(|(replica, _, _, _)| *replica);
      lhs
    },
    vec![
      (1, 3, string!(""), vec![1]),
      (1, 4, string!(""), vec![2]),
      (1, 5, string!(""), vec![3]),
      (1, 6, string!(""), vec![4]),
      (2, 3, string!(""), vec![5]),
      (2, 5, string!(""), vec![6]),
      (2, 6, string!(""), vec![7]),
      (3, 5, string!(""), vec![8]),
      (3, 6, string!(""), vec![9]),
      (5, 7, string!(""), vec![10]),
    ]
  );
  history.assert_invariants(&mut store);
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
    match rng.gen_range(0..=5) {
      0 => {
        let this = history.this();
        history = VectorHistory::new(&mut store, "");
        assert_ne!(history.this(), 0);
        assert_eq!(this, history.this());
      }
      1 => {
        let mut lhs = history.nexts();
        let mut rhs = mock.nexts();
        lhs.retain(|_, v| *v != 0);
        rhs.retain(|_, v| *v != 0);
        assert_eq!(lhs, rhs);
      }
      2 => {
        let begins = mock.data.keys().map(|key| (*key, rng.gen_range(0..10))).collect::<Vec<_>>();
        history.load_until(&mut store, &begins);
        history.assert_invariants(&mut store);
      }
      3 => {
        let begins = mock.data.keys().map(|key| (*key, rng.gen_range(0..10))).collect::<Vec<_>>();
        history.unload_until(&begins);
        history.assert_invariants(&mut store);
      }
      4 => {
        let replica = rng.gen_range(0..10);
        let serial = rng.gen_range(0..10);
        let name = String::from("");
        let action = rand_action();
        assert_eq!(
          history.push(&mut store, (replica, serial, name.clone(), serialize(&action).unwrap())).is_some(),
          mock.push((replica, serial, name, serialize(&action).unwrap())).is_some()
        );
        history.assert_invariants(&mut store);
      }
      5 => {
        let clocks = mock.data.keys().map(|key| (*key, rng.gen_range(0..10))).collect::<HashMap<_, _>>();
        let mut lhs = history.collect(&mut store, clocks.clone());
        let mut rhs = mock.actions(clocks.clone());
        lhs.sort_by_key(|(fst, snd, _, _)| (*fst, *snd));
        rhs.sort_by_key(|(fst, snd, _, _)| (*fst, *snd));
        assert_eq!(lhs.len(), rhs.len());
        for (lhs, rhs) in std::iter::zip(lhs.into_iter(), rhs.into_iter()) {
          assert_eq!(lhs.0, rhs.0);
          assert_eq!(lhs.1, rhs.1);
          assert_eq!(lhs.2, rhs.2);
          assert!(action_eq(deserialize(&lhs.3).unwrap(), deserialize(&rhs.3).unwrap()));
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
