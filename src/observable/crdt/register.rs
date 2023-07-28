//! An *observable* and *persistent* last-writer-win register.

use rusqlite::Transaction;
use serde::{de::DeserializeOwned, ser::Serialize};

use crate::joinable::{Clock, Minimum};
use crate::observable::{Aggregator, ObservableGammaJoinable, ObservableJoinable, ObservableState, Port};
use crate::persistent::{crdt as pcrdt, PersistentJoinable, PersistentState};

/// An *observable* and *persistent* last-writer-win register.
pub struct Register<T: Minimum + Clone + Serialize + DeserializeOwned> {
  inner: pcrdt::Register<T>,
  subscriptions: Vec<Port>,
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned> Register<T> {
  /// Creates or loads data.
  pub fn new(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    Self { inner: pcrdt::Register::new(txn, collection, name), subscriptions: Vec::new() }
  }

  /// Saves data.
  pub fn save(&self, txn: &mut Transaction) {
    self.inner.save(txn)
  }

  /// Obtains clock.
  pub fn clock(&self) -> Clock {
    self.inner.clock()
  }

  /// Obtains value.
  pub fn value(&self) -> &T {
    self.inner.value()
  }

  /// Makes modification.
  pub fn action(clock: Clock, value: T) -> <Self as ObservableState>::Action {
    pcrdt::Register::action(clock, value)
  }

  /// Adds observer.
  pub fn subscribe(&mut self, port: Port) {
    self.subscriptions.push(port);
  }

  /// Removes observer.
  pub fn unsubscribe(&mut self, port: Port) {
    self.subscriptions.retain(|&x| x != port);
  }

  /// Notifies all observers.
  pub fn notifies(&self, ctx: &mut <Self as ObservableState>::Context) {
    for &port in &self.subscriptions {
      ctx.push(port, self.inner.value().clone());
    }
  }
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned> ObservableState for Register<T> {
  type State = <pcrdt::Register<T> as PersistentState>::State;
  type Action = <pcrdt::Register<T> as PersistentState>::Action;
  type Context = Aggregator<T>;

  fn initial(txn: &mut rusqlite::Transaction, collection: &'static str, name: &'static str) -> Self {
    Self::new(txn, collection, name)
  }

  fn apply(&mut self, txn: &mut rusqlite::Transaction, ctx: &mut Self::Context, a: Self::Action) {
    self.inner.apply(txn, a);
    self.notifies(ctx);
  }

  fn id() -> Self::Action {
    pcrdt::Register::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    pcrdt::Register::comp(a, b)
  }
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned> ObservableJoinable for Register<T> {
  fn preq(&mut self, txn: &mut Transaction, _ctx: &mut Self::Context, t: &Self::State) -> bool {
    self.inner.preq(txn, t)
  }

  fn join(&mut self, txn: &mut Transaction, ctx: &mut Self::Context, t: Self::State) {
    self.inner.join(txn, t);
    self.notifies(ctx);
  }
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned> ObservableGammaJoinable for Register<T> {}
