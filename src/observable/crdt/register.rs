//! An *observable* last-writer-win register.

use super::Active;
use crate::joinable::{self, Minimum};

/// An *observable* last-writer-win register.
pub struct Register<T: Clone + Minimum> {
  data: joinable::crdt::register::Register<T>,
  source: Active<()>,
}
