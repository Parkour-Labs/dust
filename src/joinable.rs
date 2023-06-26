//! To understand the code below, please refer to the
//! [core theory](docs/state-management-theory.pdf).
//!
//! Wrapper types like [`ByMax`] and [`ByMin`] are required here to prevent
//! clashes between multiple typeclass instances (trait implementations).
//! This technique is covered [in the Rust book](https://doc.rust-lang.org/book/ch19-03-advanced-traits.html#using-the-newtype-pattern-to-implement-external-traits-on-external-types),
//! and is also a common practice in Lean Mathlib (e.g. pairs are partially
//! ordered by default, but the `Lex` type constructor creates a new type from
//! the pair type which is lexicographically ordered).

use rand::Rng;
use std::cmp::Eq;
use std::collections::{HashMap, HashSet};
use std::hash::Hash;
use std::time::{SystemTime, UNIX_EPOCH};

pub mod crdt;
pub mod impls;

#[cfg(test)]
mod tests;

/// Trait alias for newtypes.
pub trait Newtype: From<Self::Inner> + Into<Self::Inner> + AsRef<Self::Inner> + AsMut<Self::Inner> {
  type Inner;
}

/// Trait alias for hash map indices.
pub trait Index: Copy + Eq + Hash {}
impl<T: Copy + Eq + Hash> Index for T {}

/// An instance of [`State`] is a "proof" that `(Self, Action)` forms a **state space**.
///
/// Implementation should satisfy the following properties
/// (where return values refer to the in-out parameters):
///
/// - `∀ s ∈ Self, apply(s, id()) == s`
/// - `∀ s ∈ Self, ∀ a b ∈ Action, apply(apply(s, a), b) == apply(s, comp(a, b))`
pub trait State {
  type Action;
  fn initial() -> Self;
  fn apply(&mut self, a: &Self::Action);
  fn id() -> Self::Action;
  fn comp(a: Self::Action, b: Self::Action) -> Self::Action;
}

/// An instance of [`Joinable`] is a "proof" that `(Self, Action)` forms a **joinable state space**.
///
/// Implementation should satisfy the following properties
/// (where return values refer to the in-out parameters):
///
/// - `(Self, ≼)` is semilattice
/// - `∀ s ∈ Self, initial() ≼ s`
/// - `∀ s ∈ Self, ∀ a ∈ Action, s ≼ apply(s, a)`
/// - `∀ s t ∈ Self, join(s, t)` is the least upper bound of `s` and `t`
///
/// in addition to the properties of state spaces.
pub trait Joinable: State {
  fn preq(&self, t: &Self) -> bool;
  fn join(&mut self, t: Self);
}

/// An instance of [`DeltaJoinable`] is a "proof" that `(Self, Action)` forms a **Δ-joinable state space**.
///
/// Implementation should satisfy the following properties
/// (where return values refer to the in-out parameters):
///
/// - `∀ s ∈ Self, ∀ a b ∈ Action, delta_join(s, a, b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
pub trait DeltaJoinable: Joinable {
  fn delta_join(&mut self, a: &Self::Action, b: &Self::Action);
}

/// An instance of [`GammaJoinable`] is a "proof" that `(Self, Action)` forms a **Γ-joinable state space**.
///
/// Implementation should satisfy the following properties
/// (where return values refer to the in-out parameters):
///
/// - `∀ s ∈ Self, ∀ a b ∈ Action, gamma_join(apply(s, a), b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
pub trait GammaJoinable: Joinable {
  fn gamma_join(&mut self, a: &Self::Action);
}

/// An instance of [`Restorable`] is a "proof" that `(Self, Action)` forms a **restorable state space**.
///
/// Implementation should satisfy the following properties
/// (where return values refer to the in-out parameters):
///
/// - `∀ s ∈ Self, ∀ a ∈ Action, restore(apply(s, a), mark(s)) = (s, a)`
///
/// in addition to the properties of state spaces.
pub trait Restorable: State {
  type RestorePoint;
  fn mark(&self) -> Self::RestorePoint;
  fn restore(&mut self, m: Self::RestorePoint) -> Self::Action;
}

/// Total order with a minimum element.
///
/// Implementation should satisfy the following properties:
///
/// - `(T, ≤)` is totally ordered set
/// - `∀ t ∈ T, minimum() ≤ t`
pub trait Minimum: Ord {
  fn minimum() -> Self;
}

/// Total order with a maximum element.
///
/// Implementation should satisfy the following properties:
///
/// - `(T, ≤)` is totally ordered set
/// - `∀ t ∈ T, t ≤ maximum()`
pub trait Maximum: Ord {
  fn maximum() -> Self;
}

/// [`ByMax`] is used to indicate that we wish to implement [`Joinable`]
/// on a type `T` by defining *actions* as *taking maximums*.
#[repr(transparent)]
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct ByMax<T: Clone + Minimum> {
  pub inner: T,
}

/// [`ByMin`] is used to indicate that we wish to implement [`Joinable`]
/// on a type `T` by defining *actions* as *taking minimums*.
#[repr(transparent)]
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct ByMin<T: Clone + Maximum> {
  pub inner: T,
}

/// Newtype for identifiers.
#[repr(transparent)]
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Id {
  inner: u128,
}

impl From<u128> for Id {
  fn from(value: u128) -> Self {
    Self { inner: value }
  }
}

impl From<Id> for u128 {
  fn from(value: Id) -> Self {
    value.inner
  }
}

/// Implementation of the [hybrid logical clock](https://muratbuffalo.blogspot.com/2014/07/hybrid-logical-clocks.html)
/// enhanced with a random part (so that it serves as a unique identifier as well).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Clock {
  measured: u64,
  count: u32,
  random: u32,
}

impl Clock {
  /// Constructs an HLC from current system time and an optional list of predecessors.
  /// The `random` field will be, well, randomly assigned.
  pub fn new(preds: &[Clock]) -> Self {
    let measured = match SystemTime::now().duration_since(UNIX_EPOCH) {
      Ok(n) => n.as_secs(),
      Err(_) => 0,
    };
    let mut pair = (measured, 0);
    for pred in preds {
      let curr = if pred.count == u32::MAX { (pred.measured + 1, 0) } else { (pred.measured, pred.count + 1) };
      pair = pair.max(curr);
    }
    Self { measured: pair.0, count: pair.1, random: rand::thread_rng().gen() }
  }
}

impl From<Id> for Clock {
  fn from(value: Id) -> Self {
    let measured = (value.inner >> 64) as u64;
    let count = (value.inner >> 32) as u32;
    let random = value.inner as u32;
    Self { measured, count, random }
  }
}

impl From<Clock> for Id {
  fn from(value: Clock) -> Self {
    Self { inner: ((value.measured as u128) << 64) ^ ((value.count as u128) << 32) ^ (value.random as u128) }
  }
}
