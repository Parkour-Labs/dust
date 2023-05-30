use std::collections::HashSet;

use crate::joinable::{
  basic::{Clock, Index},
  graph::Graph,
  GammaJoinable,
};

use super::lazy_graph_store::LazyGraphStore;

pub struct LazyGraph<I, V, A, E, Store>
where
  I: Index + Ord,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
  Store: LazyGraphStore<I, V, A, E>,
{
  graph: Graph<I, V, A, E>,
  loaded: HashSet<I>,
  store: Store,
}

impl<I, V, A, E, Store> LazyGraph<I, V, A, E, Store>
where
  I: Index + Ord,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
  Store: LazyGraphStore<I, V, A, E>,
{
  /// Creates an empty graph.
  pub fn new(store: Store) -> Self {
    Self {
      graph: Graph::new(),
      loaded: HashSet::new(),
      store,
    }
  }
  /// Obtains reference to vertex value.
  pub fn vertex(&self, index: &I) -> Option<&V> {
    self.graph.vertex(index)
  }
  /// Obtains reference to atom value.
  pub fn atom(&self, index: &I) -> Option<&(I, A)> {
    self.graph.atom(index)
  }
  /// Obtains reference to edge value.
  pub fn edge(&self, index: &I) -> Option<&(I, I, E)> {
    self.graph.edge(index)
  }
  /// Modifies vertex value.
  pub fn set_vertex(mut self, index: I, value: Option<V>, clock: Clock) -> Self {
    self.graph = GammaJoinable::gamma_join(self.graph, &Graph::make_vertex_mod(index, value, clock));
    self
  }
  /// Modifies atom value.
  pub fn set_atom(mut self, index: I, value: Option<(I, A)>, clock: Clock) -> Self {
    self.graph = GammaJoinable::gamma_join(self.graph, &Graph::make_atom_mod(index, value, clock));
    self
  }
  /// Modifies edge value.
  pub fn set_edge(mut self, index: I, value: Option<(I, I, E)>, clock: Clock) -> Self {
    self.graph = GammaJoinable::gamma_join(self.graph, &Graph::make_edge_mod(index, value, clock));
    self
  }
}
