//! A grow-only counter.

use derive_more::{AsMut, AsRef, From, Into};

use super::*;

/// A grow-only counter.
///
/// - [`Counter`] is an instance of [`State`] space.
/// - [`Counter`] is an instance of [`Joinable`] state space.
/// - [`Counter`] is an instance of [`DeltaJoinable`] state space.
/// - [`Counter`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(From, Into, AsRef, AsMut)]
pub struct Counter<I: Index> {
  inner: HashMap<I, ByMinimum<u64>>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl<I: Index> Newtype for Counter<I> {
  type Inner = HashMap<I, ByMinimum<u64>>;
}

impl<I: Index> Default for Counter<I> {
  fn default() -> Self {
    Self::initial()
  }
}

impl<I: Index> Counter<I> {
  /// Creates a zero counter.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Obtains value.
  pub fn get(&self) -> u64 {
    self.inner.values().map(|e| e.inner).sum()
  }
  /// Makes increment.
  pub fn make_mod(&self, index: I, increment: u64) -> <Self as State>::Action {
    vec![(index, self.inner.get(&index).map_or(0, |e| e.inner) + increment)]
  }
}
