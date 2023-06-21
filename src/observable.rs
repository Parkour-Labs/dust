use std::{
  cell::Cell,
  rc::{Rc, Weak},
};

pub mod crdt;
pub mod impls;

#[cfg(test)]
mod tests;

#[derive(Default)]
pub struct Node {
  out: Cell<Vec<Weak<Node>>>,
  dirty: Cell<bool>,
  notify: Cell<Option<Box<dyn FnMut()>>>,
}

/// Common part of [`Active`] and [`Reactive`].
pub trait Observable<T> {
  fn register(&self, observer: &Weak<Node>);
  fn notify(&self);
  fn peek(&self) -> T;
  fn get(&self, observer: &Weak<Node>) -> T;
}

/// An [`Active`] value can be listened on.
pub struct Active<T: Copy> {
  out: Cell<Vec<Weak<Node>>>,
  value: Cell<T>,
}

/// A [`Reactive`] value is like an [`Active`] value that automatically updates
/// whenever some [`Active`] or [`Reactive`] value it listens on is modified.
#[allow(clippy::type_complexity)]
pub struct Reactive<'a, T: Copy> {
  node: Rc<Node>,
  value: Cell<T>,
  recompute: Cell<Option<Box<dyn FnMut(&Weak<Node>) -> T + 'a>>>,
}
