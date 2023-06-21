//! A last-writer-win element set.

use derive_more::{AsMut, AsRef, From, Into};

use super::register::*;
use super::*;

/// A last-writer-win element set.
///
/// - [`Set`] is an instance of [`State`] space.
/// - [`Set`] is an instance of [`Joinable`] state space.
/// - [`Set`] is an instance of [`DeltaJoinable`] state space.
/// - [`Set`] is an instance of [`GammaJoinable`] state space.
#[repr(transparent)]
#[derive(From, Into, AsRef, AsMut)]
pub struct Set<I: Index, T: Clone + Ord> {
  inner: HashMap<I, Register<Option<T>>>,
}

/// Show that this is a newtype (so that related instances can be synthesised).
impl<I: Index, T: Clone + Ord> Newtype for Set<I, T> {
  type Inner = HashMap<I, Register<Option<T>>>;
}

impl<I: Index, T: Clone + Ord> Default for Set<I, T> {
  fn default() -> Self {
    Self::initial()
  }
}

impl<I: Index, T: Clone + Ord> Set<I, T> {
  /// Creates an empty set.
  pub fn new() -> Self {
    Self::initial()
  }
  /// Obtains reference to element.
  pub fn get(&self, index: &I) -> Option<&T> {
    match &self.inner.get(index)?.get() {
      Some(s) => Some(s),
      None => None,
    }
  }
  /// Makes modification of element.
  pub fn make_mod(index: I, value: Option<T>, clock: Clock) -> <Self as State>::Action {
    vec![(index, Register::make_mod(value, clock))]
  }
}
