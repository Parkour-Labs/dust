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

pub mod collection;
pub mod crdt;
pub mod vector_history;

#[cfg(test)]
mod tests;

use rusqlite::Transaction;

pub trait PersistentState {
  type State;
  type Action;
  fn initial(txn: &Transaction, col: &'static str, name: &'static str) -> Self;
  fn apply(&mut self, txn: &Transaction, a: Self::Action);
  fn id() -> Self::Action;
  fn comp(a: Self::Action, b: Self::Action) -> Self::Action;
}

pub trait PersistentJoinable: PersistentState {
  fn preq(&mut self, txn: &Transaction, t: &Self::State) -> bool;
  fn join(&mut self, txn: &Transaction, t: Self::State);
}

pub trait PersistentDeltaJoinable: PersistentJoinable {
  fn delta_join(&mut self, txn: &Transaction, a: Self::Action, b: Self::Action);
}

pub trait PersistentGammaJoinable: PersistentJoinable {
  fn gamma_join(&mut self, txn: &Transaction, a: Self::Action);
}
