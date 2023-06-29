//! # Note
//!
//! `Γ`-joinable (CRDT) sync protocol:
//!
//! 1. Send ours state-of-knowledge vector `T` (i.e. last action time stamp for each replica ID);
//! 2. Recv theirs state-of-knowledge vector `T'`;
//! 3. Send ours new knowledge (from `> T'` or fall back to whole state);
//! 4. Recv theirs new knowledge (from `> T` or fall back to whole state);
//! 5. `Γ`-join, update `T` (in-memory and database);
//! 6. If anything updated in step 5, broadcast new knowledge to all active peers (can omit the originator);
//! 7. If received any new knowledge from other peers since step 3, send to them (now they are considered "active");
//! 8. Enter real-time mode:
//!    - Invariant: we have informed all "active" peers with our latest knowledge;
//!    - On recv new knowledge from any peer: `Γ`-join, update `T`, if updated then broadcast (can omit the originator);
//! Invariant: every known mod is sent to every peer, and mods for the same replica are sent in causal order.

pub mod database;
pub mod vector_history;

#[cfg(test)]
mod tests;

use crate::joinable::{Clock, GammaJoinable, Joinable, State};

pub trait Synchronizable<T: Joinable> {
  fn state(&self) -> (Clock, T);
  fn join_state(&mut self, state: &(Clock, T)) -> bool;
}

/// A tuple of (replica ID, clock value, action).
pub type Item<T> = (u64, Clock, <T as State>::Action);

pub trait GammaSynchronizable<T: GammaJoinable> {
  fn state_vector(&self) -> Vec<(u64, Option<Clock>)>;
  fn actions_after(&self, state_vector: &[(u64, Option<Clock>)]) -> Vec<Item<T>>;
  fn gamma_join_actions(&mut self, actions: &[Item<T>]) -> Vec<Item<T>>;
}
