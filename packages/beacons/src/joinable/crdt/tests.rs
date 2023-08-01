use rand::Rng;

use super::super::tests::*;
use super::*;
use crate::joinable::{Clock, State};

#[test]
fn register_simple() {
  let mut a = Register::<u64>::new();
  assert_eq!(*a.value(), 0);
  a.apply(Register::from(Clock::from(3), 233));
  assert_eq!(*a.value(), 233);
  a.apply(Register::from(Clock::from(4), 2333));
  assert_eq!(*a.value(), 2333);
  a.apply(Register::from(Clock::from(2), 23333));
  assert_eq!(*a.value(), 2333);
  a.apply(Register::from(Clock::from(5), 233333));
  assert_eq!(*a.value(), 233333);
}

#[test]
fn register_random() {
  let rand_state =
    || Register::<u64>::from(Clock::from(rand::thread_rng().gen_range(0..10)), rand::thread_rng().gen_range(0..10));
  let rand_action = rand_state;
  let state_eq = |r, s| r == s;

  assert_joinable(rand_state, rand_action, state_eq, 1000);
  assert_delta_joinable(rand_state, rand_action, state_eq, 1000);
  assert_gamma_joinable(rand_state, rand_action, state_eq, 1000);
}

#[test]
fn object_set_simple() {
  let mut a = ObjectSet::new();
  assert_eq!(a.get(0), None);
  assert_eq!(a.get(1), None);
  assert_eq!(a.get(2), None);

  a.apply(ObjectSet::action(Clock::from(3), 2, Some(vec![2, 3, 3])));
  assert_eq!(a.get(0), None);
  assert_eq!(a.get(1), None);
  assert_eq!(a.get(2), Some(vec![2, 3, 3].as_slice()));

  a.apply(ObjectSet::action(Clock::from(4), 1, Some(vec![2, 3, 3, 3])));
  assert_eq!(a.get(0), None);
  assert_eq!(a.get(1), Some(vec![2, 3, 3, 3].as_slice()));
  assert_eq!(a.get(2), Some(vec![2, 3, 3].as_slice()));

  a.apply(ObjectSet::action(Clock::from(2), 2, Some(vec![2, 3, 3, 3, 3])));
  assert_eq!(a.get(0), None);
  assert_eq!(a.get(1), Some(vec![2, 3, 3, 3].as_slice()));
  assert_eq!(a.get(2), Some(vec![2, 3, 3].as_slice()));

  a.apply(ObjectSet::action(Clock::from(5), 2, None));
  assert_eq!(a.get(0), None);
  assert_eq!(a.get(1), Some(vec![2, 3, 3, 3].as_slice()));
  assert_eq!(a.get(2), None);
}

#[test]
fn object_graph_simple() {
  let mut a = ObjectGraph::new();
  assert_eq!(a.node(0), None);
  assert_eq!(a.node(1), None);
  assert_eq!(a.edge(0), None);
  assert_eq!(a.edge(1), None);

  a.apply(ObjectGraph::action_node(Clock::from(3), 0, Some(233)));
  a.apply(ObjectGraph::action_edge(Clock::from(3), 0, Some((0, 233, 1))));
  assert_eq!(a.node(0), Some(233));
  assert_eq!(a.node(1), None);
  assert_eq!(a.edge(0), Some((0, 233, 1)));
  assert_eq!(a.edge(1), None);

  a.apply(ObjectGraph::action_node(Clock::from(4), 0, Some(2333)));
  a.apply(ObjectGraph::action_edge(Clock::from(4), 0, Some((0, 2333, 1))));
  assert_eq!(a.node(0), Some(2333));
  assert_eq!(a.node(1), None);
  assert_eq!(a.edge(0), Some((0, 2333, 1)));
  assert_eq!(a.edge(1), None);

  a.apply(ObjectGraph::action_node(Clock::from(2), 0, Some(23333)));
  a.apply(ObjectGraph::action_edge(Clock::from(2), 0, Some((0, 23333, 1))));
  assert_eq!(a.node(0), Some(2333));
  assert_eq!(a.node(1), None);
  assert_eq!(a.edge(0), Some((0, 2333, 1)));
  assert_eq!(a.edge(1), None);

  a.apply(ObjectGraph::action_node(Clock::from(5), 0, None));
  a.apply(ObjectGraph::action_edge(Clock::from(5), 0, None));
  assert_eq!(a.node(0), None);
  assert_eq!(a.node(1), None);
  assert_eq!(a.edge(0), None);
  assert_eq!(a.edge(1), None);
}
