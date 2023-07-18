//! An *observable* last-writer-win register.

use serde::de::DeserializeOwned;
use serde::ser::Serialize;
use std::{cell::Cell, rc::Weak};

use crate::joinable::{crdt as jcrdt, Clock, Minimum, State};
use crate::observable::{impls::dfs, Node, Observable};
use crate::persistent::crdt as pcrdt;

/// An *observable* last-writer-win register.
pub struct Register<T: Minimum + Serialize + DeserializeOwned> {
  inner: Cell<Option<pcrdt::Register<T>>>,
  out: Cell<Vec<Weak<Node>>>,
}

impl<T: Minimum + Serialize + DeserializeOwned> Register<T> {
  /// Loads or creates a minimum register.
  pub fn new<S: pcrdt::RegisterStore<T>>(store: &S, name: &'static str, default: impl FnOnce() -> T) -> Self {
    Self { inner: Cell::new(Some(pcrdt::Register::new(store, name, default))), out: Default::default() }
  }
  /// Makes modification.
  pub fn action(clock: Clock, value: T) -> <jcrdt::Register<T> as State>::Action {
    pcrdt::Register::action(clock, value)
  }
  /// Updates clock and value.
  pub fn apply<S: pcrdt::RegisterStore<T>>(&self, store: &S, action: <jcrdt::Register<T> as State>::Action) {
    let mut inner = self.inner.take().unwrap();
    inner.apply(store, action);
    self.inner.set(Some(inner));
    self.notify();
  }
}

impl<T: Minimum + Serialize + DeserializeOwned> Observable<T> for Register<T> {
  fn register(&self, observer: &Weak<Node>) {
    let mut out = self.out.take();
    out.push(observer.clone());
    self.out.set(out);
  }
  fn notify(&self) {
    for weak in self.out.take() {
      if let Some(v) = weak.upgrade() {
        dfs(&v);
      }
    }
  }
  fn peek(&self) -> T {
    /*
    let inner = self.inner.take().unwrap();
    let res = inner.value().clone();
    self.inner.set(Some(inner));
    res
    */
    todo!()
  }
  fn get(&self, observer: &Weak<Node>) -> T {
    self.register(observer);
    self.peek()
  }
}
