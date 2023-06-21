//! An *observable* last-writer-win register.

use std::{cell::Cell, rc::Weak};

use super::Node;
use crate::joinable::{self, Minimum};

/// An *observable* last-writer-win register.
pub struct Register<T: Clone + Minimum> {
  data: joinable::crdt::register::Register<T>,
  out: Cell<Vec<Weak<Node>>>,
}
