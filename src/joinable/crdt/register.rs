//! A last-writer-win register.

use std::mem::{drop, replace};

use crate::joinable::{Clock, DeltaJoinable, GammaJoinable, Joinable, Minimum, State};

/// A last-writer-win register.
///
/// - [`Register`] is an instance of [`State`] space.
/// - [`Register`] is an instance of [`Joinable`] state space.
/// - [`Register`] is an instance of [`DeltaJoinable`] state space.
/// - [`Register`] is an instance of [`GammaJoinable`] state space.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct Register<T: Clone + Minimum> {
  clock: Clock,
  value: T,
}

impl<T: Clone + Minimum> State for Register<T> {
  type Action = Self;
  fn initial() -> Self {
    Self { clock: Clock::minimum(), value: T::minimum() }
  }
  fn apply(&mut self, a: &Self) {
    drop(replace(self, self.clone().max(a.clone())));
  }
  fn id() -> Self {
    Self { clock: Clock::minimum(), value: T::minimum() }
  }
  fn comp(a: Self, b: Self) -> Self {
    a.max(b)
  }
}

impl<T: Clone + Minimum> Joinable for Register<T> {
  fn preq(&self, t: &Self) -> bool {
    self <= t
  }
  fn join(&mut self, t: Self) {
    drop(replace(self, self.clone().max(t)));
  }
}

impl<T: Clone + Minimum> DeltaJoinable for Register<T> {
  fn delta_join(&mut self, a: &Self, b: &Self) {
    drop(replace(self, self.clone().max(a.clone()).max(b.clone())));
  }
}

impl<T: Clone + Minimum> GammaJoinable for Register<T> {
  fn gamma_join(&mut self, a: &Self) {
    drop(replace(self, self.clone().max(a.clone())));
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
