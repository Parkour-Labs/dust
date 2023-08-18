pub mod crdt;
pub mod ffi;
pub mod global;
pub mod store;
use std::{
  collections::{hash_map::Entry, HashMap},
  hash::Hash,
};

pub use beacons_macros::*;

#[cfg(test)]
mod tests;

use bincode::{ErrorKind, Options};
use serde::{Deserialize, Serialize};

/// A wrapper around `bincode`.
pub fn serialize<T: Serialize>(value: &T) -> Result<Vec<u8>, Box<ErrorKind>> {
  bincode::options().reject_trailing_bytes().with_fixint_encoding().with_big_endian().serialize(value)
}

/// A wrapper around `bincode`.
pub fn deserialize<'a, T: Deserialize<'a>>(bytes: &'a [u8]) -> Result<T, Box<ErrorKind>> {
  bincode::options().reject_trailing_bytes().with_fixint_encoding().with_big_endian().deserialize(bytes)
}

/// Multimap insert.
fn insert<K: Eq + Hash, V: Eq>(map: &mut HashMap<K, Vec<V>>, key: K, value: V) {
  map.entry(key).or_default().push(value);
}

/// Multimap remove.
fn remove<K: Eq + Hash, V: Eq>(map: &mut HashMap<K, Vec<V>>, key: K, value: &V) {
  if let Entry::Occupied(mut entry) = map.entry(key) {
    entry.get_mut().retain(|x| x != value);
    if entry.get().is_empty() {
      entry.remove();
    }
  }
}
