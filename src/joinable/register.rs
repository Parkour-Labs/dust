use super::*;

/// Total order with a minimum element.
///
/// Implementation should satisfy the following properties:
///
/// - `(T, ≤)` is totally ordered set
/// - `∀ t ∈ T, min() ≤ t`
pub trait OrdMin: Ord {
  fn minimum() -> Self;
}

/// Newtype for time stamps.
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Clock(u64);

/// [Clock] is an instance of [OrdMin].
impl OrdMin for Clock {
  fn minimum() -> Self {
    Self(u64::MIN)
  }
}

/// A last-writer-win register.
///
/// - [Register] is an instance of [OrdMin].
/// - [Register] is an instance of [Basic] state space.
/// - [Register] is an instance of [Joinable] state space.
/// - [Register] is an instance of [DeltaJoinable] state space.
/// - [Register] is an instance of [GammaJoinable] state space.
#[derive(Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct Register<T: Clone + OrdMin> {
  pub clock: Clock,
  pub value: T,
}

impl<T: Clone + OrdMin> OrdMin for Register<T> {
  fn minimum() -> Self {
    Register {
      clock: Clock::minimum(),
      value: T::minimum(),
    }
  }
}

impl<T: Clone + OrdMin> Basic<Register<T>> for Register<T> {
  fn apply(s: Register<T>, a: &Register<T>) -> Register<T> {
    s.max(a.clone())
  }
  fn id() -> Register<T> {
    Self::minimum()
  }
  fn comp(a: Register<T>, b: Register<T>) -> Register<T> {
    a.max(b)
  }
}

impl<T: Clone + OrdMin> Joinable<Register<T>> for Register<T> {
  fn preq(s: &Register<T>, t: &Register<T>) -> bool {
    s <= t
  }
  fn join(s: Register<T>, t: Register<T>) -> Register<T> {
    s.max(t)
  }
}

impl<T: Clone + OrdMin> DeltaJoinable<Register<T>> for Register<T> {
  fn delta_join(s: Register<T>, a: &Register<T>, b: &Register<T>) -> Register<T> {
    s.max(a.clone()).max(b.clone())
  }
}

impl<T: Clone + OrdMin> GammaJoinable<Register<T>> for Register<T> {
  fn gamma_join(s: Register<T>, a: &Register<T>) -> Register<T> {
    s.max(a.clone())
  }
}

/*
impl<T: Clone + OrdMin> Register<T> {
  pub fn clock(&self) -> &Clock {
    &self.clock
  }
  pub fn clock_mut(&mut self) -> &mut Clock {
    &mut self.clock
  }
  pub fn value(&self) -> &T {
    &self.value
  }
  pub fn value_mut(&mut self) -> &mut T {
    &mut self.value
  }
}
*/
