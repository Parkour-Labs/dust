//! A last-writer-win element map.

use derive_more::{AsMut, AsRef, From, Into};
use std::collections::HashMap;

use super::Register;
use crate::joinable::{Clock, Index, Newtype, State};

/// A last-writer-win element map.
///
/// - [`Map`] is an instance of [`State`] space.
/// - [`Map`] is an instance of [`Joinable`] state space.
/// - [`Map`] is an instance of [`DeltaJoinable`] state space.
/// - [`Map`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(Debug, From, Into, AsRef, AsMut)]
pub struct Map<I: Index, T: Ord> {
  pub(crate) inner: HashMap<I, Register<Option<T>>>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl<I: Index, T: Ord> Newtype for Map<I, T> {
  type Inner = HashMap<I, Register<Option<T>>>;
}

impl<I: Index, T: Ord> Default for Map<I, T> {
  fn default() -> Self {
    Self::initial()
  }
}

impl<I: Index, T: Ord> Map<I, T> {
  /// Creates an empty map.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Obtains reference to element.
  pub fn get(&self, index: &I) -> Option<&T> {
    self.inner.get(index)?.value().as_ref()
  }
  /// Makes modification of element.
  pub fn action(clock: Clock, index: I, value: Option<T>) -> <Self as State>::Action {
    HashMap::from([(index, Register::action(clock, value))])
  }
}
