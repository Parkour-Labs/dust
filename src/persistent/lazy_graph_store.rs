use super::store::*;
use crate::joinable::basic::*;

/// All queries required by the lazy-load graph.
pub trait LazyGraphStore<I, V, A, E>
where
  I: Index + Ord,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
{
  fn get_vertex(&mut self, index: I) -> Option<V>;
  fn set_vertex(&mut self, index: I, value: Option<&V>);

  fn get_atom(&mut self, index: I) -> Option<(I, A)>;
  fn set_atom(&mut self, index: I, value: Option<&(I, A)>);

  fn get_edge(&mut self, index: I) -> Option<(I, I, E)>;
  fn set_edge(&mut self, index: I, value: Option<&(I, I, E)>);

  fn get_atoms_by_src(&mut self, src: I) -> Vec<(I, (I, A))>;
  fn get_edges_by_src(&mut self, src: I) -> Vec<(I, (I, I, E))>;
  fn get_edges_by_dst(&mut self, dst: I) -> Vec<(I, (I, I, E))>;
}

/// [LazyGraphStore] can be satisfied by using a combination of common stores.
impl<I, V, A, E, VS, AS, ES> LazyGraphStore<I, V, A, E> for (VS, AS, ES)
where
  I: Index + Ord,
  V: Clone + Ord,
  A: Clone + Ord,
  E: Clone + Ord,
  VS: KeyValueStore<I, V>,
  AS: KeyIndexValueStore<I, I, A>,
  ES: KeyBiIndexValueStore<I, I, I, E>,
{
  fn get_vertex(&mut self, index: I) -> Option<V> {
    self.0.get(index)
  }
  fn set_vertex(&mut self, index: I, value: Option<&V>) {
    self.0.set(index, value)
  }
  fn get_atom(&mut self, index: I) -> Option<(I, A)> {
    self.1.get(index)
  }
  fn set_atom(&mut self, index: I, value: Option<&(I, A)>) {
    self.1.set(index, value)
  }
  fn get_edge(&mut self, index: I) -> Option<(I, I, E)> {
    self.2.get(index)
  }
  fn set_edge(&mut self, index: I, value: Option<&(I, I, E)>) {
    self.2.set(index, value)
  }
  fn get_atoms_by_src(&mut self, src: I) -> Vec<(I, (I, A))> {
    self.1.get_by_index(src)
  }
  fn get_edges_by_src(&mut self, src: I) -> Vec<(I, (I, I, E))> {
    self.2.get_by_index_1(src)
  }
  fn get_edges_by_dst(&mut self, dst: I) -> Vec<(I, (I, I, E))> {
    self.2.get_by_index_2(dst)
  }
}
