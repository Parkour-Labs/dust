pub mod ffi;
pub mod global;
pub mod workspace;
pub use beacons_macros::*;

use bincode::{ErrorKind, Options};
use serde::{Deserialize, Serialize};
use std::num::Wrapping;

/// A wrapper around `bincode`.
pub fn serialize<T: Serialize>(value: &T) -> Result<Vec<u8>, Box<ErrorKind>> {
  bincode::options().reject_trailing_bytes().with_fixint_encoding().with_big_endian().serialize(value)
}

/// A wrapper around `bincode`.
pub fn deserialize<'a, T: Deserialize<'a>>(bytes: &'a [u8]) -> Result<T, Box<ErrorKind>> {
  bincode::options().reject_trailing_bytes().with_fixint_encoding().with_big_endian().deserialize(bytes)
}

/*
/// Multimap insert.
fn insert<K: Eq + Hash, V: Eq>(map: &mut BTreeMap<K, Vec<V>>, key: K, value: V) {
  map.entry(key).or_default().push(value);
}

/// Multimap remove.
fn remove<K: Eq + Hash, V: Eq>(map: &mut BTreeMap<K, Vec<V>>, key: K, value: &V) {
  if let Entry::Occupied(mut entry) = map.entry(key) {
    if let Some(index) = entry.get().iter().position(|x| x == value) {
      entry.get_mut().remove(index);
      if entry.get().is_empty() {
        entry.remove();
      }
    }
  }
}
*/

/// Hashes the string `s` to a value of desired.
fn fnv64_hash(s: impl AsRef<str>) -> u64 {
  const PRIME: Wrapping<u64> = Wrapping(1099511628211);
  const BASIS: Wrapping<u64> = Wrapping(14695981039346656037);
  let mut res = BASIS;
  for c in s.as_ref().as_bytes() {
    res = (res * PRIME) ^ Wrapping(*c as u64);
  }
  res.0
}

#[cfg(test)]
mod tests {
  use super::*;

  #[test]
  fn serde_simple() {
    assert_eq!(serialize(&1u64).unwrap(), [0, 0, 0, 0, 0, 0, 0, 1]);
    assert_eq!(serialize(&-2i64).unwrap(), [255, 255, 255, 255, 255, 255, 255, 254]);
    assert_eq!(deserialize::<u64>(&[0, 0, 0, 0, 0, 0, 0, 1]).unwrap(), 1u64);
    assert_eq!(deserialize::<i64>(&[255, 255, 255, 255, 255, 255, 255, 254]).unwrap(), -2i64);
    assert_eq!(serialize(&None::<i64>).unwrap(), [0]);
    assert_eq!(serialize(&Some(-1i64)).unwrap(), [1, 255, 255, 255, 255, 255, 255, 255, 255]);
    assert_eq!(deserialize::<Option<i64>>(&[0]).unwrap(), None);
    assert_eq!(deserialize::<Option<i64>>(&[1, 255, 255, 255, 255, 255, 255, 255, 255]).unwrap(), Some(-1));
  }

  /*
  #[test]
  fn multimap_simple() {
    let mut map = BTreeMap::<u64, Vec<u64>>::new();

    insert(&mut map, 0, 233);
    insert(&mut map, 1, 233);
    insert(&mut map, 1, 233);
    insert(&mut map, 1, 234);
    insert(&mut map, 0, 234);
    insert(&mut map, 0, 234);
    assert_eq!(map.get(&0).unwrap(), &[233, 234, 234]);
    assert_eq!(map.get(&1).unwrap(), &[233, 233, 234]);

    remove(&mut map, 0, &233);
    assert_eq!(map.get(&0).unwrap(), &[234, 234]);
    remove(&mut map, 0, &234);
    assert_eq!(map.get(&0).unwrap(), &[234]);
    remove(&mut map, 0, &235);
    assert_eq!(map.get(&0).unwrap(), &[234]);
    remove(&mut map, 0, &234);
    assert_eq!(map.get(&0), None);
  }
  */
}
