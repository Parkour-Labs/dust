//! A last-writer-win object graph.

use derive_more::{AsMut, AsRef, From, Into};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::Register;
use crate::joinable::{Clock, Newtype, State};

type Atoms = HashMap<u128, Register<Option<(u128, Vec<u8>)>>>;
type Edges = HashMap<u128, Register<Option<(u128, u128, Vec<u8>)>>>;

/// A last-writer-win object graph.
///
/// - [`ObjectGraph`] is an instance of [`State`] space.
/// - [`ObjectGraph`] is an instance of [`Joinable`] state space.
/// - [`ObjectGraph`] is an instance of [`DeltaJoinable`] state space.
/// - [`ObjectGraph`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(Debug, From, Into, AsRef, AsMut, Serialize, Deserialize)]
pub struct ObjectGraph {
  pub(crate) inner: (Atoms, Edges),
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl Newtype for ObjectGraph {
  type Inner = (Atoms, Edges);
}

impl ObjectGraph {
  /// Creates an empty graph.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Creates a graph from data.
  pub fn from(atoms: Atoms, edges: Edges) -> Self {
    Self { inner: (atoms, edges) }
  }
  /// Obtains reference to atom value.
  pub fn atom(&self, index: u128) -> Option<&(u128, Vec<u8>)> {
    self.inner.0.get(&index)?.value().as_ref()
  }
  /// Obtains reference to edge value.
  pub fn edge(&self, index: u128) -> Option<&(u128, u128, Vec<u8>)> {
    self.inner.1.get(&index)?.value().as_ref()
  }
  /// Makes modification of atom value.
  pub fn action_atom(clock: Clock, index: u128, value: Option<(u128, Vec<u8>)>) -> <Self as State>::Action {
    (HashMap::from([(index, Register::action(clock, value))]), HashMap::new())
  }
  /// Makes modification of edge value.
  pub fn action_edge(clock: Clock, index: u128, value: Option<(u128, u128, Vec<u8>)>) -> <Self as State>::Action {
    (HashMap::new(), HashMap::from([(index, Register::action(clock, value))]))
  }
}

impl Default for ObjectGraph {
  fn default() -> Self {
    Self::initial()
  }
}
