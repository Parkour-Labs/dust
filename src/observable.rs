pub mod crdt;

use rusqlite::Transaction;

pub trait ObservablePersistentState {
  type State;
  type Action;
  type Context;
  fn initial(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self;
  fn apply(&mut self, txn: &mut Transaction, ctx: &mut Self::Context, a: Self::Action);
  fn id() -> Self::Action;
  fn comp(a: Self::Action, b: Self::Action) -> Self::Action;
}

pub trait ObservablePersistentJoinable: ObservablePersistentState {
  fn preq(&mut self, txn: &mut Transaction, ctx: &mut Self::Context, t: &Self::State) -> bool;
  fn join(&mut self, txn: &mut Transaction, ctx: &mut Self::Context, t: Self::State);
}

pub trait ObservablePersistentGammaJoinable: ObservablePersistentJoinable {
  fn gamma_join(&mut self, txn: &mut Transaction, ctx: &mut Self::Context, a: Self::Action) {
    self.apply(txn, ctx, a);
  }
}

pub type Port = u64;

pub enum SetEvent<T> {
  Insert(T),
  Remove(T),
}

pub struct Aggregator<T> {
  events: Vec<(Port, T)>,
}

impl<T> Aggregator<T> {
  pub fn push(&mut self, port: Port, event: T) {
    self.events.push((port, event));
  }
}

#[allow(clippy::from_over_into)]
impl<T> Into<Vec<(Port, T)>> for Aggregator<T> {
  fn into(self) -> Vec<(Port, T)> {
    self.events
  }
}
