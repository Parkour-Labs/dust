use rand::Rng;
use rusqlite::Connection;

use super::*;
use crate::joinable::{crdt as jcrdt, State};
use crate::persistent::PersistentState;

#[test]
fn object_set_simple() {
  let mut conn = Connection::open_in_memory().unwrap();
  let mut txn = conn.transaction().unwrap();

  let mut a = ObjectSet::new(&mut txn, "collection", "name");
  assert_eq!(a.get(&mut txn, 0), None);
  assert_eq!(a.get(&mut txn, 1), None);
  assert_eq!(a.get(&mut txn, 2), None);

  let action = a.action(&mut txn, 2, Some(vec![2, 3, 3]));
  a.apply(&mut txn, action);
  assert_eq!(a.get(&mut txn, 0), None);
  assert_eq!(a.get(&mut txn, 1), None);
  assert_eq!(a.get(&mut txn, 2), Some(vec![2, 3, 3].as_slice()));

  let action = a.action(&mut txn, 1, Some(vec![2, 3, 3, 3]));
  a.apply(&mut txn, action);
  assert_eq!(a.get(&mut txn, 0), None);
  assert_eq!(a.get(&mut txn, 1), Some(vec![2, 3, 3, 3].as_slice()));
  assert_eq!(a.get(&mut txn, 2), Some(vec![2, 3, 3].as_slice()));

  let action = a.action(&mut txn, 2, None);
  a.apply(&mut txn, action);
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
        let action = a.action(&mut txn, rng.gen_range(0..10), Some(vec![rng.gen_range(0..10)]));
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

  let action = a.action_node(&mut txn, 0, Some(233));
  a.apply(&mut txn, action);
  let action = a.action_edge(&mut txn, 0, Some((0, 233, 1)));
  a.apply(&mut txn, action);
  assert_eq!(a.node(&mut txn, 0), Some(233));
  assert_eq!(a.node(&mut txn, 1), None);
  assert_eq!(a.edge(&mut txn, 0), Some((0, 233, 1)));
  assert_eq!(a.edge(&mut txn, 1), None);

  let action = a.action_node(&mut txn, 0, Some(2333));
  a.apply(&mut txn, action);
  let action = a.action_edge(&mut txn, 0, Some((0, 2333, 1)));
  a.apply(&mut txn, action);
  assert_eq!(a.node(&mut txn, 0), Some(2333));
  assert_eq!(a.node(&mut txn, 1), None);
  assert_eq!(a.edge(&mut txn, 0), Some((0, 2333, 1)));
  assert_eq!(a.edge(&mut txn, 1), None);

  let action = a.action_node(&mut txn, 0, None);
  a.apply(&mut txn, action);
  let action = a.action_edge(&mut txn, 0, None);
  a.apply(&mut txn, action);
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
        let action = a.action_node(&mut txn, rng.gen_range(0..10), Some(rng.gen_range(0..10)));
        a.apply(&mut txn, action.clone());
        b.apply(action);
      }
      4 => {
        let action = a.action_edge(
          &mut txn,
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
        a.query_node_label(&mut txn, rng.gen_range(0..10));
        a.query_edge_src(&mut txn, rng.gen_range(0..10));
        a.query_edge_src_label(&mut txn, rng.gen_range(0..10), rng.gen_range(0..10));
        a.query_edge_dst_label(&mut txn, rng.gen_range(0..10), rng.gen_range(0..10));
      }
      _ => panic!(),
    }
  }
}
