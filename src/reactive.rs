use std::{
  cell::Cell,
  rc::{Rc, Weak},
};

#[cfg(test)]
mod tests;

#[derive(Default)]
pub struct Node {
  out: Cell<Vec<Weak<Node>>>,
  dirty: Cell<bool>,
  notify: Cell<Option<Box<dyn FnMut()>>>,
}

/// Marks all upstream nodes as `dirty`, triggers upstream `notify` functions
/// and clears all out-edges.
fn dfs(u: &Node) {
  if let false = u.dirty.replace(true) {
    // Pending nightly feature: https://github.com/rust-lang/rust/issues/50186
    let mut option = u.notify.take();
    if let Some(notify) = option.as_mut() {
      notify();
    }
    u.notify.set(option);
    for weak in u.out.take() {
      if let Some(v) = weak.upgrade() {
        dfs(&v);
      }
    }
  }
}

/// Common part of [`Active`] and [`Reactive`].
pub trait Observable<T: Copy> {
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

impl<T: Copy> Observable<T> for Active<T> {
  /// Registers an observer (direct upstream node).
  fn register(&self, observer: &Weak<Node>) {
    let mut out = self.out.take();
    out.push(observer.clone());
    self.out.set(out);
  }
  /// Marks all upstream nodes as `dirty`, triggers upstream `notify` functions
  /// and clears all out-edges.
  fn notify(&self) {
    for weak in self.out.take() {
      if let Some(v) = weak.upgrade() {
        dfs(&v);
      }
    }
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> T {
    self.value.get()
  }
  /// Obtains the current value and calls `self.register(observer)`.
  fn get(&self, observer: &Weak<Node>) -> T {
    self.register(observer);
    self.peek()
  }
}

impl<T: Copy> Active<T> {
  /// Creates a new [`Active`] value.
  pub fn new(value: T) -> Self {
    Self { out: Default::default(), value: Cell::new(value) }
  }
  /// Updates the current value and calls `self.notify()`.
  pub fn set(&self, value: T) {
    self.value.set(value);
    self.notify();
  }
}

/// A [`Reactive`] value is like an [`Active`] value that automatically updates
/// whenever some [`Active`] or [`Reactive`] value it listens on is modified.
#[allow(clippy::type_complexity)]
pub struct Reactive<'a, T: Copy> {
  node: Rc<Node>,
  value: Cell<T>,
  recompute: Cell<Option<Box<dyn FnMut(&Weak<Node>) -> T + 'a>>>,
}

impl<'a, T: Copy> Observable<T> for Reactive<'a, T> {
  /// Registers an observer (direct upstream node).
  fn register(&self, observer: &Weak<Node>) {
    let mut out = self.node.out.take();
    out.push(observer.clone());
    self.node.out.set(out);
  }
  /// Marks all upstream nodes (including `self`) as `dirty`, triggers upstream
  /// `notify` functions and clears all out-edges.
  fn notify(&self) {
    dfs(&self.node);
  }
  /// Obtains the current value without registering any observer.
  fn peek(&self) -> T {
    // If marked `dirty`, recompute and clear the `dirty` flag.
    if let true = self.node.dirty.replace(false) {
      let mut option = self.recompute.take();
      if let Some(recompute) = option.as_mut() {
        self.value.set(recompute(&Rc::downgrade(&self.node)));
      }
      self.recompute.set(option);
    }
    self.value.get()
  }
  /// Obtains the current value and calls `self.register(observer)`.
  fn get(&self, observer: &Weak<Node>) -> T {
    self.register(observer);
    self.peek()
  }
}

impl<'a, T: Copy> Reactive<'a, T> {
  /// Creates a new [`Reactive`] value.
  pub fn new(mut recompute: impl FnMut(&Weak<Node>) -> T + 'a) -> Self {
    let node = Default::default();
    let value = Cell::new(recompute(&Rc::downgrade(&node)));
    Self { node, value, recompute: Cell::new(Some(Box::new(recompute))) }
  }
  /// Updates the recomputation function and calls `self.notify()`.
  /// Note that currently it does **not** clear in-edges that might present.
  #[allow(unused_must_use)]
  pub fn set(&self, recompute: impl FnMut(&Weak<Node>) -> T + 'a) {
    self.recompute.set(Some(Box::new(recompute)));
    self.notify();
  }
}
