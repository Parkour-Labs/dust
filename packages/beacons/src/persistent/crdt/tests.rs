use rand::Rng;
use rusqlite::Connection;

use super::*;
use crate::joinable::{crdt as jcrdt, Clock, GammaJoinable, Joinable, State};
use crate::persistent::{PersistentGammaJoinable, PersistentJoinable, PersistentState};

#[test]
fn register_simple() {
  let mut conn = Connection::open_in_memory().unwrap();
  let mut txn = conn.transaction().unwrap();

  let mut a = Register::<u64>::new(&mut txn, "collection", "name");
  assert_eq!(*a.value(), 0);
  a.apply(&mut txn, jcrdt::Register::from(Clock::from_u128(3), 233));
  assert_eq!(*a.value(), 233);
  a.apply(&mut txn, jcrdt::Register::from(Clock::from_u128(4), 2333));
  assert_eq!(*a.value(), 2333);
  a.apply(&mut txn, jcrdt::Register::from(Clock::from_u128(2), 23333));
  assert_eq!(*a.value(), 2333);
  a.apply(&mut txn, jcrdt::Register::from(Clock::from_u128(5), 233333));
  assert_eq!(*a.value(), 233333);
}

#[test]
fn register_random() {
  let mut conn = Connection::open_in_memory().unwrap();
  let mut txn = conn.transaction().unwrap();

  let mut a = Register::<u64>::new(&mut txn, "collection", "name");
  let mut b = jcrdt::Register::<u64>::new();

  let count = 1000;
  let mut rng = rand::thread_rng();

  for _ in 0..count {
    match rng.gen_range(0..=5) {
      0 => {
        a = Register::new(&mut txn, "collection", "name");
      }
      1 => {
        assert_eq!(a.clock(), b.clock());
        assert_eq!(a.value(), b.value());
      }
      2 => {
        let action = jcrdt::Register::from(Clock::from_u128(rng.gen_range(0..10)), rng.gen_range(0..10));
        a.apply(&mut txn, action);
        b.apply(action);
      }
      3 => {
        let state = jcrdt::Register::from(Clock::from_u128(rng.gen_range(0..10)), rng.gen_range(0..10));
        assert_eq!(a.preq(&mut txn, &state), b.preq(&state));
      }
      4 => {
        let state = jcrdt::Register::from(Clock::from_u128(rng.gen_range(0..10)), rng.gen_range(0..10));
        a.join(&mut txn, state);
        b.join(state);
      }
      5 => {
        let action = jcrdt::Register::from(Clock::from_u128(rng.gen_range(0..10)), rng.gen_range(0..10));
        a.gamma_join(&mut txn, action);
        b.gamma_join(action);
      }
      _ => panic!(),
    }
  }
}

#[test]
fn object_set_simple() {
  let mut conn = Connection::open_in_memory().unwrap();
  let mut txn = conn.transaction().unwrap();

  let mut a = ObjectSet::new(&mut txn, "collection", "name");
  assert_eq!(a.get(&mut txn, 0), None);
  assert_eq!(a.get(&mut txn, 1), None);
  assert_eq!(a.get(&mut txn, 2), None);

  a.apply(&mut txn, ObjectSet::action(Clock::from_u128(3), 2, Some(vec![2, 3, 3])));
  assert_eq!(a.get(&mut txn, 0), None);
  assert_eq!(a.get(&mut txn, 1), None);
  assert_eq!(a.get(&mut txn, 2), Some(vec![2, 3, 3].as_slice()));

  a.apply(&mut txn, ObjectSet::action(Clock::from_u128(4), 1, Some(vec![2, 3, 3, 3])));
  assert_eq!(a.get(&mut txn, 0), None);
  assert_eq!(a.get(&mut txn, 1), Some(vec![2, 3, 3, 3].as_slice()));
  assert_eq!(a.get(&mut txn, 2), Some(vec![2, 3, 3].as_slice()));

  a.apply(&mut txn, ObjectSet::action(Clock::from_u128(2), 2, Some(vec![2, 3, 3, 3, 3])));
  assert_eq!(a.get(&mut txn, 0), None);
  assert_eq!(a.get(&mut txn, 1), Some(vec![2, 3, 3, 3].as_slice()));
  assert_eq!(a.get(&mut txn, 2), Some(vec![2, 3, 3].as_slice()));

  a.apply(&mut txn, ObjectSet::action(Clock::from_u128(5), 2, None));
  assert_eq!(a.get(&mut txn, 0), None);
  assert_eq!(a.get(&mut txn, 1), Some(vec![2, 3, 3, 3].as_slice()));
  assert_eq!(a.get(&mut txn, 2), None);
}

#[test]
fn object_set_random() {
  let mut conn = Connection::open_in_memory().unwrap();
  let mut txn = conn.transaction().unwrap();

  let mut a = ObjectSet::new(&mut txn, "collection", "name");
  let mut b = jcrdt::ObjectSet::new();

  let count = 10000;
  let mut rng = rand::thread_rng();

  for _ in 0..count {
    match rng.gen_range(0..=4) {
      0 => {
        a = ObjectSet::new(&mut txn, "collection", "name");
      }
      1 => {
        let id = rng.gen_range(0..10);
        assert_eq!(a.get(&mut txn, id), b.get(id));
      }
      2 => {
        let action = jcrdt::ObjectSet::action(
          Clock::from_u128(rng.gen_range(0..10)),
          rng.gen_range(0..10),
          Some(vec![rng.gen_range(0..10)]),
        );
        a.apply(&mut txn, action.clone());
        b.apply(action);
      }
      3 => {
        let id = rng.gen_range(0..10);
        a.load(&mut txn, id);
      }
      4 => {
        let id = rng.gen_range(0..10);
        a.unload(id);
      }
      _ => panic!(),
    }
  }
}

#[test]
fn object_graph_simple() {
  let mut conn = Connection::open_in_memory().unwrap();
  let mut txn = conn.transaction().unwrap();

  let mut a = ObjectGraph::new(&mut txn, "collection", "name");
  assert_eq!(a.node(&mut txn, 0), None);
  assert_eq!(a.node(&mut txn, 1), None);
  assert_eq!(a.edge(&mut txn, 0), None);
  assert_eq!(a.edge(&mut txn, 1), None);

  a.apply(&mut txn, ObjectGraph::action_node(Clock::from_u128(3), 0, Some(233)));
  a.apply(&mut txn, ObjectGraph::action_edge(Clock::from_u128(3), 0, Some((0, 233, 1))));
  assert_eq!(a.node(&mut txn, 0), Some(233));
  assert_eq!(a.node(&mut txn, 1), None);
  assert_eq!(a.edge(&mut txn, 0), Some((0, 233, 1)));
  assert_eq!(a.edge(&mut txn, 1), None);

  a.apply(&mut txn, ObjectGraph::action_node(Clock::from_u128(4), 0, Some(2333)));
  a.apply(&mut txn, ObjectGraph::action_edge(Clock::from_u128(4), 0, Some((0, 2333, 1))));
  assert_eq!(a.node(&mut txn, 0), Some(2333));
  assert_eq!(a.node(&mut txn, 1), None);
  assert_eq!(a.edge(&mut txn, 0), Some((0, 2333, 1)));
  assert_eq!(a.edge(&mut txn, 1), None);

  a.apply(&mut txn, ObjectGraph::action_node(Clock::from_u128(2), 0, Some(23333)));
  a.apply(&mut txn, ObjectGraph::action_edge(Clock::from_u128(2), 0, Some((0, 23333, 1))));
  assert_eq!(a.node(&mut txn, 0), Some(2333));
  assert_eq!(a.node(&mut txn, 1), None);
  assert_eq!(a.edge(&mut txn, 0), Some((0, 2333, 1)));
  assert_eq!(a.edge(&mut txn, 1), None);

  a.apply(&mut txn, ObjectGraph::action_node(Clock::from_u128(5), 0, None));
  a.apply(&mut txn, ObjectGraph::action_edge(Clock::from_u128(5), 0, None));
  assert_eq!(a.node(&mut txn, 0), None);
  assert_eq!(a.node(&mut txn, 1), None);
  assert_eq!(a.edge(&mut txn, 0), None);
  assert_eq!(a.edge(&mut txn, 1), None);
}

#[test]
fn object_graph_random() {
  let mut conn = Connection::open_in_memory().unwrap();
  let mut txn = conn.transaction().unwrap();

  let mut a = ObjectGraph::new(&mut txn, "collection", "name");
  let mut b = jcrdt::ObjectGraph::new();

  let count = 10000;
  let mut rng = rand::thread_rng();

  for _ in 0..count {
    match rng.gen_range(0..=9) {
      0 => {
        a = ObjectGraph::new(&mut txn, "collection", "name");
      }
      1 => {
        let id = rng.gen_range(0..10);
        assert_eq!(a.node(&mut txn, id), b.node(id));
      }
      2 => {
        let id = rng.gen_range(0..10);
        assert_eq!(a.edge(&mut txn, id), b.edge(id));
      }
      3 => {
        let action = jcrdt::ObjectGraph::action_node(
          Clock::from_u128(rng.gen_range(0..10)),
          rng.gen_range(0..10),
          Some(rng.gen_range(0..10)),
        );
        a.apply(&mut txn, action.clone());
        b.apply(action);
      }
      4 => {
        let action = jcrdt::ObjectGraph::action_edge(
          Clock::from_u128(rng.gen_range(0..10)),
          rng.gen_range(0..10),
          Some((rng.gen_range(0..10), rng.gen_range(0..10), rng.gen_range(0..10))),
        );
        a.apply(&mut txn, action.clone());
        b.apply(action);
      }
      5 => {
        let id = rng.gen_range(0..10);
        a.load_node(&mut txn, id);
      }
      6 => {
        let id = rng.gen_range(0..10);
        a.load_edge(&mut txn, id);
      }
      7 => {
        let id = rng.gen_range(0..10);
        a.unload_node(id);
      }
      8 => {
        let id = rng.gen_range(0..10);
        a.unload_edge(id);
      }
      9 => {
        a.query_edge_label_dst(&mut txn, rng.gen_range(0..10), rng.gen_range(0..10));
        a.query_edge_src(&mut txn, rng.gen_range(0..10));
        a.query_node_label(&mut txn, rng.gen_range(0..10));
      }
      _ => panic!(),
    }
  }
}
