use rusqlite::OptionalExtension;
use serde::{de::DeserializeOwned, Serialize};
use std::{
  collections::{HashMap, VecDeque},
  marker::PhantomData,
};

use super::{
  database::{Database, Order, Select, Transaction},
  Item,
};
use crate::joinable::{Clock, State};

#[cfg(test)]
use crate::joinable::Maximum;

/// A [`VectorHistory`] stores an action history for each replica.
pub struct VectorHistory<T: State, S: VectorHistoryStore<T>> {
  data: HashMap<u64, ReplicaHistory<T>>,
  _store: PhantomData<S>,
}

/// Action history and metadata for one replica.
struct ReplicaHistory<T: State> {
  actions: VecDeque<(Clock, T::Action)>,
  begin: Option<Clock>,
  latest: Option<Clock>,
}

impl<T: State, S: VectorHistoryStore<T>> VectorHistory<T, S>
where
  T::Action: Clone,
{
  #[cfg(test)]
  pub fn assert_invariants(&self, store: &S) {
    // All replica metadata must be loaded.
    assert_eq!(store.get_replicas().len(), self.data.len());
    // Per-replica invariants:
    for (replica, entry) in self.data.iter() {
      // `begin` must be less than or equal to `latest`.
      assert!(entry.begin <= entry.latest);
      // The last element in store must agree with `latest`.
      assert_eq!(store.get_by_replica_clock_max(*replica).map(|(clock, _)| clock), entry.latest);
      // All actions with clock value strictly greater than `begin` must be loaded.
      assert_eq!(store.get_by_replica_clock_range(*replica, entry.begin, Clock::maximum()).len(), entry.actions.len());
      // Clock values must be strictly monotone increasing.
      if !entry.actions.is_empty() {
        for ((fsta, _), (fstb, _)) in entry.actions.iter().zip(entry.actions.range(1..)) {
          assert!(fsta < fstb);
        }
      }
    }
  }

  /// Creates a vector history from a backing store.
  pub fn new(store: &S) -> Self {
    store.init();
    let mut data = HashMap::new();
    for replica in store.get_replicas() {
      let latest = store.get_by_replica_clock_max(replica).map(|(clock, _)| clock);
      let entry = ReplicaHistory { actions: VecDeque::new(), begin: latest, latest };
      data.insert(replica, entry);
    }
    Self { data, _store: Default::default() }
  }

  /// Returns the latest clock values for each replica.
  pub fn latests(&self) -> HashMap<u64, Option<Clock>> {
    self.data.iter().map(|(replica, entry)| (*replica, entry.latest)).collect()
  }

  /// Returns the latest clock value across all replicas.
  pub fn latest(&self) -> Option<Clock> {
    self.data.values().fold(None, |acc, entry| acc.max(entry.latest))
  }

  /// Moves `begin` backwards.
  /// Absent entries from `begins` are ignored (equiv. assumed to be [`Some(Maximum::maximum())`]).
  pub fn load_until(&mut self, store: &S, begins: &[(u64, Option<Clock>)]) {
    for (replica, begin) in begins.iter().copied() {
      if let Some(entry) = self.data.get_mut(&replica) {
        if begin < entry.begin {
          let items = store.get_by_replica_clock_range(replica, begin, entry.begin.unwrap()); // No panic.
          for (clock, action) in items.into_iter().rev() {
            entry.actions.push_front((clock, action));
          }
          entry.begin = begin;
        }
      }
    }
  }

  /// Moves `begin` forwards.
  /// Absent entries from `begins` are ignored (equiv. assumed to be [`None`]).
  pub fn unload_until(&mut self, begins: &[(u64, Option<Clock>)]) {
    for (replica, begin) in begins.iter().copied() {
      if let Some(entry) = self.data.get_mut(&replica) {
        let begin = begin.min(entry.latest);
        if begin > entry.begin {
          let start = entry.actions.partition_point(|(fst, _)| Some(*fst) <= begin);
          entry.actions.drain(..start);
          entry.begin = begin;
        }
      }
    }
  }

  /// Pushes to history. Clock values must be strictly monotone increasing. Invalid entries are ignored.
  pub fn push(&mut self, store: &S, item: Item<T>) -> bool {
    let (replica, clock, action) = item;
    let entry = self.data.entry(replica).or_insert_with(|| {
      store.put_replica(replica);
      ReplicaHistory { actions: VecDeque::new(), begin: None, latest: None }
    });
    if entry.latest < Some(clock) {
      entry.latest = Some(clock);
      entry.actions.push_back((clock, action.clone()));
      store.put_by_replica(replica, (clock, action));
      true
    } else {
      false
    }
  }

  /// Appends to history. Clock values must be strictly monotone increasing. Invalid entries are ignored.
  pub fn append(&mut self, store: &S, items: Vec<Item<T>>) -> Vec<Item<T>> {
    let mut res = Vec::new();
    for item in items {
      if self.push(store, item.clone()) {
        res.push(item);
      }
    }
    res
  }

  /// Returns all actions strictly later than given time stamps.
  /// Absent entries from `clocks` are assumed to be [`None`].
  pub fn collect(&mut self, store: &S, clocks: &HashMap<u64, Option<Clock>>) -> Vec<Item<T>> {
    let mut res = Vec::new();
    let mut begins = Vec::new();
    for replica in self.data.keys() {
      begins.push((*replica, clocks.get(replica).copied().unwrap_or(None)));
    }
    self.load_until(store, begins.as_slice());
    for (replica, begin) in begins {
      let entry = self.data.get_mut(&replica).unwrap(); // No panic.
      let start = entry.actions.partition_point(|(fst, _)| Some(*fst) <= begin);
      for (clock, action) in entry.actions.range(start..).cloned() {
        res.push((replica, clock, action));
      }
    }
    res
  }
}

/// Database interface for [`VectorHistory`].
pub trait VectorHistoryStore<T: State> {
  fn init(&self);
  fn get_replicas(&self) -> Vec<u64>;
  fn put_replica(&self, replica: u64);
  /// Left open, right closed, sorted by clock in ascending order.
  fn get_by_replica_clock_range(&self, replica: u64, lower: Option<Clock>, upper: Clock) -> Vec<(Clock, T::Action)>;
  fn get_by_replica_clock_max(&self, replica: u64) -> Option<(Clock, T::Action)>;
  fn put_by_replica(&self, replica: u64, item: (Clock, T::Action));
}

/// Implementation of [`VectorHistoryStore`] using SQLite.
pub struct SqliteVectorHistoryStore<'a, T: State> {
  instance: u64,
  transaction: &'a rusqlite::Transaction<'a>,
  _t: PhantomData<T>,
}

impl<'a, T: State> SqliteVectorHistoryStore<'a, T> {
  pub fn new(instance: u64, transaction: &'a rusqlite::Transaction<'a>) -> Self {
    Self { instance, transaction, _t: Default::default() }
  }
}

impl<'a, T: State> VectorHistoryStore<T> for SqliteVectorHistoryStore<'a, T>
where
  T::Action: Serialize + DeserializeOwned,
{
  fn init(&self) {
    self
      .transaction
      .execute_batch(
        "
      CREATE TABLE IF NOT EXISTS \"vector_history_replica\" (
        instance BLOB NOT NULL,
        replica BLOB NOT NULL
      ) STRICT;

      CREATE INDEX IF NOT EXISTS vector_history_replica_idx_instance_replica ON
        vector_history_replica (instance, replica);

      CREATE TABLE IF NOT EXISTS vector_history_replica_history (
        instance BLOB NOT NULL,
        replica BLOB NOT NULL,
        clock BLOB NOT NULL,
        action BLOB NOT NULL
      ) STRICT;

      CREATE INDEX IF NOT EXISTS vector_history_replica_history_idx_instance_replica_clock ON
        vector_history_replica_history (instance, replica, clock);
      ",
      )
      .unwrap();
  }

  fn get_replicas(&self) -> Vec<u64> {
    self
      .transaction
      .prepare_cached("SELECT replica FROM vector_history_replica WHERE instance = ?")
      .unwrap()
      .query_map((self.instance.to_be_bytes(),), |row| Ok(u64::from_be_bytes(row.get(0)?)))
      .unwrap()
      .collect::<Result<_, _>>()
      .unwrap()
  }

  fn put_replica(&self, replica: u64) {
    self
      .transaction
      .prepare_cached("INSERT INTO vector_history_replica (instance, replica) VALUES (?, ?)")
      .unwrap()
      .execute((self.instance.to_be_bytes(), replica.to_be_bytes()))
      .unwrap();
  }

  fn get_by_replica_clock_range(
    &self,
    replica: u64,
    lower: Option<Clock>,
    upper: Clock,
  ) -> Vec<(Clock, <T as State>::Action)> {
    let lower = lower.map_or(0, |clock| clock.to_u128() + 1).to_be_bytes();
    let upper = upper.to_be_bytes();
    self
      .transaction
      .prepare_cached(
        "SELECT clock, action FROM vector_history_replica_history \
        WHERE instance = ? AND replica = ? AND clock >= ? AND clock <= ? ORDER BY clock ASC",
      )
      .unwrap()
      .query_map((self.instance.to_be_bytes(), replica.to_be_bytes(), lower, upper), |row| {
        Ok((Clock::from_be_bytes(row.get(0)?), postcard::from_bytes(row.get_ref(1)?.as_blob()?).unwrap()))
      })
      .unwrap()
      .collect::<Result<_, _>>()
      .unwrap()
  }

  fn get_by_replica_clock_max(&self, replica: u64) -> Option<(Clock, <T as State>::Action)> {
    self
      .transaction
      .prepare_cached(
        "SELECT clock, action FROM vector_history_replica_history \
        WHERE instance = ? AND replica = ? ORDER BY clock DESC",
      )
      .unwrap()
      .query_row((self.instance.to_be_bytes(), replica.to_be_bytes()), |row| {
        Ok((Clock::from_be_bytes(row.get(0)?), postcard::from_bytes(row.get_ref(1)?.as_blob()?).unwrap()))
      })
      .optional()
      .unwrap()
  }

  fn put_by_replica(&self, replica: u64, item: (Clock, <T as State>::Action)) {
    self
      .transaction
      .prepare_cached(
        "INSERT INTO vector_history_replica_history \
        (instance, replica, clock, action) VALUES (?, ?, ?, ?)",
      )
      .unwrap()
      .execute((
        self.instance.to_be_bytes(),
        replica.to_be_bytes(),
        item.0.to_be_bytes(),
        postcard::to_allocvec(&item.1).unwrap(),
      ))
      .unwrap();
  }
}

/// Implementation of [`VectorHistoryStore`] using the database abstraction.
pub struct DatabaseVectorHistoryStore<'a, T: State, D: Database + 'a> {
  instance: u64,
  transaction: &'a D::Transaction<'a>,
  replica_table: &'a D::Table<2, 1>,
  replica_history_table: &'a D::Table<4, 1>,
  _t: PhantomData<T>,
}

const INSTANCE: usize = 0;
const REPLICA: usize = 1;
const CLOCK: usize = 2;
const ACTION: usize = 3;
const IDX_INSTANCE_REPLICA: usize = 0;
const IDX_INSTANCE_REPLICA_CLOCK: usize = 0;

impl<'a, T: State, D: Database> DatabaseVectorHistoryStore<'a, T, D> {
  pub fn replica_table(db: &D) -> D::Table<2, 1> {
    db.table(
      "vector_history_replica",
      ["instance", "replica"],
      [("vector_history_replica_idx_instance_replica", &[INSTANCE, REPLICA])],
    )
  }

  pub fn replica_history_table(db: &D) -> D::Table<4, 1> {
    db.table(
      "vector_history_replica_history",
      ["instance", "replica", "clock", "action"],
      [("vector_history_replica_history_idx_instance_replica_clock", &[INSTANCE, REPLICA, CLOCK])],
    )
  }

  pub fn new(
    instance: u64,
    txn: &'a D::Transaction<'a>,
    replica_table: &'a D::Table<2, 1>,
    replica_history_table: &'a D::Table<4, 1>,
  ) -> Self {
    Self { instance, transaction: txn, replica_table, replica_history_table, _t: Default::default() }
  }
}

impl<'a, T: State, D: Database> VectorHistoryStore<T> for DatabaseVectorHistoryStore<'a, T, D>
where
  T::Action: Serialize + DeserializeOwned,
{
  fn init(&self) {}

  fn get_replicas(&self) -> Vec<u64> {
    self
      .transaction
      .select(self.replica_table)
      .query_all(IDX_INSTANCE_REPLICA, [&self.instance.to_be_bytes()])
      .into_iter()
      .map(|(_, row)| u64::from_be_bytes(row[REPLICA].as_slice().try_into().unwrap()))
      .collect()
  }

  fn put_replica(&self, replica: u64) {
    self.transaction.select(self.replica_table).put([&self.instance.to_be_bytes(), &replica.to_be_bytes()]);
  }

  fn get_by_replica_clock_range(
    &self,
    replica: u64,
    lower: Option<Clock>,
    upper: Clock,
  ) -> Vec<(Clock, <T as State>::Action)> {
    let lower = lower.map_or(0, |clock| clock.to_u128() + 1);
    let upper = upper.to_u128();
    self
      .transaction
      .select(self.replica_history_table)
      .query_sorted_range(
        IDX_INSTANCE_REPLICA_CLOCK,
        [&self.instance.to_be_bytes(), &replica.to_be_bytes()],
        Order::Asc,
        Some(&lower.to_be_bytes()),
        Some(&upper.to_be_bytes()),
      )
      .into_iter()
      .map(|(_, row)| {
        (Clock::from_be_bytes(row[CLOCK].as_slice().try_into().unwrap()), postcard::from_bytes(&row[ACTION]).unwrap())
      })
      .collect()
  }

  fn get_by_replica_clock_max(&self, replica: u64) -> Option<(Clock, <T as State>::Action)> {
    self
      .transaction
      .select(self.replica_history_table)
      .query_sorted_first(
        IDX_INSTANCE_REPLICA_CLOCK,
        [&self.instance.to_be_bytes(), &replica.to_be_bytes()],
        Order::Desc,
      )
      .map(|(_, row)| {
        (Clock::from_be_bytes(row[CLOCK].as_slice().try_into().unwrap()), postcard::from_bytes(&row[ACTION]).unwrap())
      })
  }

  fn put_by_replica(&self, replica: u64, item: (Clock, <T as State>::Action)) {
    self.transaction.select(self.replica_history_table).put([
      &self.instance.to_be_bytes(),
      &replica.to_be_bytes(),
      &item.0.to_be_bytes(),
      &postcard::to_allocvec(&item.1).unwrap(),
    ]);
  }
}
