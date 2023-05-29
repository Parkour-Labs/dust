use super::*;

type Inner<I> = HashMap<I, u64>;
type Action<I> = Vec<(I, u64)>;

/// A grow-only counter.
///
/// - [Counter] is an instance of [State] space.
/// - [Counter] is an instance of [Joinable] state space.
/// - [Counter] is an instance of [DeltaJoinable] state space.
/// - [Counter] is an instance of [GammaJoinable] state space.
#[derive(Clone, PartialEq, Eq)]
pub struct Counter<I: Copy + Ord + Hash>(Inner<I>);

impl<I: Copy + Ord + Hash> Counter<I> {
  /// Creates a zero counter.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Obtains value.
  pub fn get(&self) -> u64 {
    self.0.values().sum()
  }
  /// Makes increment.
  pub fn make_mod(&self, index: I, increment: u64) -> Action<I> {
    let value = self.0.get(&index).unwrap_or(&0) + increment;
    vec![(index, value)]
  }
}

// -----------------------------------------------------------------------------
// Boilerplate for transporting trait instances.
// -----------------------------------------------------------------------------

impl<I: Copy + Ord + Hash> Default for Counter<I> {
  fn default() -> Self {
    Self::initial()
  }
}

impl<I: Copy + Ord + Hash> State<Action<I>> for Counter<I> {
  fn initial() -> Self {
    Self(Inner::<I>::initial())
  }
  fn apply(s: Self, a: &Action<I>) -> Self {
    Self(Inner::<I>::apply(s.0, a))
  }
  fn id() -> Action<I> {
    Inner::<I>::id()
  }
  fn comp(a: Action<I>, b: Action<I>) -> Action<I> {
    Inner::<I>::comp(a, b)
  }
}

impl<I: Copy + Ord + Hash> Joinable<Action<I>> for Counter<I> {
  fn preq(s: &Self, t: &Self) -> bool {
    Inner::<I>::preq(&s.0, &t.0)
  }
  fn join(s: Self, t: Self) -> Self {
    Self(Inner::<I>::join(s.0, t.0))
  }
}

impl<I: Copy + Ord + Hash> DeltaJoinable<Action<I>> for Counter<I> {
  fn delta_join(s: Self, a: &Action<I>, b: &Action<I>) -> Self {
    Self(Inner::<I>::delta_join(s.0, a, b))
  }
}

impl<I: Copy + Ord + Hash> GammaJoinable<Action<I>> for Counter<I> {
  fn gamma_join(s: Self, a: &Action<I>) -> Self {
    Self(Inner::<I>::gamma_join(s.0, a))
  }
}
