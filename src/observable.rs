use std::{
  cell::{Cell, RefCell, RefMut},
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
  out: Cell<Vec<Weak<Node>>>,
  notified: Cell<bool>,
}

pub trait Observable<T> {
  fn register(&self, observer: &Weak<Node>);
  fn notify(&self);
  fn peek(&self) -> T;
  fn get(&self, observer: &Weak<Node>) -> T;
}

pub trait ObservableRef<T> {
  type Ref<'a>: Deref<Target = T>
  where
    T: 'a,
    Self: 'a;

  fn register(&self, observer: &Weak<Node>);
  fn notify(&self);
  fn peek(&self) -> Self::Ref<'_>;
  fn get(&self, observer: &Weak<Node>) -> Self::Ref<'_>;
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

/// A mutable reference obtained from [`ObservableRef`] which notifies the
/// origin when dropped.
pub struct NotifiedRefMut<'a, T, U: ObservableRef<T>> {
  inner: Option<RefMut<'a, T>>,
  origin: &'a U,
}

impl<'a, T, U: ObservableRef<T>> Drop for NotifiedRefMut<'a, T, U> {
  fn drop(&mut self) {
    std::mem::drop(self.inner.take());
    self.origin.notify();
  }
}

impl<'a, T, U: ObservableRef<T>> Deref for NotifiedRefMut<'a, T, U> {
  type Target = T;
  fn deref(&self) -> &T {
    self.inner.as_ref().unwrap()
  }
}

impl<'a, T, U: ObservableRef<T>> DerefMut for NotifiedRefMut<'a, T, U> {
  fn deref_mut(&mut self) -> &mut T {
    self.inner.as_mut().unwrap()
  }
}
