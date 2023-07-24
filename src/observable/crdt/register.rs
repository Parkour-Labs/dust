//! An *observable* last-writer-win register.

/*
use std::cell::RefCell;
use std::ops::Deref;
use std::{cell::Cell, rc::Weak};

use crate::joinable::{crdt as jcrdt, Clock, Minimum, State};
use crate::observable::{Node, ObservableRef};
use crate::persistent::{crdt as pcrdt, Serde};

/// An *observable* and *persistent* last-writer-win register.
pub struct Register<T: Minimum + Serde> {
  out: Cell<Vec<Weak<Node>>>,
  inner: pcrdt::Register<T>,
}

/*
impl<T: Minimum> Register<T> {
  /// Loads or creates a minimum register.
  pub fn new<S: pcrdt::RegisterStore<T>>(store: &S, name: &'static str, default: impl FnOnce() -> T) -> Self {
    Self { out: Default::default(), inner: RefCell::new(pcrdt::Register::new(store, name, default)) }
  }
  /// Makes modification.
  pub fn action(clock: Clock, value: T) -> <jcrdt::Register<T> as State>::Action {
    jcrdt::Register::action(clock, value)
  }
  /// Updates clock and value.
  pub fn apply<S: pcrdt::RegisterStore<T>>(&self, store: &S, action: <jcrdt::Register<T> as State>::Action) {
    self.inner.borrow_mut().apply(store, action);
    self.notify();
  }
}
*/

pub struct RegisterRef<'a, T: Minimum + Serde> {
  inner: std::cell::Ref<'a, pcrdt::Register<T>>,
}

impl<'a, T: Minimum + Serde> Deref for RegisterRef<'a, T> {
  type Target = T;

  fn deref(&self) -> &Self::Target {
    self.inner.value()
  }
}

impl<T: Minimum + Serde> ObservableRef<T> for Register<T> {
  type Ref<'a> = RegisterRef<'a, T>
  where
    T: 'a,
    Self: 'a;

  fn register(&self, observer: &Weak<Node>) {
    let mut out = self.out.take();
    out.push(observer.clone());
    self.out.set(out);
  }

  fn notify(&self) {
    for weak in self.out.take() {
      if let Some(v) = weak.upgrade() {
        v.notify();
      }
    }
  }

  fn peek(&self) -> Self::Ref<'_> {
    Self::Ref { inner: self.inner.borrow() }
  }

  fn get(&self, observer: &Weak<Node>) -> Self::Ref<'_> {
    self.register(observer);
    self.peek()
  }
}
*/
