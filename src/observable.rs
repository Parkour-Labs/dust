use std::{
  cell::{Cell, Ref, RefCell, RefMut},
  ops::{Deref, DerefMut},
  rc::{Rc, Weak},
};

pub mod crdt;
pub mod impls;

#[cfg(test)]
mod tests;

#[derive(Default)]
pub struct Node {
  // `Rc` and `Weak` must be used instead of references, since it is impossible
  // to put elements with different lifetimes into the same `Vec`.
  // (It would be possible only if Rust had dependent types.)
  out: Cell<Vec<Weak<Node>>>,
  dirty: Cell<bool>,
  notify: Cell<Option<Box<dyn FnMut() + 'static>>>,
}

pub trait Observable<T> {
  fn register(&self, observer: &Weak<Node>);
  fn notify(&self);
  fn peek(&self) -> T;
  fn get(&self, observer: &Weak<Node>) -> T;
}

pub trait ObservableRef<T> {
  fn register(&self, observer: &Weak<Node>);
  fn notify(&self);
  fn peek(&self) -> Ref<'_, T>;
  fn get(&self, observer: &Weak<Node>) -> Ref<'_, T>;
}

/// An [`Active`] value can be listened on.
///
/// This is intended for "small" values for which *value semantics* are suitable
/// (copy is cheap, no interior mutability). This is also due to
/// [a restriction](https://users.rust-lang.org/t/why-does-cell-require-copy-instead-of-clone/5769) of [`Cell`].
pub struct Active<T: Copy> {
  out: Cell<Vec<Weak<Node>>>,
  value: Cell<T>,
}

/// An [`ActiveRef`] reference can be listened on.
///
/// This is intended for "large" values for which *reference semantics* are
/// suitable (copy is expensive, possible interior mutability). It panics if
/// value is being mutated while a read reference is held.
pub struct ActiveRef<T> {
  out: Cell<Vec<Weak<Node>>>,
  value: RefCell<T>,
}

/// A [`Reactive`] value is like an [`Active`] value that automatically updates
/// whenever some [`Observable`] it listens on is modified.
///
/// This is intended for "small" values for which *value semantics* are suitable
/// (copy is cheap, no interior mutability). This is also due to
/// [a restriction](https://users.rust-lang.org/t/why-does-cell-require-copy-instead-of-clone/5769) of [`Cell`].
#[allow(clippy::type_complexity)]
pub struct Reactive<'a, T: Copy> {
  node: Rc<Node>,
  value: Cell<T>,
  recompute: Cell<Option<Box<dyn FnMut(&Weak<Node>) -> T + 'a>>>,
}

/// A [`ReactiveRef`] reference is like an [`ActiveRef`] reference that
/// automatically updates whenever some [`Observable`] it listens on is modified.
///
/// This is intended for "large" values for which *reference semantics* are
/// suitable (copy is expensive, possible interior mutability). It panics if
/// value is being mutated while a read reference is held.
#[allow(clippy::type_complexity)]
pub struct ReactiveRef<'a, T> {
  node: Rc<Node>,
  value: RefCell<T>,
  recompute: Cell<Option<Box<dyn FnMut(&Weak<Node>) -> T + 'a>>>,
}

/// A mutable reference obtained from [`ActiveRef`] which notifies the origin
/// when dropped.
pub struct NotifiedRefMut<'a, T> {
  inner: Option<RefMut<'a, T>>,
  origin: &'a ActiveRef<T>,
}

impl<'a, T> Drop for NotifiedRefMut<'a, T> {
  fn drop(&mut self) {
    std::mem::drop(self.inner.take());
    self.origin.notify();
  }
}

impl<'a, T> Deref for NotifiedRefMut<'a, T> {
  type Target = T;
  fn deref(&self) -> &T {
    self.inner.as_ref().unwrap()
  }
}

impl<'a, T> DerefMut for NotifiedRefMut<'a, T> {
  fn deref_mut(&mut self) -> &mut T {
    self.inner.as_mut().unwrap()
  }
}
