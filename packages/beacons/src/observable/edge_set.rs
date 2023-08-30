//! An *observable* last-writer-wins element set for storing edges.

use std::collections::HashMap;

use crate::joinable::edge_set::{self, EdgeSetStore};
use crate::{insert, remove};

/// An *observable* last-writer-wins element set for storing edges.
#[derive(Debug)]
pub struct EdgeSet {
  inner: edge_set::EdgeSet,
  by_id: HashMap<u128, Vec<u64>>,
  // by_src: HashMap<u128, Vec<u64>>,
  by_src_label: HashMap<(u128, u64), Vec<u64>>,
  by_label: HashMap<u64, Vec<u64>>,
  by_label_dst: HashMap<(u64, u128), Vec<u64>>,
}

/// Type alias for item: `(id, bucket, clock, (src, label, dst))`.
type Item = (u128, u64, u64, Option<(u128, u64, u128)>);

/// Event bus interface for [`EdgeSet`].
pub trait EdgeSetEvents {
  fn by_id_update(&mut self, port: u64, sld: Option<(u128, u64, u128)>);
  fn by_src_label_insert(&mut self, port: u64, id: u128, dst: u128);
  fn by_src_label_remove(&mut self, port: u64, id: u128, dst: u128);
  fn by_label_insert(&mut self, port: u64, id: u128, src: u128, dst: u128);
  fn by_label_remove(&mut self, port: u64, id: u128, src: u128, dst: u128);
  fn by_label_dst_insert(&mut self, port: u64, id: u128, src: u128);
  fn by_label_dst_remove(&mut self, port: u64, id: u128, src: u128);
}

impl EdgeSet {
  /// Creates or loads data.
  pub fn new(name: &'static str, store: &mut impl EdgeSetStore) -> Self {
    Self {
      inner: edge_set::EdgeSet::new(name, store),
      by_id: HashMap::new(),
      by_src_label: HashMap::new(),
      by_label: HashMap::new(),
      by_label_dst: HashMap::new(),
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

  pub fn get(&mut self, store: &mut impl EdgeSetStore, id: u128) -> Option<Item> {
    self.inner.get(store, id)
  }

  pub fn label_dst_by_src(&mut self, store: &mut impl EdgeSetStore, src: u128) -> Vec<(u128, (u64, u128))> {
    self.inner.label_dst_by_src(store, src)
  }

  pub fn dst_by_src_label(&mut self, store: &mut impl EdgeSetStore, src: u128, label: u64) -> Vec<(u128, u128)> {
    self.inner.dst_by_src_label(store, src, label)
  }

  pub fn src_dst_by_label(&mut self, store: &mut impl EdgeSetStore, label: u64) -> Vec<(u128, (u128, u128))> {
    self.inner.src_dst_by_label(store, label)
  }

  pub fn src_by_label_dst(&mut self, store: &mut impl EdgeSetStore, label: u64, dst: u128) -> Vec<(u128, u128)> {
    self.inner.src_by_label_dst(store, label, dst)
  }

  /// Modifies item.
  pub fn set(
    &mut self,
    store: &mut impl EdgeSetStore,
    ctx: &mut impl EdgeSetEvents,
    id: u128,
    bucket: u64,
    clock: u64,
    sld: Option<(u128, u64, u128)>,
  ) -> bool {
    if let Some((_, _, _, prev)) = self.inner.set(store, id, bucket, clock, sld) {
      self.notify(ctx, id, prev, sld);
      return true;
    }
    false
  }

  /// Returns all actions strictly later than given clock values (sorted by clock value).
  /// Absent entries are assumed to be `None`.
  pub fn actions(&mut self, store: &mut impl EdgeSetStore, version: HashMap<u64, u64>) -> Vec<Item> {
    self.inner.actions(store, version)
  }

  /// Applies a set of actions (each bucket must be sorted by clock value).
  pub fn gamma_join(
    &mut self,
    store: &mut impl EdgeSetStore,
    ctx: &mut impl EdgeSetEvents,
    mut actions: Vec<Item>,
  ) -> Vec<Item> {
    actions.retain(|(id, bucket, clock, sld)| self.set(store, ctx, *id, *bucket, *clock, *sld));
    actions
  }

  pub fn subscribe_by_id(&mut self, store: &mut impl EdgeSetStore, ctx: &mut impl EdgeSetEvents, id: u128, port: u64) {
    insert(&mut self.by_id, id, port);
    ctx.by_id_update(port, self.get(store, id).and_then(|(_, _, _, sld)| sld));
  }

  pub fn subscribe_by_src_label(
    &mut self,
    store: &mut impl EdgeSetStore,
    ctx: &mut impl EdgeSetEvents,
    src: u128,
    label: u64,
    port: u64,
  ) {
    insert(&mut self.by_src_label, (src, label), port);
    for (id, dst) in self.dst_by_src_label(store, src, label) {
      ctx.by_src_label_insert(port, id, dst);
    }
  }

  pub fn subscribe_by_label(
    &mut self,
    store: &mut impl EdgeSetStore,
    ctx: &mut impl EdgeSetEvents,
    label: u64,
    port: u64,
  ) {
    insert(&mut self.by_label, label, port);
    for (id, (src, dst)) in self.src_dst_by_label(store, label) {
      ctx.by_label_insert(port, id, src, dst);
    }
  }

  pub fn subscribe_by_label_dst(
    &mut self,
    store: &mut impl EdgeSetStore,
    ctx: &mut impl EdgeSetEvents,
    label: u64,
    dst: u128,
    port: u64,
  ) {
    insert(&mut self.by_label_dst, (label, dst), port);
    for (id, src) in self.src_by_label_dst(store, label, dst) {
      ctx.by_label_dst_insert(port, id, src);
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

  pub fn unsubscribe_by_label_dst(&mut self, label: u64, dst: u128, port: u64) {
    remove(&mut self.by_label_dst, (label, dst), &port);
  }

  fn notify(
    &mut self,
    ctx: &mut impl EdgeSetEvents,
    id: u128,
    prev: Option<(u128, u64, u128)>,
    curr: Option<(u128, u64, u128)>,
  ) {
    if prev != curr {
      if let Some(ports) = self.by_id.get(&id) {
        for &port in ports {
          ctx.by_id_update(port, curr);
        }
      }
      if let Some((src, label, dst)) = prev {
        if let Some(ports) = self.by_src_label.get(&(src, label)) {
          for &port in ports {
            ctx.by_src_label_remove(port, id, dst);
          }
        }
        if let Some(ports) = self.by_label.get(&label) {
          for &port in ports {
            ctx.by_label_remove(port, id, src, dst);
          }
        }
        if let Some(ports) = self.by_label_dst.get(&(label, dst)) {
          for &port in ports {
            ctx.by_label_dst_remove(port, id, src);
          }
        }
      }
      if let Some((src, label, dst)) = curr {
        if let Some(ports) = self.by_src_label.get(&(src, label)) {
          for &port in ports {
            ctx.by_src_label_insert(port, id, dst);
          }
        }
        if let Some(ports) = self.by_label.get(&label) {
          for &port in ports {
            ctx.by_label_insert(port, id, src, dst);
          }
        }
        if let Some(ports) = self.by_label_dst.get(&(label, dst)) {
          for &port in ports {
            ctx.by_label_dst_insert(port, id, src);
          }
        }
      }
    }
  }
}
