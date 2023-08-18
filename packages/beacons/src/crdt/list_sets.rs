//! YATA sequence sets.

use std::collections::{HashMap, HashSet};

use super::metadata::VersionStore;
use crate::crdt::metadata::{Version, VersionClock};

impl VersionClock for u64 {
  type SqlType = [u8; 8];

  fn serialize(&self) -> Self::SqlType {
    self.to_be_bytes()
  }

  fn deserialize(data: Self::SqlType) -> Self {
    u64::from_be_bytes(data)
  }
}

/// A base class for YATA sequence sets.
#[derive(Debug, Clone)]
pub struct ListSet<T: Ord + Clone> {
  version: Version<u64>,
  nodes: HashMap<(u64, u64), Option<Item<T>>>, // All loaded nodes.
  roots: HashSet<(u64, u64)>,                  // All loaded roots.
}

/// Item type for YATA sequence sets.
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct Item<T: Ord + Clone> {
  parent: Option<(u64, u64)>, // Root nodes have `parent == None`.
  right: Option<(u64, u64)>,  // Rightmost child nodes have `right == None`.
  data: Option<Vec<T>>,       // Removed nodes have `data == None`.
}

/// Database interface for [`ListSet`].
pub trait ListSetStore<T: Ord + Clone>: VersionStore<u64> {
  fn init_data(&mut self, name: &str);
  fn get_data(&mut self, name: &str, bucket: u64, serial: u64) -> Option<Item<T>>;
  fn set_data(&mut self, name: &str, bucket: u64, serial: u64, value: &Item<T>);
  fn query_data(&mut self, name: &str, bucket: u64, lower: u64) -> Vec<((u64, u64), Item<T>)>; // Inclusive.
}