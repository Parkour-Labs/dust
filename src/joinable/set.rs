use super::basic::*;
use super::register::*;
use super::*;

type Inner<I, T> = HashMap<I, Register<Option<T>>>;
type Action<I, T> = Vec<(I, Register<Option<T>>)>;

/// A last-writer-win element set.
///
/// - [Set] is an instance of [State] space.
/// - [Set] is an instance of [Joinable] state space.
/// - [Set] is an instance of [DeltaJoinable] state space.
/// - [Set] is an instance of [GammaJoinable] state space.
#[derive(Clone, PartialEq, Eq)]
pub struct Set<I: Copy + Ord + Hash, T: Clone + Ord>(Inner<I, T>);

impl<I: Copy + Ord + Hash, T: Clone + Ord> Set<I, T> {
  /// Creates an empty set.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Obtains reference to element.
  pub fn get(&self, index: &I) -> Option<&T> {
    match &self.0.get(index)?.get() {
      Some(s) => Some(s),
      None => None,
    }
  }
  /// Makes modification of element.
  pub fn make_mod(index: I, value: Option<T>, clock: Clock) -> Action<I, T> {
    vec![(index, Register::make_mod(value, clock))]
  }
}

// -----------------------------------------------------------------------------
// Boilerplate for transporting trait instances.
// -----------------------------------------------------------------------------

impl<I: Copy + Ord + Hash, T: Clone + Ord> Default for Set<I, T> {
  fn default() -> Self {
    Self::initial()
  }
}

impl<I: Copy + Ord + Hash, T: Clone + Ord> State<Action<I, T>> for Set<I, T> {
  fn initial() -> Self {
    Self(Inner::<I, T>::initial())
  }
  fn apply(s: Self, a: &Action<I, T>) -> Self {
    Self(Inner::<I, T>::apply(s.0, a))
  }
  fn id() -> Action<I, T> {
    Inner::<I, T>::id()
  }
  fn comp(a: Action<I, T>, b: Action<I, T>) -> Action<I, T> {
    Inner::<I, T>::comp(a, b)
  }
}

impl<I: Copy + Ord + Hash, T: Clone + Ord> Joinable<Action<I, T>> for Set<I, T> {
  fn preq(s: &Self, t: &Self) -> bool {
    Inner::<I, T>::preq(&s.0, &t.0)
  }
  fn join(s: Self, t: Self) -> Self {
    Self(Inner::<I, T>::join(s.0, t.0))
  }
}

impl<I: Copy + Ord + Hash, T: Clone + Ord> DeltaJoinable<Action<I, T>> for Set<I, T> {
  fn delta_join(s: Self, a: &Action<I, T>, b: &Action<I, T>) -> Self {
    Self(Inner::<I, T>::delta_join(s.0, a, b))
  }
}

impl<I: Copy + Ord + Hash, T: Clone + Ord> GammaJoinable<Action<I, T>> for Set<I, T> {
  fn gamma_join(s: Self, a: &Action<I, T>) -> Self {
    Self(Inner::<I, T>::gamma_join(s.0, a))
  }
}
