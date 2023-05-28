//! ----------------------------------------------------------------------------
//!
//! To understand the code below, please refer to the
//! [core theory](docs/state-management-theory.pdf).
//!
//! (Sorry, I have almost surely made this way too formal...)
//!
//! ----------------------------------------------------------------------------

use std::cmp::Eq;
use std::collections::hash_map::Entry;
use std::collections::HashMap;
use std::hash::Hash;
use std::mem;

/// An instance of [Basic] is a "proof" that `(S, A)` forms a **state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, apply(s, id()) == s`
/// - `∀ s ∈ S, ∀ a b ∈ A, apply(apply(s, a), b) == apply(s, comp(a, b))`
///
/// For performance reasons, arguments to `apply` and `comp` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
pub trait Basic<S, A> {
  fn apply(s: S, a: &A) -> S;
  fn id() -> A;
  fn comp(a: A, b: A) -> A;
}

/// Product of state spaces: `(S, A) × (T, B)`.
impl<S, T, A, B, SA: Basic<S, A>, TB: Basic<T, B>> Basic<(S, T), (A, B)> for (SA, TB) {
  fn apply(s: (S, T), a: &(A, B)) -> (S, T) {
    (SA::apply(s.0, &a.0), TB::apply(s.1, &a.1))
  }
  fn id() -> (A, B) {
    (SA::id(), TB::id())
  }
  fn comp(a: (A, B), b: (A, B)) -> (A, B) {
    (SA::comp(a.0, b.0), TB::comp(a.1, b.1))
  }
}

/// Iterated product of state spaces: `I → (S, A)`.
///
/// Since `I` can be very large, a default state `default ∈ S` is assumed.
impl<I: Copy + Eq + Hash, S: Default, A, SA: Basic<S, A>> Basic<HashMap<I, S>, HashMap<I, A>> for SA {
  fn apply(mut s: HashMap<I, S>, a: &HashMap<I, A>) -> HashMap<I, S> {
    for (i, ai) in a {
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let value = mem::replace(entry.get_mut(), S::default()); // See: https://github.com/rust-lang/rfcs/pull/1736
          entry.insert(SA::apply(value, ai));
        }
        Entry::Vacant(entry) => {
          entry.insert(SA::apply(S::default(), ai));
        }
      };
    }
    s
  }
  fn id() -> HashMap<I, A> {
    HashMap::new()
  }
  fn comp(mut a: HashMap<I, A>, b: HashMap<I, A>) -> HashMap<I, A> {
    for (i, bi) in b {
      match a.entry(i) {
        Entry::Occupied(mut entry) => {
          let value = mem::replace(entry.get_mut(), SA::id());
          entry.insert(SA::comp(value, bi));
        }
        Entry::Vacant(entry) => {
          entry.insert(bi);
        }
      }
    }
    a
  }
}

/// An instance of [Joinable] is a "proof" that `(S, A)` forms a **joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `(S, ≤)` is semilattice
/// - `∀ s ∈ S, ∀ a ∈ A, s ≤ f(s)`
/// - `∀ s t ∈ S, join(s, t)` is the least upper bound of `s` and `t`
///
/// in addition to the properties of state spaces.
///
/// For performance reasons, arguments to `join` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
pub trait Joinable<S, A>: Basic<S, A> {
  fn le(s: &S, t: &S) -> bool;
  fn join(s: S, t: S) -> S;
}

/// Product of joinable state spaces: `(S, A) × (T, B)`.
impl<S, T, A, B, SA: Joinable<S, A>, TB: Joinable<T, B>> Joinable<(S, T), (A, B)> for (SA, TB) {
  fn le(s: &(S, T), t: &(S, T)) -> bool {
    SA::le(&s.0, &t.0) && TB::le(&s.1, &t.1)
  }
  fn join(s: (S, T), t: (S, T)) -> (S, T) {
    (SA::join(s.0, t.0), TB::join(s.1, t.1))
  }
}

/// Iterated product of joinable state spaces: `I → (S, A)`.
///
/// Since `I` can be very large, a default state `default ∈ S` is assumed.
/// This must be the **minimum element**:
///
/// - `∀ s ∈ S, default ≤ s`
impl<I: Copy + Eq + Hash, S: Default, A, SA: Joinable<S, A>> Joinable<HashMap<I, S>, HashMap<I, A>> for SA {
  fn le(s: &HashMap<I, S>, t: &HashMap<I, S>) -> bool {
    let default = S::default();
    for (i, si) in s {
      let ti = t.get(i).unwrap_or(&default);
      if !SA::le(si, ti) {
        return false;
      }
    }
    true
  }
  fn join(mut s: HashMap<I, S>, t: HashMap<I, S>) -> HashMap<I, S> {
    for (i, ti) in t {
      match s.entry(i) {
        Entry::Occupied(mut entry) => {
          let value = mem::replace(entry.get_mut(), S::default());
          entry.insert(SA::join(value, ti));
        }
        Entry::Vacant(entry) => {
          entry.insert(ti);
        }
      }
    }
    s
  }
}

/// An instance of [DeltaJoinable] is a "proof" that `(S, A)` forms a **Δ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, ∀ a b ∈ A, delta_join(s, a, b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
///
/// For performance reasons, arguments to `delta_join` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
trait DeltaJoinable<S, A>: Joinable<S, A> {
  fn delta_join(s: S, a: &A, b: &A) -> S;
}

/// Product of Δ-joinable state spaces: `(S, A) × (T, B)`.
impl<S, A, T, B, SA: DeltaJoinable<S, A>, TB: DeltaJoinable<T, B>> DeltaJoinable<(S, T), (A, B)> for (SA, TB) {
  fn delta_join(s: (S, T), a: &(A, B), b: &(A, B)) -> (S, T) {
    (SA::delta_join(s.0, &a.0, &b.0), TB::delta_join(s.1, &a.1, &b.1))
  }
}

/// Iterated product of Δ-joinable state spaces: `I → (S, A)`.
impl<I: Copy + Eq + Hash, S: Default, A, SA: DeltaJoinable<S, A>> DeltaJoinable<HashMap<I, S>, HashMap<I, A>> for SA {
  fn delta_join(mut s: HashMap<I, S>, a: &HashMap<I, A>, b: &HashMap<I, A>) -> HashMap<I, S> {
    let id = SA::id();
    for (i, ai) in a {
      let bi = b.get(i).unwrap_or(&id);
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::replace(entry.get_mut(), S::default());
          entry.insert(SA::delta_join(si, ai, bi));
        }
        Entry::Vacant(entry) => {
          entry.insert(SA::delta_join(S::default(), ai, bi));
        }
      }
    }
    for (i, bi) in b {
      if a.contains_key(i) {
        continue;
      }
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::replace(entry.get_mut(), S::default());
          entry.insert(SA::delta_join(si, &id, bi));
        }
        Entry::Vacant(entry) => {
          entry.insert(SA::delta_join(S::default(), &id, bi));
        }
      }
    }
    s
  }
}

/// An instance of [GammaJoinable] is a "proof" that `(S, A)` forms a **Γ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, ∀ a b ∈ A, gamma_join(apply(s, a), b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
///
/// For performance reasons, arguments to `gamma_join` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
trait GammaJoinable<S, A>: Joinable<S, A> {
  fn gamma_join(s: S, a: &A) -> S;
}

/// Product of Γ-joinable state spaces: `(S, A) × (T, B)`.
impl<S, A, T, B, SA: GammaJoinable<S, A>, TB: GammaJoinable<T, B>> GammaJoinable<(S, T), (A, B)> for (SA, TB) {
  fn gamma_join(s: (S, T), a: &(A, B)) -> (S, T) {
    (SA::gamma_join(s.0, &a.0), TB::gamma_join(s.1, &a.1))
  }
}

/// Iterated product of Γ-joinable state spaces: `I → (S, A)`.
impl<I: Copy + Eq + Hash, S: Default, A, SA: GammaJoinable<S, A>> GammaJoinable<HashMap<I, S>, HashMap<I, A>> for SA {
  fn gamma_join(mut s: HashMap<I, S>, a: &HashMap<I, A>) -> HashMap<I, S> {
    for (i, ai) in a {
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::replace(entry.get_mut(), S::default());
          entry.insert(SA::gamma_join(si, ai));
        }
        Entry::Vacant(entry) => {
          entry.insert(SA::gamma_join(S::default(), ai));
        }
      }
    }
    s
  }
}
