//! A last-writer-win register.

use serde::{Deserialize, Serialize};
use std::mem::{drop, replace};

use crate::joinable::{Clock, DeltaJoinable, GammaJoinable, Joinable, Minimum, State};

/// A last-writer-win register.
///
/// - [`Register`] is an instance of [`State`] space.
/// - [`Register`] is an instance of [`Joinable`] state space.
/// - [`Register`] is an instance of [`DeltaJoinable`] state space.
/// - [`Register`] is an instance of [`GammaJoinable`] state space.
#[derive(Debug, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize)]
pub struct Register<T: Minimum> {
  clock: Clock,
  value: T,
}

impl<T: Minimum> Register<T> {
  /// Creates a minimum register.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Creates a register from data.
  pub fn from(clock: Clock, value: T) -> Self {
    Self { clock, value }
  }
  /// Obtains clock.
  pub fn clock(&self) -> Clock {
    self.clock
  }
  /// Obtains value.
  pub fn value(&self) -> &T {
    &self.value
  }
  /// Makes modification.
  pub fn action(clock: Clock, value: T) -> Self {
    Self { clock, value }
  }
}

impl<T: Minimum> State for Register<T> {
  type Action = Self;
  fn initial() -> Self {
    Self { clock: Clock::minimum(), value: T::minimum() }
  }
  fn apply(&mut self, mut a: Self) {
    if self < &mut a {
      drop(replace(self, a));
    }
  }
  fn id() -> Self {
    Self { clock: Clock::minimum(), value: T::minimum() }
  }
  fn comp(a: Self, b: Self) -> Self {
    Ord::max(a, b)
  }
}

impl<T: Minimum> Joinable for Register<T> {
  fn preq(&self, t: &Self) -> bool {
    self <= t
  }
  fn join(&mut self, mut t: Self) {
    if self < &mut t {
      drop(replace(self, t));
    }
  }
}

impl<T: Minimum> DeltaJoinable for Register<T> {
  fn delta_join(&mut self, mut a: Self, mut b: Self) {
    if self < &mut a {
      drop(replace(self, a));
    }
    if self < &mut b {
      drop(replace(self, b));
    }
  }
}

impl<T: Minimum> GammaJoinable for Register<T> {
  fn gamma_join(&mut self, mut a: Self) {
    if self < &mut a {
      drop(replace(self, a));
    }
  }
}

impl<T: Minimum> Default for Register<T> {
  fn default() -> Self {
    Self::initial()
  }
}
