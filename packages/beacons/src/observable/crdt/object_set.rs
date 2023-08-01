//! An *observable* and *persistent* last-writer-win element map.

use rusqlite::Transaction;
use std::collections::hash_map::Entry;
use std::collections::HashMap;

use crate::joinable::Clock;
use crate::observable::{
  Aggregator, ObservablePersistentGammaJoinable, ObservablePersistentJoinable, ObservablePersistentState, Port,
};
use crate::persistent::{crdt as pcrdt, PersistentJoinable, PersistentState};

/// An *observable* and *persistent* last-writer-win element map.
#[derive(Debug, Clone)]
pub struct ObjectSet {
  inner: pcrdt::ObjectSet,
  subscriptions: HashMap<u128, Vec<Port>>,
}

impl ObjectSet {
  /// Creates or loads data.
  pub fn new(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    Self { inner: pcrdt::ObjectSet::new(txn, collection, name), subscriptions: HashMap::new() }
  }

  /// Loads element.
  pub fn load(&mut self, txn: &mut Transaction, id: u128) {
    self.inner.load(txn, id)
  }

  /// Saves loaded element.
  pub fn save(&self, txn: &mut Transaction, id: u128) {
    self.inner.save(txn, id)
  }

  /// Unloads element.
  pub fn unload(&mut self, id: u128) {
    self.inner.unload(id)
  }

  /// Obtains reference to element.
  pub fn get(&mut self, txn: &mut Transaction, id: u128) -> Option<&[u8]> {
    self.inner.get(txn, id)
  }

  /// Makes modification of element.
  pub fn action(clock: Clock, id: u128, value: Option<Vec<u8>>) -> <Self as ObservablePersistentState>::Action {
    pcrdt::ObjectSet::action(clock, id, value)
  }

  /// Frees memory.
  pub fn free(&mut self) {
    self.inner.free()
  }

  /// Adds observer.
  pub fn subscribe(&mut self, txn: &mut Transaction, ctx: &mut Aggregator<Option<Vec<u8>>>, id: u128, port: Port) {
    self.subscriptions.entry(id).or_default().push(port);
    ctx.push(port, self.get(txn, id).map(Vec::from));
  }

  /// Removes observer.
  pub fn unsubscribe(&mut self, id: u128, port: Port) {
    if let Entry::Occupied(mut entry) = self.subscriptions.entry(id) {
      entry.get_mut().retain(|&x| x != port);
      if entry.get().is_empty() {
        entry.remove();
      }
    }
  }

  fn notifies(&mut self, txn: &mut Transaction, ctx: &mut Aggregator<Option<Vec<u8>>>, ids: &[u128]) {
    for &id in ids {
      if let Some(ports) = self.subscriptions.get(&id) {
        for &port in ports {
          ctx.push(port, self.inner.get(txn, id).map(Vec::from));
        }
      }
    }
  }
}

impl ObservablePersistentState for ObjectSet {
  type State = <pcrdt::ObjectSet as PersistentState>::State;
  type Action = <pcrdt::ObjectSet as PersistentState>::Action;
  type Transaction<'a> = Transaction<'a>;
  type Context<'a> = Aggregator<Option<Vec<u8>>>;

  fn initial(txn: &mut Transaction, collection: &'static str, name: &'static str) -> Self {
    Self::new(txn, collection, name)
  }

  fn apply(&mut self, txn: &mut Transaction, ctx: &mut Aggregator<Option<Vec<u8>>>, a: Self::Action) {
    let ids: Vec<u128> = a.keys().copied().collect();
    self.inner.apply(txn, a);
    self.notifies(txn, ctx, &ids);
  }

  fn id() -> Self::Action {
    pcrdt::ObjectSet::id()
  }

  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    pcrdt::ObjectSet::comp(a, b)
  }
}

impl ObservablePersistentJoinable for ObjectSet {
  fn preq(&mut self, txn: &mut Transaction, _ctx: &mut Aggregator<Option<Vec<u8>>>, t: &Self::State) -> bool {
    self.inner.preq(txn, t)
  }

  fn join(&mut self, txn: &mut Transaction, ctx: &mut Aggregator<Option<Vec<u8>>>, t: Self::State) {
    let ids: Vec<u128> = t.inner.keys().copied().collect();
    self.inner.join(txn, t);
    self.notifies(txn, ctx, &ids);
  }
}

impl ObservablePersistentGammaJoinable for ObjectSet {}