//! A [`VectorHistory`] stores an action history for each replica.

use rand::Rng;
use rusqlite::{OptionalExtension, Transaction};
use std::collections::{HashMap, VecDeque};

/// A [`VectorHistory`] stores an action history for each replica.
#[derive(Debug, Clone)]
pub struct VectorHistory {
  data: HashMap<u64, ReplicaHistory>, // Maps replica ID -> (loaded replica history).
  this: u64,                          // Current replica ID.
  name: &'static str,                 // Collection name.
}

/// Action history and metadata for one replica.
#[derive(Debug, Clone)]
struct ReplicaHistory {
  actions: VecDeque<(u64, String, Vec<u8>)>, // Array of (serial, structure name, content).
  serial_begin: u64,                         // Left open.
  serial_next: u64,                          // Right closed.
}

impl VectorHistory {
  pub fn assert_invariants(&self, store: &mut impl VectorHistoryStore) {
    // All replica metadata must be loaded.
    assert_eq!(store.get_replicas(self.name).len(), self.data.len());
    // Per-replica invariants:
    for (&replica, entry) in self.data.iter() {
      // `serial_begin` must be less than or equal to `serial_next`.
      assert!(entry.serial_begin <= entry.serial_next);
      // The last element in store must agree with `serial_next`.
      assert_eq!(
        store.get_action_latest(self.name, replica).map(|(serial, _, _)| serial).unwrap_or(0),
        entry.serial_next
      );
      // All actions with serial value strictly greater than `serial_begin` must be loaded.
      assert_eq!(
        store.get_actions(self.name, replica, entry.serial_begin, entry.serial_next).len(),
        entry.actions.len()
      );
      // Serial values must be strictly monotone increasing.
      if !entry.actions.is_empty() {
        assert!(0 < entry.actions.front().unwrap().0);
        for ((fsta, _, _), (fstb, _, _)) in entry.actions.iter().zip(entry.actions.range(1..)) {
          assert!(fsta < fstb);
        }
      }
    }
  }

  /// Creates a vector history from a backing store.
  pub fn new(store: &mut impl VectorHistoryStore, name: &'static str) -> Self {
    let this = store.init(name);
    let data = store
      .get_replicas(name)
      .into_iter()
      .map(|replica| {
        let latest = store.get_action_latest(name, replica).map(|(serial, _, _)| serial).unwrap_or(0);
        let entry = ReplicaHistory { actions: VecDeque::new(), serial_begin: latest, serial_next: latest };
        (replica, entry)
      })
      .collect();
    Self { data, this, name }
  }

  /// Returns the next serial values for each replica.
  pub fn nexts(&self) -> HashMap<u64, u64> {
    self.data.iter().map(|(&replica, entry)| (replica, entry.serial_next)).collect()
  }

  /// Returns the next serial value for this replica.
  pub fn next_this(&self) -> u64 {
    self.data.get(&self.this).map(|entry| entry.serial_next).unwrap_or(0)
  }

  /// Returns this replica ID.
  pub fn this(&self) -> u64 {
    self.this
  }

  /// Moves `serial_begin` backwards.
  /// Absent entries from `begins` are ignored (equiv. assumed to be `u64::MAX`).
  pub fn load_until(&mut self, store: &mut impl VectorHistoryStore, begins: &[(u64, u64)]) {
    for &(replica, begin) in begins.iter() {
      if let Some(entry) = self.data.get_mut(&replica) {
        if begin < entry.serial_begin {
          for item in store.get_actions(self.name, replica, begin, entry.serial_begin).into_iter().rev() {
            entry.actions.push_front(item);
          }
          entry.serial_begin = begin;
        }
      }
    }
  }

  /// Moves `begin` forwards.
  /// Absent entries from `begins` are ignored (equiv. assumed to be `0`).
  pub fn unload_until(&mut self, begins: &[(u64, u64)]) {
    for &(replica, begin) in begins.iter() {
      if let Some(entry) = self.data.get_mut(&replica) {
        let begin = begin.min(entry.serial_next);
        if begin > entry.serial_begin {
          entry.actions.drain(..entry.actions.partition_point(|(fst, _, _)| *fst <= begin));
          entry.serial_begin = begin;
        }
      }
    }
  }

  /// Pushes to history. Serial values must be strictly monotone increasing. Invalid entries are ignored.
  pub fn push(
    &mut self,
    store: &mut impl VectorHistoryStore,
    item: (u64, u64, String, Vec<u8>),
  ) -> Option<(u64, u64, String, Vec<u8>)> {
    let (replica, serial, name, action) = item;
    let entry = self.data.entry(replica).or_insert_with(|| {
      store.put_replica(self.name, replica);
      ReplicaHistory { actions: VecDeque::new(), serial_begin: 0, serial_next: 0 }
    });
    if entry.serial_next < serial {
      entry.serial_next = serial;
      entry.actions.push_back((serial, name.clone(), action.clone()));
      store.put_action(self.name, replica, (serial, &name, &action));
      Some((replica, serial, name, action))
    } else {
      None
    }
  }

  /// Appends to history. Serial values must be strictly monotone increasing. Invalid entries are ignored.
  pub fn append(
    &mut self,
    store: &mut impl VectorHistoryStore,
    items: Vec<(u64, u64, String, Vec<u8>)>,
  ) -> Vec<(u64, u64, String, Vec<u8>)> {
    let mut res = Vec::new();
    for item in items {
      if let Some(item) = self.push(store, item) {
        res.push(item);
      }
    }
    res
  }

  /// Returns all actions strictly later than given time stamps.
  /// Absent entries from `serials` are assumed to be `0`.
  pub fn collect(
    &mut self,
    store: &mut impl VectorHistoryStore,
    mut serials: HashMap<u64, u64>,
  ) -> Vec<(u64, u64, String, Vec<u8>)> {
    let mut res = Vec::new();
    let mut begins = Vec::new();
    for replica in self.data.keys() {
      begins.push((*replica, serials.remove(replica).unwrap_or(0)));
    }
    self.load_until(store, begins.as_slice());
    for (replica, begin) in begins {
      let entry = self.data.get_mut(&replica).unwrap(); // No panic.
      let start = entry.actions.partition_point(|(fst, _, _)| *fst <= begin);
      for (serial, name, action) in entry.actions.range(start..).cloned() {
        res.push((replica, serial, name, action));
      }
    }
    res
  }
}

/// Database interface for [`VectorHistory`].
pub trait VectorHistoryStore {
  fn init(&mut self, collection: &str) -> u64;
  fn get_replicas(&mut self, collection: &str) -> Vec<u64>;
  fn put_replica(&mut self, collection: &str, replica: u64);
  fn get_action_latest(&mut self, collection: &str, replica: u64) -> Option<(u64, String, Vec<u8>)>;
  fn get_actions(&mut self, collection: &str, replica: u64, lower: u64, upper: u64) -> Vec<(u64, String, Vec<u8>)>;
  fn put_action(&mut self, collection: &str, replica: u64, item: (u64, &str, &[u8]));
}

impl<'a> VectorHistoryStore for Transaction<'a> {
  fn init(&mut self, collection: &str) -> u64 {
    self
      .execute_batch(&format!(
        "
CREATE TABLE IF NOT EXISTS \"{collection}.vector_history.this\" (
  replica BLOB NOT NULL,
  PRIMARY KEY (replica)
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS \"{collection}.vector_history.replicas\" (
  replica BLOB NOT NULL,
  PRIMARY KEY (replica)
) STRICT, WITHOUT ROWID;

CREATE TABLE IF NOT EXISTS \"{collection}.vector_history\" (
  replica BLOB NOT NULL,
  serial BLOB NOT NULL,
  name BLOB NOT NULL,
  action BLOB NOT NULL,
  PRIMARY KEY (replica, serial)
) STRICT, WITHOUT ROWID;
        "
      ))
      .unwrap();

    let this = self
      .prepare_cached(&format!("SELECT replica FROM \"{collection}.vector_history.this\""))
      .unwrap()
      .query_row((), |row| Ok(u64::from_be_bytes(row.get(0).unwrap())))
      .optional()
      .unwrap();

    this.unwrap_or_else(|| {
      let random: u64 = rand::thread_rng().gen();
      self
        .prepare_cached(&format!("REPLACE INTO \"{collection}.vector_history.this\" VALUES (?)"))
        .unwrap()
        .execute((random.to_be_bytes(),))
        .unwrap();
      random
    })
  }

  fn get_replicas(&mut self, collection: &str) -> Vec<u64> {
    self
      .prepare_cached(&format!("SELECT replica FROM \"{collection}.vector_history.replicas\""))
      .unwrap()
      .query_map((), |row| Ok(u64::from_be_bytes(row.get(0).unwrap())))
      .unwrap()
      .collect::<Result<_, _>>()
      .unwrap()
  }

  fn put_replica(&mut self, collection: &str, replica: u64) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{collection}.vector_history.replicas\" VALUES (?)"))
      .unwrap()
      .execute((replica.to_be_bytes(),))
      .unwrap();
  }

  fn get_action_latest(&mut self, collection: &str, replica: u64) -> Option<(u64, String, Vec<u8>)> {
    self
      .prepare_cached(&format!(
        "SELECT serial, name, action FROM \"{collection}.vector_history\" WHERE replica = ? ORDER BY serial DESC LIMIT 1"
      ))
      .unwrap()
      .query_row((replica.to_be_bytes(),), |row| {
        Ok((
          u64::from_be_bytes(row.get(0).unwrap()),
          String::from_utf8(row.get(1).unwrap()).unwrap(),
          row.get(2).unwrap(),
        ))
      })
      .optional()
      .unwrap()
  }

  fn get_actions(&mut self, collection: &str, replica: u64, lower: u64, upper: u64) -> Vec<(u64, String, Vec<u8>)> {
    self
      .prepare_cached(&format!(
        "SELECT serial, name, action FROM \"{collection}.vector_history\" WHERE replica = ? AND serial > ? AND serial <= ? ORDER BY serial ASC"
      ))
      .unwrap()
      .query_map((replica.to_be_bytes(), lower.to_be_bytes(), upper.to_be_bytes()), |row| {
        Ok((
          u64::from_be_bytes(row.get(0).unwrap()),
          String::from_utf8(row.get(1).unwrap()).unwrap(),
          row.get(2).unwrap(),
        ))
      })
      .unwrap()
      .collect::<Result<_, _>>()
      .unwrap()
  }

  fn put_action(&mut self, collection: &str, replica: u64, item: (u64, &str, &[u8])) {
    self
      .prepare_cached(&format!("REPLACE INTO \"{collection}.vector_history\" VALUES (?, ?, ?, ?)"))
      .unwrap()
      .execute((replica.to_be_bytes(), item.0.to_be_bytes(), item.1.as_bytes(), item.2))
      .unwrap();
  }
}
