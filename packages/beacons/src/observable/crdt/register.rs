//! An *observable* and *persistent* last-writer-win register.

use rusqlite::Transaction;
use serde::{de::DeserializeOwned, ser::Serialize};

use crate::joinable::{Clock, Minimum};
use crate::observable::{
  Aggregator, ObservablePersistentGammaJoinable, ObservablePersistentJoinable, ObservablePersistentState, Port,
};
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
  pub fn action(clock: Clock, value: T) -> <Self as ObservablePersistentState>::Action {
    pcrdt::Register::action(clock, value)
  }

  /// Adds observer.
  pub fn subscribe(&mut self, _txn: &mut Transaction, ctx: &mut Aggregator<T>, port: Port) {
    self.subscriptions.push(port);
    ctx.push(port, self.value().clone());
  }

  /// Removes observer.
  pub fn unsubscribe(&mut self, port: Port) {
    self.subscriptions.retain(|&x| x != port);
  }

  fn notifies(&self, ctx: &mut Aggregator<T>) {
    for &port in &self.subscriptions {
      ctx.push(port, self.value().clone());
    }
  }
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned> ObservablePersistentState for Register<T> {
  type State = <pcrdt::Register<T> as PersistentState>::State;
  type Action = <pcrdt::Register<T> as PersistentState>::Action;
  type Transaction<'a> = Transaction<'a>;
  type Context<'a> = Aggregator<T>;

  fn initial(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    Self::new(txn, collection, name)
  }

  fn apply(&mut self, txn: &mut Transaction, ctx: &mut Aggregator<T>, a: Self::Action) {
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

impl<T: Minimum + Clone + Serialize + DeserializeOwned> ObservablePersistentJoinable for Register<T> {
  fn preq(&mut self, txn: &mut Transaction, _ctx: &mut Aggregator<T>, t: &Self::State) -> bool {
    self.inner.preq(txn, t)
  }

  fn join(&mut self, txn: &mut Transaction, ctx: &mut Aggregator<T>, t: Self::State) {
    self.inner.join(txn, t);
    self.notifies(ctx);
  }
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned> ObservablePersistentGammaJoinable for Register<T> {}
