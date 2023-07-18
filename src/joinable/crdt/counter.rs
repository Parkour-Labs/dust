//! A grow-only counter.

use derive_more::{AsMut, AsRef, From, Into};
use std::collections::HashMap;

use crate::joinable::{ByMax, Index, Newtype, State};

/// A grow-only counter.
///
/// - [`Counter`] is an instance of [`State`] space.
/// - [`Counter`] is an instance of [`Joinable`] state space.
/// - [`Counter`] is an instance of [`DeltaJoinable`] state space.
/// - [`Counter`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(Debug, From, Into, AsRef, AsMut)]
pub struct Counter<I: Index> {
  inner: HashMap<I, ByMax<u64>>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl<I: Index> Newtype for Counter<I> {
  type Inner = HashMap<I, ByMax<u64>>;
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
  pub fn action(&self, index: I, increment: u64) -> <Self as State>::Action {
    let value = self.inner.get(&index).map_or(0, |e| e.inner) + increment;
    HashMap::from([(index, value)])
  }
}
