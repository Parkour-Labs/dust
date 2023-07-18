//! A last-writer-win object graph.

use derive_more::{AsMut, AsRef, From, Into};
use std::collections::HashMap;

use super::Register;
use crate::joinable::{Clock, Index, Newtype, State};

type Inner<I, V, A, E> =
  (HashMap<I, Register<Option<V>>>, HashMap<I, Register<Option<(I, A)>>>, HashMap<I, Register<Option<(I, I, E)>>>);

/// A last-writer-win object graph.
///
/// - [`ObjectGraph`] is an instance of [`State`] space.
/// - [`ObjectGraph`] is an instance of [`Joinable`] state space.
/// - [`ObjectGraph`] is an instance of [`DeltaJoinable`] state space.
/// - [`ObjectGraph`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(Debug, From, Into, AsRef, AsMut)]
pub struct ObjectGraph<I, V, A, E>
where
  I: Index + Ord,
  V: Ord,
  A: Ord,
  E: Ord,
{
  inner: Inner<I, V, A, E>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl<I, V, A, E> Newtype for ObjectGraph<I, V, A, E>
where
  I: Index + Ord,
  V: Ord,
  A: Ord,
  E: Ord,
{
  type Inner = Inner<I, V, A, E>;
}

impl<I, V, A, E> Default for ObjectGraph<I, V, A, E>
where
  I: Index + Ord,
  V: Ord,
  A: Ord,
  E: Ord,
{
  fn default() -> Self {
    Self::initial()
  }
}

#[allow(clippy::type_complexity)]
impl<I, V, A, E> ObjectGraph<I, V, A, E>
where
  I: Index + Ord,
  V: Ord,
  A: Ord,
  E: Ord,
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
    match &self.vertices().get(index)?.value() {
      Some(s) => Some(s),
      None => None,
    }
  }
  /// Obtains reference to atom value.
  pub fn atom(&self, index: &I) -> Option<&(I, A)> {
    match &self.atoms().get(index)?.value() {
      Some(s) => self.vertices().get(&s.0).and(Some(s)),
      None => None,
    }
  }
  /// Obtains reference to edge value.
  pub fn edge(&self, index: &I) -> Option<&(I, I, E)> {
    match &self.edges().get(index)?.value() {
      Some(s) => self.vertices().get(&s.0).and(self.vertices().get(&s.1)).and(Some(s)),
      None => None,
    }
  }
  /// Makes modification of vertex value.
  pub fn action_vertex(clock: Clock, index: I, value: Option<V>) -> <Self as State>::Action {
    (HashMap::from([(index, Register::action(clock, value))]), HashMap::new(), HashMap::new())
  }
  /// Makes modification of atom value.
  pub fn action_atom(clock: Clock, index: I, value: Option<(I, A)>) -> <Self as State>::Action {
    (HashMap::new(), HashMap::from([(index, Register::action(clock, value))]), HashMap::new())
  }
  /// Makes modification of edge value.
  pub fn action_edge(clock: Clock, index: I, value: Option<(I, I, E)>) -> <Self as State>::Action {
    (HashMap::new(), HashMap::new(), HashMap::from([(index, Register::action(clock, value))]))
  }
}
