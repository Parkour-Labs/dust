use std::collections::HashMap;
use std::hash::Hash;

use super::joinable::basic::*;
use super::joinable::register::*;
use super::joinable::*;

type Inner<I, V, A, E> = (
  HashMap<I, Register<Option<V>>>,
  HashMap<I, Register<Option<(I, A)>>>,
  HashMap<I, Register<Option<(I, I, E)>>>,
);
type Action<I, V, A, E> = (
  Vec<(I, Register<Option<V>>)>,
  Vec<(I, Register<Option<(I, A)>>)>,
  Vec<(I, Register<Option<(I, I, E)>>)>,
);

/// A last-writer-win graph.
///
/// - [Graph] is an instance of [State] space.
/// - [Graph] is an instance of [Joinable] state space.
/// - [Graph] is an instance of [DeltaJoinable] state space.
/// - [Graph] is an instance of [GammaJoinable] state space.
#[derive(Clone, PartialEq, Eq)]
pub struct Graph<I, V, A, E>(Inner<I, V, A, E>)
where
  I: Copy + Ord + Hash,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord;

#[allow(clippy::type_complexity)]
impl<I, V, A, E> Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
{
  fn vertices(&self) -> &HashMap<I, Register<Option<V>>> {
    &self.0 .0
  }
  fn atoms(&self) -> &HashMap<I, Register<Option<(I, A)>>> {
    &self.0 .1
  }
  fn edges(&self) -> &HashMap<I, Register<Option<(I, I, E)>>> {
    &self.0 .2
  }

  /// Creates an empty graph.
  pub fn new() -> Self {
    Self::initial()
  }

  /// Obtains reference to vertex value.
  pub fn vertex(&self, index: &I) -> Option<&V> {
    match &self.vertices().get(index)?.get() {
      Some(s) => Some(s),
      None => None,
    }
  }

  /// Obtains reference to atom value.
  pub fn atom(&self, index: &I) -> Option<&(I, A)> {
    match &self.atoms().get(index)?.get() {
      Some(s) => self.vertices().get(&s.0).and(Some(s)),
      None => None,
    }
  }

  /// Obtains reference to edge value.
  pub fn edge(&self, index: &I) -> Option<&(I, I, E)> {
    match &self.edges().get(index)?.get() {
      Some(s) => self.vertices().get(&s.0).and(self.vertices().get(&s.1)).and(Some(s)),
      None => None,
    }
  }

  /// Makes modification of vertex value.
  pub fn make_vertex_mod(index: I, value: Option<V>, clock: Clock) -> Action<I, V, A, E> {
    (vec![(index, Register::make_mod(value, clock))], vec![], vec![])
  }

  /// Makes modification of atom value.
  pub fn make_atom_mod(index: I, value: Option<(I, A)>, clock: Clock) -> Action<I, V, A, E> {
    (vec![], vec![(index, Register::make_mod(value, clock))], vec![])
  }

  /// Makes modification of edge value.
  pub fn make_edge_mod(index: I, value: Option<(I, I, E)>, clock: Clock) -> Action<I, V, A, E> {
    (vec![], vec![], vec![(index, Register::make_mod(value, clock))])
  }
}

// -----------------------------------------------------------------------------
// Boilerplate for transporting trait instances.
// -----------------------------------------------------------------------------

impl<I, V, A, E> Default for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
{
  fn default() -> Self {
    Self::initial()
  }
}

impl<I, V, A, E> State<Action<I, V, A, E>> for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
{
  fn initial() -> Self {
    Self(Inner::<I, V, A, E>::initial())
  }
  fn apply(s: Self, a: &Action<I, V, A, E>) -> Self {
    Self(Inner::<I, V, A, E>::apply(s.0, a))
  }
  fn id() -> Action<I, V, A, E> {
    Inner::<I, V, A, E>::id()
  }
  fn comp(a: Action<I, V, A, E>, b: Action<I, V, A, E>) -> Action<I, V, A, E> {
    Inner::<I, V, A, E>::comp(a, b)
  }
}

impl<I, V, A, E> Joinable<Action<I, V, A, E>> for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
{
  fn preq(s: &Self, t: &Self) -> bool {
    Inner::<I, V, A, E>::preq(&s.0, &t.0)
  }
  fn join(s: Self, t: Self) -> Self {
    Self(Inner::<I, V, A, E>::join(s.0, t.0))
  }
}

impl<I, V, A, E> DeltaJoinable<Action<I, V, A, E>> for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
{
  fn delta_join(s: Self, a: &Action<I, V, A, E>, b: &Action<I, V, A, E>) -> Self {
    Self(Inner::<I, V, A, E>::delta_join(s.0, a, b))
  }
}

impl<I, V, A, E> GammaJoinable<Action<I, V, A, E>> for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
{
  fn gamma_join(s: Self, a: &Action<I, V, A, E>) -> Self {
    Self(Inner::<I, V, A, E>::gamma_join(s.0, a))
  }
}
