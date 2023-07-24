//! A last-writer-win object graph.

use derive_more::{AsMut, AsRef, From, Into};
use std::collections::HashMap;

use super::Register;
use crate::joinable::{Clock, Index, Newtype, State};

type Inner<I, A, E> = (HashMap<I, Register<Option<(I, A)>>>, HashMap<I, Register<Option<(I, I, E)>>>);

/// A last-writer-win object graph.
///
/// - [`ObjectGraph`] is an instance of [`State`] space.
/// - [`ObjectGraph`] is an instance of [`Joinable`] state space.
/// - [`ObjectGraph`] is an instance of [`DeltaJoinable`] state space.
/// - [`ObjectGraph`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(Debug, From, Into, AsRef, AsMut)]
pub struct ObjectGraph<I: Index + Ord, A: Ord, E: Ord> {
  pub(crate) inner: Inner<I, A, E>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl<I: Index + Ord, A: Ord, E: Ord> Newtype for ObjectGraph<I, A, E> {
  type Inner = Inner<I, A, E>;
}

impl<I: Index + Ord, A: Ord, E: Ord> Default for ObjectGraph<I, A, E> {
  fn default() -> Self {
    Self::initial()
  }
}

#[allow(clippy::type_complexity)]
impl<I: Index + Ord, A: Ord, E: Ord> ObjectGraph<I, A, E> {
  fn atoms(&self) -> &HashMap<I, Register<Option<(I, A)>>> {
    &self.inner.0
  }
  fn edges(&self) -> &HashMap<I, Register<Option<(I, I, E)>>> {
    &self.inner.1
  }
  /// Creates an empty graph.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Obtains reference to atom value.
  pub fn atom(&self, index: &I) -> Option<&(I, A)> {
    self.atoms().get(index)?.value().as_ref()
  }
  /// Obtains reference to edge value.
  pub fn edge(&self, index: &I) -> Option<&(I, I, E)> {
    self.edges().get(index)?.value().as_ref()
  }
  /// Makes modification of atom value.
  pub fn action_atom(clock: Clock, index: I, value: Option<(I, A)>) -> <Self as State>::Action {
    (HashMap::from([(index, Register::action(clock, value))]), HashMap::new())
  }
  /// Makes modification of edge value.
  pub fn action_edge(clock: Clock, index: I, value: Option<(I, I, E)>) -> <Self as State>::Action {
    (HashMap::new(), HashMap::from([(index, Register::action(clock, value))]))
  }
}
