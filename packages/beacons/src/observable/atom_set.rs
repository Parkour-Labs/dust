#![allow(clippy::type_complexity)]

//! An *observable* last-writer-wins element set for storing atomic data.

use std::borrow::Borrow;
use std::collections::HashMap;

use crate::joinable::atom_set::{self, AtomSetStore};
use crate::{insert, remove};

/// An *observable* last-writer-wins element set for storing atomic data.
#[derive(Debug)]
pub struct AtomSet {
  inner: atom_set::AtomSet,
  by_id: HashMap<u128, Vec<u64>>,
  // by_src: HashMap<u128, Vec<u64>>,
  by_src_label: HashMap<(u128, u64), Vec<u64>>,
  by_label: HashMap<u64, Vec<u64>>,
  // by_label_value: HashMap<(u64, Box<[u8]>), Vec<u64>>,
}

/// Type alias for item: `(id, bucket, clock, (src, label, value))`.
type Item = (u128, u64, u64, Option<(u128, u64, Box<[u8]>)>);

/// Event bus interface for [`AtomSet`].
pub trait AtomSetEvents {
  fn by_id_update(&mut self, port: u64, slv: Option<(u128, u64, Box<[u8]>)>);
  fn by_src_label_insert(&mut self, port: u64, id: u128, value: Box<[u8]>);
  fn by_src_label_remove(&mut self, port: u64, id: u128, value: Box<[u8]>);
  fn by_label_insert(&mut self, port: u64, id: u128, src: u128, value: Box<[u8]>);
  fn by_label_remove(&mut self, port: u64, id: u128, src: u128, value: Box<[u8]>);
}

impl AtomSet {
  /// Creates or loads data.
  pub fn new(name: &'static str, store: &mut impl AtomSetStore) -> Self {
    Self {
      inner: atom_set::AtomSet::new(name, store),
      by_id: HashMap::new(),
      by_src_label: HashMap::new(),
      by_label: HashMap::new(),
    }
  }

  /// Returns the name of the structure.
  pub fn name(&self) -> &'static str {
    self.inner.name()
  }

  /// Returns this bucket ID.
  pub fn this(&self) -> u64 {
    self.inner.this()
  }

  /// Returns the current clock values for each bucket.
  pub fn buckets(&self) -> &HashMap<u64, u64> {
    self.inner.buckets()
  }

  /// Returns the largest clock value across all buckets plus one.
  pub fn next(&self) -> u64 {
    self.inner.next()
  }

  pub fn get(&mut self, store: &mut impl AtomSetStore, id: u128) -> Option<Item> {
    self.inner.get(store, id)
  }

  pub fn label_value_by_src(&mut self, store: &mut impl AtomSetStore, src: u128) -> Vec<(u128, (u64, Box<[u8]>))> {
    self.inner.label_value_by_src(store, src)
  }

  pub fn value_by_src_label(&mut self, store: &mut impl AtomSetStore, src: u128, label: u64) -> Vec<(u128, Box<[u8]>)> {
    self.inner.value_by_src_label(store, src, label)
  }

  pub fn src_value_by_label(&mut self, store: &mut impl AtomSetStore, label: u64) -> Vec<(u128, (u128, Box<[u8]>))> {
    self.inner.src_value_by_label(store, label)
  }

  pub fn src_by_label_value(&mut self, store: &mut impl AtomSetStore, label: u64, value: &[u8]) -> Vec<(u128, u128)> {
    self.inner.src_by_label_value(store, label, value)
  }

  /// Modifies item.
  pub fn set(
    &mut self,
    store: &mut impl AtomSetStore,
    ctx: &mut impl AtomSetEvents,
    id: u128,
    bucket: u64,
    clock: u64,
    slv: Option<(u128, u64, &[u8])>,
  ) -> bool {
    if let Some((_, _, _, prev)) = self.inner.set(store, id, bucket, clock, slv) {
      self.notify(ctx, id, prev, slv.map(|(src, label, value)| (src, label, Vec::from(value).into())));
      return true;
    }
    false
  }

  /// Returns all actions strictly later than given clock values (sorted by clock value).
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl AtomSetStore, version: HashMap<u64, u64>) -> Vec<Item> {
    self.inner.actions(store, version)
  }

  /// Applies a set of actions (each bucket must be sorted by clock value).
  pub fn gamma_join(
    &mut self,
    store: &mut impl AtomSetStore,
    ctx: &mut impl AtomSetEvents,
    mut actions: Vec<Item>,
  ) -> Vec<Item> {
    actions.retain(|(id, bucket, clock, slv)| {
      self.set(store, ctx, *id, *bucket, *clock, slv.as_ref().map(|(src, label, value)| (*src, *label, value.borrow())))
    });
    actions
  }

  pub fn subscribe_by_id(&mut self, store: &mut impl AtomSetStore, ctx: &mut impl AtomSetEvents, id: u128, port: u64) {
    insert(&mut self.by_id, id, port);
    ctx.by_id_update(port, self.get(store, id).and_then(|(_, _, _, slv)| slv));
  }

  pub fn subscribe_by_src_label(
    &mut self,
    store: &mut impl AtomSetStore,
    ctx: &mut impl AtomSetEvents,
    src: u128,
    label: u64,
    port: u64,
  ) {
    insert(&mut self.by_src_label, (src, label), port);
    for (id, value) in self.value_by_src_label(store, src, label) {
      ctx.by_src_label_insert(port, id, value);
    }
  }

  pub fn subscribe_by_label(
    &mut self,
    store: &mut impl AtomSetStore,
    ctx: &mut impl AtomSetEvents,
    label: u64,
    port: u64,
  ) {
    insert(&mut self.by_label, label, port);
    for (id, (src, value)) in self.src_value_by_label(store, label) {
      ctx.by_label_insert(port, id, src, value);
    }
  }

  pub fn unsubscribe_by_id(&mut self, id: u128, port: u64) {
    remove(&mut self.by_id, id, &port);
  }

  pub fn unsubscribe_by_src_label(&mut self, src: u128, label: u64, port: u64) {
    remove(&mut self.by_src_label, (src, label), &port);
  }

  pub fn unsubscribe_by_label(&mut self, label: u64, port: u64) {
    remove(&mut self.by_label, label, &port);
  }

  fn notify(
    &mut self,
    ctx: &mut impl AtomSetEvents,
    id: u128,
    prev: Option<(u128, u64, Box<[u8]>)>,
    curr: Option<(u128, u64, Box<[u8]>)>,
  ) {
    if prev != curr {
      if let Some(ports) = self.by_id.get(&id) {
        for &port in ports {
          ctx.by_id_update(port, curr.clone());
        }
      }
      if let Some((src, label, value)) = prev {
        if let Some(ports) = self.by_src_label.get(&(src, label)) {
          for &port in ports {
            ctx.by_src_label_remove(port, id, value.clone());
          }
        }
        if let Some(ports) = self.by_label.get(&label) {
          for &port in ports {
            ctx.by_label_remove(port, id, src, value.clone());
          }
        }
      }
      if let Some((src, label, value)) = curr {
        if let Some(ports) = self.by_src_label.get(&(src, label)) {
          for &port in ports {
            ctx.by_src_label_insert(port, id, value.clone());
          }
        }
        if let Some(ports) = self.by_label.get(&label) {
          for &port in ports {
            ctx.by_label_insert(port, id, src, value.clone());
          }
        }
      }
    }
  }
}
