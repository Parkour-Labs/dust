//! A [`VectorHistory`] stores an action history for each replica.

use rusqlite::{OptionalExtension, Transaction};
use std::collections::{HashMap, VecDeque};

use crate::joinable::{Clock, Maximum};

/// A [`VectorHistory`] stores an action history for each replica.
pub struct VectorHistory {
  data: HashMap<u128, ReplicaHistory>,
  name: &'static str,
}

/// Action history and metadata for one replica.
struct ReplicaHistory {
  actions: VecDeque<(Clock, String, Vec<u8>)>,
  begin: Option<Clock>,
  latest: Option<Clock>,
}

impl VectorHistory {
  pub fn assert_invariants<S: VectorHistoryStore>(&self, store: &S) {
    // All replica metadata must be loaded.
    assert_eq!(store.get_replicas(self.name).len(), self.data.len());
    // Per-replica invariants:
    for (replica, entry) in self.data.iter() {
      // `begin` must be less than or equal to `latest`.
      assert!(entry.begin <= entry.latest);
      // The last element in store must agree with `latest`.
      assert_eq!(store.get_by_replica_clock_max(self.name, *replica).map(|(clock, _, _)| clock), entry.latest);
      // All actions with clock value strictly greater than `begin` must be loaded.
      assert_eq!(
        store.get_by_replica_clock_range(self.name, *replica, entry.begin, Clock::maximum()).len(),
        entry.actions.len()
      );
      // Clock values must be strictly monotone increasing.
      if !entry.actions.is_empty() {
        for ((fsta, _, _), (fstb, _, _)) in entry.actions.iter().zip(entry.actions.range(1..)) {
          assert!(fsta < fstb);
        }
      }
    }
  }

  /// Creates a vector history from a backing store.
  pub fn new<S: VectorHistoryStore>(store: &S, name: &'static str) -> Self {
    store.init(name);
    let mut data = HashMap::new();
    for replica in store.get_replicas(name) {
      let latest = store.get_by_replica_clock_max(name, replica).map(|(clock, _, _)| clock);
      let entry = ReplicaHistory { actions: VecDeque::new(), begin: latest, latest };
      data.insert(replica, entry);
    }
    Self { data, name }
  }

  /// Returns the latest clock values for each replica.
  pub fn latests(&self) -> HashMap<u128, Option<Clock>> {
    self.data.iter().map(|(replica, entry)| (*replica, entry.latest)).collect()
  }

  /// Returns the latest clock value across all replicas.
  pub fn latest(&self) -> Option<Clock> {
    self.data.values().fold(None, |acc, entry| acc.max(entry.latest))
  }

  /// Moves `begin` backwards.
  /// Absent entries from `begins` are ignored (equiv. assumed to be [`Some(Maximum::maximum())`]).
  pub fn load_until<S: VectorHistoryStore>(&mut self, store: &S, begins: &[(u128, Option<Clock>)]) {
    for (replica, begin) in begins.iter().copied() {
      if let Some(entry) = self.data.get_mut(&replica) {
        if begin < entry.begin {
          let items = store.get_by_replica_clock_range(self.name, replica, begin, entry.begin.unwrap()); // No panic.
          for (clock, name, action) in items.into_iter().rev() {
            entry.actions.push_front((clock, name, action));
          }
          entry.begin = begin;
        }
      }
    }
  }

  /// Moves `begin` forwards.
  /// Absent entries from `begins` are ignored (equiv. assumed to be [`None`]).
  pub fn unload_until(&mut self, begins: &[(u128, Option<Clock>)]) {
    for (replica, begin) in begins.iter().copied() {
      if let Some(entry) = self.data.get_mut(&replica) {
        let begin = begin.min(entry.latest);
        if begin > entry.begin {
          let start = entry.actions.partition_point(|(fst, _, _)| Some(*fst) <= begin);
          entry.actions.drain(..start);
          entry.begin = begin;
        }
      }
    }
  }

  /// Pushes to history. Clock values must be strictly monotone increasing. Invalid entries are ignored.
  pub fn push<S: VectorHistoryStore>(
    &mut self,
    store: &S,
    replica: u128,
    clock: Clock,
    name: String,
    action: Vec<u8>,
  ) -> bool {
    let entry = self.data.entry(replica).or_insert_with(|| {
      store.put_replica(self.name, replica);
      ReplicaHistory { actions: VecDeque::new(), begin: None, latest: None }
    });
    if entry.latest < Some(clock) {
      entry.latest = Some(clock);
      entry.actions.push_back((clock, name.clone(), action.clone()));
      store.put_by_replica(self.name, replica, (clock, name, action));
      true
    } else {
      false
    }
  }

  /// Appends to history. Clock values must be strictly monotone increasing. Invalid entries are ignored.
  pub fn append<S: VectorHistoryStore>(
    &mut self,
    store: &S,
    items: Vec<(u128, Clock, String, Vec<u8>)>,
  ) -> Vec<(u128, Clock, String, Vec<u8>)> {
    let mut res = Vec::new();
    for item in items {
      let (replica, clock, name, action) = item.clone();
      if self.push(store, replica, clock, name, action) {
        res.push(item);
      }
    }
    res
  }

  /// Returns all actions strictly later than given time stamps.
  /// Absent entries from `clocks` are assumed to be [`None`].
  pub fn collect<S: VectorHistoryStore>(
    &mut self,
    store: &S,
    mut clocks: HashMap<u128, Option<Clock>>,
  ) -> Vec<(u128, Clock, String, Vec<u8>)> {
    let mut res = Vec::new();
    let mut begins = Vec::new();
    for replica in self.data.keys() {
      begins.push((*replica, clocks.remove(replica).unwrap_or(None)));
    }
    self.load_until(store, begins.as_slice());
    for (replica, begin) in begins {
      let entry = self.data.get_mut(&replica).unwrap(); // No panic.
      let start = entry.actions.partition_point(|(fst, _, _)| Some(*fst) <= begin);
      for (clock, name, action) in entry.actions.range(start..).cloned() {
        res.push((replica, clock, name, action));
      }
    }
    res
  }
}

/// Database interface for [`VectorHistory`].
pub trait VectorHistoryStore {
  fn init(&self, name: &str);
  fn get_replicas(&self, name: &str) -> Vec<u128>;
  fn put_replica(&self, name: &str, replica: u128);
  fn get_by_replica_clock_range(
    &self,
    name: &str,
    replica: u128,
    lower: Option<Clock>,
    upper: Clock,
  ) -> Vec<(Clock, String, Vec<u8>)>;
  fn get_by_replica_clock_max(&self, name: &str, replica: u128) -> Option<(Clock, String, Vec<u8>)>;
  fn put_by_replica(&self, name: &str, replica: u128, item: (Clock, String, Vec<u8>));
}

impl<'a> VectorHistoryStore for Transaction<'a> {
  fn init(&self, name: &str) {
    self
      .execute_batch(&format!(
        "
CREATE TABLE IF NOT EXISTS \"{name}.vhr\" (
  replica BLOB NOT NULL,
  PRIMARY KEY (replica)
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS \"{name}.vh\" (
  replica BLOB NOT NULL,
  clock BLOB NOT NULL,
  name BLOB NOT NULL,
  action BLOB NOT NULL,
  PRIMARY KEY (replica, clock)
) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();
  }

  fn get_replicas(&self, name: &str) -> Vec<u128> {
    self
      .prepare_cached(&format!("SELECT replica FROM \"{name}.vhr\""))
      .unwrap()
      .query_map((), |row| Ok(u128::from_be_bytes(row.get(0)?)))
      .unwrap()
      .collect::<Result<_, _>>()
      .unwrap()
  }

  fn put_replica(&self, name: &str, replica: u128) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.vhr\" (replica) VALUES (?)"))
      .unwrap()
      .execute((replica.to_be_bytes(),))
      .unwrap();
  }

  fn get_by_replica_clock_range(
    &self,
    name: &str,
    replica: u128,
    lower: Option<Clock>,
    upper: Clock,
  ) -> Vec<(Clock, String, Vec<u8>)> {
    let lower = lower.map_or(0, |clock| clock.to_u128() + 1).to_be_bytes();
    let upper = upper.to_be_bytes();
    self
      .prepare_cached(&format!(
        "SELECT clock, name, action FROM \"{name}.vh\" WHERE replica = ? AND clock >= ? AND clock <= ? ORDER BY clock ASC"
      ))
      .unwrap()
      .query_map((replica.to_be_bytes(), lower, upper), |row| {
        Ok((Clock::from_be_bytes(row.get(0)?), String::from_utf8(row.get(1)?).unwrap(), row.get(2)?))
      })
      .unwrap()
      .collect::<Result<_, _>>()
      .unwrap()
  }

  fn get_by_replica_clock_max(&self, name: &str, replica: u128) -> Option<(Clock, String, Vec<u8>)> {
    self
      .prepare_cached(&format!("SELECT clock, name, action FROM \"{name}.vh\" WHERE replica = ? ORDER BY clock DESC"))
      .unwrap()
      .query_row((replica.to_be_bytes(),), |row| {
        Ok((Clock::from_be_bytes(row.get(0)?), String::from_utf8(row.get(1)?).unwrap(), row.get(2)?))
      })
      .optional()
      .unwrap()
  }

  fn put_by_replica(&self, name: &str, replica: u128, item: (Clock, String, Vec<u8>)) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{name}.vh\" (replica, clock, name, action) VALUES (?, ?, ?, ?)"))
      .unwrap()
      .execute((replica.to_be_bytes(), item.0.to_be_bytes(), item.1.into_bytes(), item.2))
      .unwrap();
  }
}
