//! Sequence-like CRDTs.

use crate::crdt::metadata::VersionClock;

impl VersionClock for u64 {
  type SqlType = [u8; 8];

  fn serialize(&self) -> Self::SqlType {
    self.to_be_bytes()
  }
  fn deserialize(data: Self::SqlType) -> Self {
    u64::from_be_bytes(data)
  }
}
