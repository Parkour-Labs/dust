//! A last-writer-win object graph.

use derive_more::{AsMut, AsRef, From, Into};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::Register;
use crate::joinable::{Clock, Newtype, State};

type Nodes = HashMap<u128, Register<Option<u64>>>;
type Edges = HashMap<u128, Register<Option<(u128, u64, u128)>>>;

/// A last-writer-win object graph.
///
/// - [`ObjectGraph`] is an instance of [`State`] space.
/// - [`ObjectGraph`] is an instance of [`Joinable`] state space.
/// - [`ObjectGraph`] is an instance of [`DeltaJoinable`] state space.
/// - [`ObjectGraph`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(Debug, From, Into, AsRef, AsMut, Serialize, Deserialize)]
pub struct ObjectGraph {
  pub(crate) inner: (Nodes, Edges),
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl Newtype for ObjectGraph {
  type Inner = (Nodes, Edges);
}

impl ObjectGraph {
  /// Creates an empty graph.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Creates a graph from data.
  pub fn from(nodes: Nodes, edges: Edges) -> Self {
    Self { inner: (nodes, edges) }
  }
  /// Obtains reference to node value.
  pub fn node(&self, id: u128) -> Option<u64> {
    *self.inner.0.get(&id)?.value()
  }
  /// Obtains reference to edge value.
  pub fn edge(&self, id: u128) -> Option<(u128, u64, u128)> {
    *self.inner.1.get(&id)?.value()
  }
  /// Makes modification of node value.
  pub fn action_node(clock: Clock, id: u128, value: Option<u64>) -> <Self as State>::Action {
    (HashMap::from([(id, Register::action(clock, value))]), HashMap::new())
  }
  /// Makes modification of edge value.
  pub fn action_edge(clock: Clock, id: u128, value: Option<(u128, u64, u128)>) -> <Self as State>::Action {
    (HashMap::new(), HashMap::from([(id, Register::action(clock, value))]))
  }
}

impl Default for ObjectGraph {
  fn default() -> Self {
    Self::initial()
  }
}
