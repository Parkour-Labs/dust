//! An *observable* and *persistent* last-writer-win register.

use std::marker::PhantomData;

use rusqlite::Transaction;
use serde::{de::DeserializeOwned, ser::Serialize};

use crate::joinable::{Clock, Minimum};
use crate::observable::{
  Events, ObservablePersistentGammaJoinable, ObservablePersistentJoinable, ObservablePersistentState, Port,
};
use crate::persistent::{crdt as pcrdt, PersistentJoinable, PersistentState};

/// An *observable* and *persistent* last-writer-win register.
#[derive(Debug, Clone)]
pub struct Register<T: Minimum + Clone + Serialize + DeserializeOwned, E: Events<T>> {
  inner: pcrdt::Register<T>,
  subscriptions: Vec<Port>,
  _events: PhantomData<E>,
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned, E: Events<T>> Register<T, E> {
  /// Creates or loads data.
  pub fn new(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    Self { inner: pcrdt::Register::new(txn, collection, name), subscriptions: Vec::new(), _events: Default::default() }
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
  pub fn subscribe(&mut self, _txn: &mut Transaction, ctx: &mut E, port: Port) {
    self.subscriptions.push(port);
    ctx.push(port, self.value().clone());
  }

  /// Removes observer.
  pub fn unsubscribe(&mut self, port: Port) {
    self.subscriptions.retain(|&x| x != port);
  }

  fn notifies(&self, ctx: &mut E) {
    for &port in &self.subscriptions {
      ctx.push(port, self.value().clone());
    }
  }
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned, E: Events<T>> ObservablePersistentState for Register<T, E> {
  type State = <pcrdt::Register<T> as PersistentState>::State;
  type Action = <pcrdt::Register<T> as PersistentState>::Action;
  type Transaction<'a> = Transaction<'a>;
  type Context<'a> = E;

  fn initial(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    Self::new(txn, collection, name)
  }

  fn apply(&mut self, txn: &mut Transaction, ctx: &mut E, a: Self::Action) {
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

impl<T: Minimum + Clone + Serialize + DeserializeOwned, E: Events<T>> ObservablePersistentJoinable for Register<T, E> {
  fn preq(&mut self, txn: &mut Transaction, _ctx: &mut E, t: &Self::State) -> bool {
    self.inner.preq(txn, t)
  }

  fn join(&mut self, txn: &mut Transaction, ctx: &mut E, t: Self::State) {
    self.inner.join(txn, t);
    self.notifies(ctx);
  }
}

impl<T: Minimum + Clone + Serialize + DeserializeOwned, E: Events<T>> ObservablePersistentGammaJoinable
  for Register<T, E>
{
}
