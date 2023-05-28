use super::register::*;
use super::*;

/// See: https://doc.rust-lang.org/stable/core/option/index.html#comparison-operators
impl<T: Ord> OrdMin for Option<T> {
  fn minimum() -> Self {
    None
  }
}

/// See: https://doc.rust-lang.org/stable/core/option/enum.Option.html#impl-Default-for-Option%3CT%3E
impl<T: Clone + Ord> Default for Register<Option<T>> {
  fn default() -> Self {
    Self {
      clock: Clock::minimum(),
      value: Option::minimum(),
    }
  }
}

type Vertices<I, V> = HashMap<I, Register<Option<V>>>;
type Atoms<I, A> = HashMap<I, Register<Option<(I, A)>>>;
type Edges<I, E> = HashMap<I, Register<Option<(I, I, E)>>>;
type State<I, V, A, E> = (Vertices<I, V>, (Atoms<I, A>, Edges<I, E>));

/// A last-writer-win graph.
///
/// - [Graph] is an instance of [Basic] state space.
/// - [Graph] is an instance of [Joinable] state space.
/// - [Graph] is an instance of [DeltaJoinable] state space.
/// - [Graph] is an instance of [GammaJoinable] state space.
#[derive(Clone, PartialEq, Eq)]
pub struct Graph<I, V, A, E>(State<I, V, A, E>)
where
  I: Copy + Ord + Hash,
  V: Ord + Clone,
  A: Ord + Clone,
  E: Ord + Clone;

impl<I, V, A, E> Basic<State<I, V, A, E>> for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Ord + Clone,
  A: Ord + Clone,
  E: Ord + Clone,
{
  fn apply(s: Graph<I, V, A, E>, a: &State<I, V, A, E>) -> Graph<I, V, A, E> {
    Graph(State::<I, V, A, E>::apply(s.0, a))
  }
  fn id() -> State<I, V, A, E> {
    State::<I, V, A, E>::id()
  }
  fn comp(a: State<I, V, A, E>, b: State<I, V, A, E>) -> State<I, V, A, E> {
    State::<I, V, A, E>::comp(a, b)
  }
}

impl<I, V, A, E> Joinable<State<I, V, A, E>> for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Ord + Clone,
  A: Ord + Clone,
  E: Ord + Clone,
{
  fn preq(s: &Graph<I, V, A, E>, t: &Graph<I, V, A, E>) -> bool {
    State::<I, V, A, E>::preq(&s.0, &t.0)
  }
  fn join(s: Graph<I, V, A, E>, t: Graph<I, V, A, E>) -> Graph<I, V, A, E> {
    Graph(State::<I, V, A, E>::join(s.0, t.0))
  }
}

impl<I, V, A, E> DeltaJoinable<State<I, V, A, E>> for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Ord + Clone,
  A: Ord + Clone,
  E: Ord + Clone,
{
  fn delta_join(s: Graph<I, V, A, E>, a: &State<I, V, A, E>, b: &State<I, V, A, E>) -> Graph<I, V, A, E> {
    Graph(State::<I, V, A, E>::delta_join(s.0, a, b))
  }
}

impl<I, V, A, E> GammaJoinable<State<I, V, A, E>> for Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Ord + Clone,
  A: Ord + Clone,
  E: Ord + Clone,
{
  fn gamma_join(s: Graph<I, V, A, E>, a: &State<I, V, A, E>) -> Graph<I, V, A, E> {
    Graph(State::<I, V, A, E>::gamma_join(s.0, a))
  }
}

impl<I, V, A, E> Graph<I, V, A, E>
where
  I: Copy + Ord + Hash,
  V: Ord + Clone,
  A: Ord + Clone,
  E: Ord + Clone,
{
  fn vertices(&self) -> &Vertices<I, V> {
    &self.0 .0
  }
  fn vertices_mut(&mut self) -> &mut Vertices<I, V> {
    &mut self.0 .0
  }
  fn atoms(&self) -> &Atoms<I, A> {
    &self.0 .1 .0
  }
  fn atoms_mut(&mut self) -> &mut Atoms<I, A> {
    &mut self.0 .1 .0
  }
  fn edges(&self) -> &Edges<I, E> {
    &self.0 .1 .1
  }
  fn edges_mut(&mut self) -> &mut Edges<I, E> {
    &mut self.0 .1 .1
  }

  /// Obtains reference to vertex value.
  pub fn vertex(&self, index: &I) -> Option<&V> {
    match &self.vertices().get(index)?.value {
      Some(s) => Some(s),
      None => None,
    }
  }

  /// Obtains reference to atom value.
  pub fn atom(&self, index: &I) -> Option<&(I, A)> {
    match &self.atoms().get(index)?.value {
      Some(s) => self.vertices().get(&s.0).and(Some(s)),
      None => None,
    }
  }

  /// Obtains reference to edge value.
  pub fn edge(&self, index: &I) -> Option<&(I, I, E)> {
    match &self.edges().get(index)?.value {
      Some(s) => self.vertices().get(&s.0).and(self.vertices().get(&s.1)).and(Some(s)),
      None => None,
    }
  }
}
