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
#[derive(Debug, Clone, From, Into, AsRef, AsMut, Serialize, Deserialize)]
pub struct ObjectSet {
  pub(crate) inner: HashMap<u128, Register<Option<Vec<u8>>>>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl Newtype for ObjectSet {
  type Inner = HashMap<u128, Register<Option<Vec<u8>>>>;
}

impl ObjectSet {
  /// Creates an empty map.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Creates a map from data.
  pub fn from(inner: HashMap<u128, Register<Option<Vec<u8>>>>) -> Self {
    Self { inner }
  }
  /// Obtains reference to element.
  pub fn get(&self, id: u128) -> Option<&[u8]> {
    match self.inner.get(&id)?.value() {
      None => None,
      Some(value) => Some(value.as_ref()),
    }
  }
  /// Makes modification of element.
  pub fn action(clock: Clock, id: u128, value: Option<Vec<u8>>) -> <Self as State>::Action {
    HashMap::from([(id, Register::action(clock, value))])
  }
}

impl Default for ObjectSet {
  fn default() -> Self {
    Self::initial()
  }
}
