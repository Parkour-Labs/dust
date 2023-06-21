use super::basic::*;
use super::*;

/// A last-writer-win register.
///
/// - [`Register`] is an instance of [`State`] space.
/// - [`Register`] is an instance of [`Joinable`] state space.
/// - [`Register`] is an instance of [`DeltaJoinable`] state space.
/// - [`Register`] is an instance of [`GammaJoinable`] state space.
#[derive(Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct Register<T: Clone + Minimum> {
  clock: Clock,
  value: T,
}

impl<T: Clone + Minimum> State for Register<T> {
  type Action = Self;
  fn initial() -> Self {
    Self { clock: Clock::minimum(), value: T::minimum() }
  }
  fn apply(s: Self, a: &Self) -> Self {
    s.max(a.clone())
  }
  fn id() -> Self {
    Self { clock: Clock::minimum(), value: T::minimum() }
  }
  fn comp(a: Self, b: Self) -> Self {
    a.max(b)
  }
}

impl<T: Clone + Minimum> Joinable for Register<T> {
  fn preq(s: &Self, t: &Self) -> bool {
    s <= t
  }
  fn join(s: Self, t: Self) -> Self {
    s.max(t)
  }
}

impl<T: Clone + Minimum> DeltaJoinable for Register<T> {
  fn delta_join(s: Self, a: &Self, b: &Self) -> Self {
    s.max(a.clone()).max(b.clone())
  }
}

impl<T: Clone + Minimum> GammaJoinable for Register<T> {
  fn gamma_join(s: Self, a: &Self) -> Self {
    s.max(a.clone())
  }
}

impl<T: Clone + Minimum> Default for Register<T> {
  fn default() -> Self {
    Self::initial()
  }
}

impl<T: Clone + Minimum> Register<T> {
  /// Creates a minimum register.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Obtains value.
  pub fn get(&self) -> &T {
    &self.value
  }
  /// Makes modification.
  pub fn make_mod(value: T, clock: Clock) -> Self {
    Self { clock, value }
  }
}
