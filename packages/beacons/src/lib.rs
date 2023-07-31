// #![feature(vec_into_raw_parts)]

pub mod collection;
pub mod global;
pub mod joinable;
pub mod observable;
pub mod persistent;

use rusqlite::Connection;
use std::sync::{Mutex, MutexGuard, OnceLock};

static DB_CONNECTION: OnceLock<Mutex<Connection>> = OnceLock::new();

pub fn init(path: &str) {
  DB_CONNECTION.set(Mutex::new(Connection::open(path).unwrap())).unwrap();
}

pub fn db_connection() -> MutexGuard<'static, Connection> {
  DB_CONNECTION.get().unwrap().lock().unwrap()
}

#[cfg(test)]
mod tests {
  #[test]
  fn simple_test() {}
}

/*
#[repr(C)]
pub enum Event {
  CaseOne(u64),
  CaseTwo(u64),
}

#[repr(C)]
pub struct Events {
  ptr: *mut Event,
  len: usize,
  cap: usize,
}

#[no_mangle]
pub extern "C" fn add(left: u64, right: u64) -> u64 {
  left + right
}

#[no_mangle]
pub extern "C" fn create(arg_one: u64, arg_two: u64) -> Events {
  // Do things...
  let res = Vec::from([Event::CaseOne(arg_one), Event::CaseTwo(arg_two)]);
  let (ptr, len, cap) = res.into_raw_parts();
  Events { ptr, len, cap }
}

#[no_mangle]
pub extern "C" fn destroy(vec: Events) {
  unsafe { Vec::from_raw_parts(vec.ptr, vec.len, vec.cap) };
}
*/

/*
// Accessing nodes.
pub fn get_node(id: u128) -> Option<u64>;
pub fn set_node(id: u128, value: Option<u64>) -> Vec<Message>;
pub fn subscribe_node(id: u128, port: u64);
pub fn unsubscribe_node(id: u128, port: u64);

// Accessing atoms.
pub fn get_atom(id: u128) -> Option<Vec<u8>>;
pub fn set_atom(id: u128, value: Option<&[u8]>) -> Vec<Message>;
pub fn subscribe_atom(id: u128, port: u64);
pub fn unsubscribe_atom(id: u128, port: u64);

// Accessing edges.
pub fn get_edge(id: u128) -> Option<(u128, u64, u128)>;
pub fn set_edge(id: u128, value: Option<u128, u64, u128>) -> Vec<Message>;
pub fn subscribe_edge(id: u128, port: u64);
pub fn unsubscribe_edge(id: u128, port: u64);

// Accessing backedges.
pub fn subscribe_backedge(dst: u128, label: u64, port: u64);
pub fn unsubscribe_backedge(dst: u128, label: u64, port: u64);

// Queries.
pub fn get_edges_from(src: u128) -> Vec<u128>;

// Sync.
pub fn get_state_vector() -> Vec<u8>;
pub fn get_actions_after(state_vector: &[u8]) -> Vec<u8>;
pub fn apply_actions(actions: &[u8]) -> Vec<Message>;
*/
