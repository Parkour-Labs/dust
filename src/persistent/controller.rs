//! A controller controls one replica of data.
//!
//! `Γ`-joinable (CRDT) sync protocol:
//!
//! 1. Send ours state-of-knowledge vector `T` (i.e. last action time stamp for each replica ID);
//! 2. Recv theirs state-of-knowledge vector `T'`;
//! 3. Send ours new knowledge (from `> T'` or fall back to whole state);
//! 4. Recv theirs new knowledge (from `> T` or fall back to whole state);
//! 5. | `Γ`-join, update `T` (in-memory and database);
//! 6. | If anything updated in step 5, broadcast new knowledge to all active peers (can omit the originator);
//! 7. | If received any new knowledge from other peers since step 3, send to them (now they are considered "active");
//! 8. Enter real-time mode:
//!   - Invariant: we have informed all "active" peers with our latest knowledge;
//!   - On recv new knowledge from any peer: `Γ`-join, update `T`, if updated then broadcast (can omit the originator);
//! Invariant: every known mod is sent to every peer, and mods for the same replica are sent in causal order.

use std::{cell::RefCell, collections::HashMap};

use crate::joinable::{Clock, GammaJoinable};

pub type ReplicaId = u64;

pub trait GammaSynchronizable<T: GammaJoinable> {
  fn state_vector(&self) -> Vec<(ReplicaId, Clock)>;
  fn actions_after(&self, state_vector: &[(ReplicaId, Clock)]) -> Vec<(Clock, T::Action)>;
  fn apply_actions(&mut self, action: &[(Clock, T::Action)]) -> bool;
}
