pub mod ffi;
pub mod global;
pub mod joinable;
pub mod observable;
pub mod persistent;
pub mod store;
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
