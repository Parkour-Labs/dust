//! A *persistent* last-writer-win element map.

/*
use std::collections::HashSet;

use crate::joinable::State;
use crate::joinable::{crdt as jcrdt, Clock, Index};
use crate::persistent::vector_history::{VectorHistory, VectorHistoryStore};
use crate::persistent::Serde;

/// A *persistent* last-writer-win element map.
pub struct Map<I: Index + Serde, T: Ord + Serde>
where
  <jcrdt::Map<I, T> as State>::Action: Serde + Clone,
{
  inner: jcrdt::Map<I, T>,
  loaded: HashSet<I>,
  history: VectorHistory<jcrdt::Map<I, T>>,
  name: &'static str,
}

impl<I: Index + Serde, T: Ord + Serde> Map<I, T>
where
  <jcrdt::Map<I, T> as State>::Action: Serde + Clone,
{
  /// Loads or creates an empty map.
  pub fn new<S: MapStore<I, T>>(store: &S, name: &'static str) -> Self {
    MapStore::init(store, name);
    Self { inner: Default::default(), loaded: HashSet::new(), history: VectorHistory::new(store, name), name }
  }
  /// Loads element.
  pub fn load<S: MapStore<I, T>>(&mut self, store: &S, index: &I) {
    if self.loaded.insert(index.clone()) {
      let (clock, value) = store.get(self.name, index);
      self.inner.inner.insert(index.clone(), jcrdt::Register::from(clock, value));
    }
  }
  /// Unloads element.
  pub fn unload(&mut self, index: &I) {
    self.inner.inner.remove(index);
    self.loaded.remove(index);
  }
  /// Obtains reference to element.
  pub fn get<S: MapStore<I, T>>(&mut self, store: &S, index: &I) -> Option<&T> {
    self.load(store, index);
    self.inner.get(index)
  }
  /// Makes modification of element.
  pub fn action(clock: Clock, index: I, value: Option<T>) -> <jcrdt::Map<I, T> as State>::Action {
    jcrdt::Map::action(clock, index, value)
  }
  /// Updates clock and value.
  pub fn apply<S: MapStore<I, T>>(&mut self, store: &S, action: <jcrdt::Map<I, T> as State>::Action) {
    let indices: Vec<_> = action.keys().cloned().collect();
    for index in &indices {
      self.load(store, index);
    }
    self.inner.apply(action);
    // self.history.push(store, replica, clock, action);
    for index in &indices {
      let elem = self.inner.inner.get(index).unwrap(); // Never panics.
      store.set(self.name, index, (elem.clock(), elem.value()));
    }
  }
}

/// Database interface for [`Map`].
pub trait MapStore<I: Index + Serde, T: Ord + Serde>: VectorHistoryStore<jcrdt::Map<I, T>>
where
  <jcrdt::Map<I, T> as State>::Action: Serde,
{
  fn init(&self, name: &str);
  fn get(&self, name: &str, index: &I) -> (Clock, Option<T>);
  fn set(&self, name: &str, index: &I, data: (Clock, &Option<T>));
}

/// Implementation of [`MapStore`] using SQLite.
impl<'a, I: Index + Serde, T: Ord + Serde> MapStore<I, T> for rusqlite::Transaction<'a>
where
  <jcrdt::Map<I, T> as State>::Action: Serde,
{
  fn init(&self, name: &str) {
    self
      .prepare_cached(&format!(
        "CREATE TABLE IF NOT EXISTS \"{name}\" (index BLOB NOT NULL, clock BLOB NOT NULL, data BLOB NOT NULL) STRICT"
      ))
      .unwrap()
      .execute(())
      .unwrap();
  }

  fn get(&self, name: &str, index: &I) -> (Clock, Option<T>) {
    self
      .prepare_cached(&format!("SELECT clock, data FROM \"{name}\" WHERE index = ?"))
      .unwrap()
      .query_row((postcard::to_allocvec(index).unwrap(),), |row| {
        Ok((Clock::from_be_bytes(row.get(0)?), postcard::from_bytes(row.get_ref(1)?.as_blob()?).unwrap()))
      })
      .unwrap()
  }

  fn set(&self, name: &str, index: &I, data: (Clock, &Option<T>)) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}\" (index, clock, data) VALUES (?, ?, ?)"))
      .unwrap()
      .execute((
        postcard::to_allocvec(index).unwrap(),
        data.0.to_u128().to_be_bytes(),
        postcard::to_allocvec(data.1).unwrap(),
      ))
      .unwrap();
  }
}
*/
