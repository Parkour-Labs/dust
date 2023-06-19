use derive_more::{AsMut, AsRef, From, Into};
use std::collections::HashMap;

use super::basic::*;
use super::register::*;
use super::*;

type Inner<I, V, A, E> =
  (HashMap<I, Register<Option<V>>>, HashMap<I, Register<Option<(I, A)>>>, HashMap<I, Register<Option<(I, I, E)>>>);
type Action<I, V, A, E> =
  (Vec<(I, Register<Option<V>>)>, Vec<(I, Register<Option<(I, A)>>)>, Vec<(I, Register<Option<(I, I, E)>>)>);

/// A last-writer-win graph.
///
/// - [Graph] is an instance of [State] space.
/// - [Graph] is an instance of [Joinable] state space.
/// - [Graph] is an instance of [DeltaJoinable] state space.
/// - [Graph] is an instance of [GammaJoinable] state space.
#[derive(From, Into, AsRef, AsMut)]
pub struct Graph<I: Index + Ord, V: Clone + Ord, A: Clone + Ord, E: Clone + Ord> {
  inner: Inner<I, V, A, E>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl<I: Index + Ord, V: Clone + Ord, A: Clone + Ord, E: Clone + Ord> Newtype for Graph<I, V, A, E> {
  type Inner = Inner<I, V, A, E>;
}

impl<I: Index + Ord, V: Clone + Ord, A: Clone + Ord, E: Clone + Ord> Default for Graph<I, V, A, E> {
  fn default() -> Self {
    Self::initial()
  }
}

#[allow(clippy::type_complexity)]
impl<I, V, A, E> Graph<I, V, A, E>
where
  I: Index + Ord,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
{
  fn vertices(&self) -> &HashMap<I, Register<Option<V>>> {
    &self.inner.0
  }
  fn atoms(&self) -> &HashMap<I, Register<Option<(I, A)>>> {
    &self.inner.1
  }
  fn edges(&self) -> &HashMap<I, Register<Option<(I, I, E)>>> {
    &self.inner.2
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
