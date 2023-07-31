use rusqlite::Connection;
use std::sync::{Mutex, MutexGuard, OnceLock};

use crate::object_store::ObjectStore;

const INITIAL_COMMANDS: &str = "
PRAGMA auto_vacuum = INCREMENTAL;
PRAGMA journal_mode = WAL;
PRAGMA wal_autocheckpoint = 8000;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -20000;
PRAGMA busy_timeout = 3000;
";

// static CONNECTION: OnceLock<Mutex<Connection>> = OnceLock::new();
static OBJECT_STORE: OnceLock<Mutex<ObjectStore>> = OnceLock::new();

pub fn init(path: &str) {
  let conn = Connection::open(path).unwrap();
  conn.execute_batch(INITIAL_COMMANDS).unwrap();
  OBJECT_STORE.set(Mutex::new(ObjectStore::new(conn, ""))).unwrap();
}

pub fn init_in_memory() {
  let conn = Connection::open_in_memory().unwrap();
  conn.execute_batch(INITIAL_COMMANDS).unwrap();
  OBJECT_STORE.set(Mutex::new(ObjectStore::new(conn, ""))).unwrap();
}

pub fn object_store() -> MutexGuard<'static, ObjectStore> {
  OBJECT_STORE.get().unwrap().lock().unwrap()
}

#[cfg(test)]
mod tests {
  use rand::Rng;

  use super::*;

  #[test]
  fn simple_test() {
    init_in_memory();
    let mut rng = rand::thread_rng();
    let mut store = object_store();
    store.set_node(0, Some(233));
    store.set_node(1, Some(2333));
    store.set_edge(rng.gen(), Some((0, 23333, 1)));
    assert_eq!(store.node(0), Some(233));
    assert_eq!(store.node(1), Some(2333));
    let edges = store.edges_from(0);
    assert_eq!(edges.len(), 1);
    assert_eq!(store.edge(edges[0]), Some((0, 23333, 1)));
  }
}
