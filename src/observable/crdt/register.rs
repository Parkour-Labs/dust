//! An *observable* last-writer-win register.

use std::{cell::Cell, rc::Weak};

use crate::joinable::{crdt as jcrdt, DeltaJoinable, GammaJoinable, Joinable};
use crate::joinable::{Minimum, State};
use crate::observable::Node;
use crate::observable::Observable;

/// An *observable* last-writer-win register.
pub struct Register<T: Clone + Minimum> {
  data: jcrdt::Register<T>,
  out: Cell<Vec<Weak<Node>>>,
}

impl<T: Clone + Minimum> State for Register<T> {
  type Action = <jcrdt::Register<T> as State>::Action;
  fn initial() -> Self {
    Self { data: jcrdt::Register::initial(), out: Default::default() }
  }
  fn apply(&mut self, a: &Self::Action) {
    jcrdt::Register::apply(&mut self.data, a)
  }
  fn id() -> Self::Action {
    jcrdt::Register::id()
  }
  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    jcrdt::Register::comp(a, b)
  }
}

impl<T: Clone + Minimum> Joinable for Register<T> {
  fn preq(&self, t: &Self) -> bool {
    jcrdt::Register::preq(&self.data, &t.data)
  }
  fn join(&mut self, t: Self) {
    jcrdt::Register::join(&mut self.data, t.data)
  }
}

impl<T: Clone + Minimum> DeltaJoinable for Register<T> {
  fn delta_join(&mut self, a: &Self::Action, b: &Self::Action) {
    jcrdt::Register::delta_join(&mut self.data, a, b)
  }
}

impl<T: Clone + Minimum> GammaJoinable for Register<T> {
  fn gamma_join(&mut self, a: &Self::Action) {
    self.apply(a)
  }
}

impl<T: Clone + Minimum> Observable<T> for Register<T> {
  fn register(&self, observer: &Weak<Node>) {}
  fn notify(&self) {
    todo!()
  }
  fn peek(&self) -> T {
    todo!()
  }
  fn get(&self, observer: &Weak<Node>) -> T {
    todo!()
  }
}
