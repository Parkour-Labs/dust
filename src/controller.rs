//! Γ-joinable (including CRDT) sync protocol:
//!
//! - Send ours replica ID
//! - Recv theirs replica ID
//! - Send ours last-seen time stamp for theirs (`T`)
//! - Recv theirs last-seen time stamp for ours (`T'`)
//! - Send ours delta (from `T'`)
//! - Recv theirs delta (from `T`)
//! - **Γ-join**, update `T`
//! - Send acknowledgement
//! - Recv acknowledgement (proof of their `T'` updated)
//! - Establish real-time mode
//!   - Notify about ours new deltas, recv ack (proof of their `T'` updated)
//!   - Listen to theirs new deltas, **Γ-join**, update `T`, ack
//!
//! Δ-joinable and restorable (including OT) sync protocol:
//!
//! - (TODO)
