//! A last-writer-win element map.

use derive_more::{AsMut, AsRef, From, Into};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::Register;
use crate::joinable::{Clock, Newtype, State};

/// A last-writer-win element map.
///
/// - [`Map`] is an instance of [`State`] space.
/// - [`Map`] is an instance of [`Joinable`] state space.
/// - [`Map`] is an instance of [`DeltaJoinable`] state space.
/// - [`Map`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(Debug, From, Into, AsRef, AsMut, Serialize, Deserialize)]
pub struct ObjectSet<T: Ord> {
  pub(crate) inner: HashMap<u128, Register<Option<T>>>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl<T: Ord> Newtype for ObjectSet<T> {
  type Inner = HashMap<u128, Register<Option<T>>>;
}

impl<T: Ord> ObjectSet<T> {
  /// Creates an empty map.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Creates a map from data.
  pub fn from(inner: HashMap<u128, Register<Option<T>>>) -> Self {
    Self { inner }
  }
  /// Obtains reference to element.
  pub fn get(&self, index: u128) -> Option<&T> {
    self.inner.get(&index)?.value().as_ref()
  }
  /// Makes modification of element.
  pub fn action(clock: Clock, index: u128, value: Option<T>) -> <Self as State>::Action {
    HashMap::from([(index, Register::action(clock, value))])
  }
}

impl<T: Ord> Default for ObjectSet<T> {
  fn default() -> Self {
    Self::initial()
  }
}
