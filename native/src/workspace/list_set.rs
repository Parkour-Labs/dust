//! YATA sequence sets.

/*
/// A base class for YATA sequence sets.
#[derive(Debug, Clone)]
pub struct ListSet<T: Ord + Clone> {
  version: Version<u64>,
  nodes: BTreeMap<(u64, u64), Option<Item<T>>>, // All loaded nodes.
  roots: BTreeSet<(u64, u64)>,                  // All loaded roots.
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
*/
