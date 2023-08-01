//! A tree with pre-order traversal, aka. YATA sequence.

use derive_more::{AsMut, AsRef, From, Into};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use super::Register;
use crate::joinable::Clock;
// use crate::joinable::{Clock, DeltaJoinable, GammaJoinable, Joinable, Minimum, State};

type Inner<T> = HashMap<u64, Register<Option<(u64, Clock, Vec<T>)>>>;

/// A tree with pre-order traversal, aka. YATA sequence.
///
/// - [`Sequence`] is an instance of [`State`] space.
/// - [`Sequence`] is an instance of [`Joinable`] state space.
/// - [`Sequence`] is an instance of [`DeltaJoinable`] state space.
/// - [`Sequence`] is an instance of [`GammaJoinable`] state space.
#[derive(Debug, Clone, From, Into, AsRef, AsMut, Serialize, Deserialize)]
pub struct Sequence<T: Ord> {
  data: Inner<T>,
}

// TODO
// Note: action contains random u64 for node-splitting
