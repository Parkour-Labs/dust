//! ----------------------------------------------------------------------------
//!
//! To understand the code below, please refer to the
//! [core theory](docs/state-management-theory.pdf).
//!
//! (Sorry, I have almost surely made this way too formal...)
//!
//! ----------------------------------------------------------------------------

pub mod graph;
pub mod register;

use std::cmp::Eq;
use std::collections::hash_map::Entry;
use std::collections::HashMap;
use std::hash::Hash;
use std::mem;

/// An instance of [Basic] is a "proof" that `(Self, A)` forms a **state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ Self, apply(s, id()) == s`
/// - `∀ s ∈ Self, ∀ a b ∈ A, apply(apply(s, a), b) == apply(s, comp(a, b))`
///
/// For performance reasons, arguments to `apply` and `comp` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
pub trait Basic<A> {
  fn apply(s: Self, a: &A) -> Self;
  fn id() -> A;
  fn comp(a: A, b: A) -> A;
}

/// Product of state spaces: `(S, A) × (T, B)`.
impl<S: Basic<A>, T: Basic<B>, A, B> Basic<(A, B)> for (S, T) {
  fn apply(s: (S, T), a: &(A, B)) -> (S, T) {
    (S::apply(s.0, &a.0), T::apply(s.1, &a.1))
  }
  fn id() -> (A, B) {
    (S::id(), T::id())
  }
  fn comp(a: (A, B), b: (A, B)) -> (A, B) {
    (S::comp(a.0, b.0), T::comp(a.1, b.1))
  }
}

/*
/// Product of state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! basic_product_variadic {
  ( $($i:tt),* ; $($S:ident),* ; $($A:ident),* ) => {
    impl< $($S: Basic<$A>),* , $($A),* > Basic<( $($A),* )> for ( $($S),* ) {
      fn apply(s: ( $($S),* ), a: &( $($A),* )) -> ( $($S),* ) {
        ( $($S::apply(s.$i, &a.$i)),* )
      }
      fn id() -> ( $($A),* ) {
        ( $($S::id()),* )
      }
      fn comp(a: ( $($A),* ), b: ( $($A),* )) -> ( $($A),* ) {
        ( $($S::comp(a.$i, b.$i)),* )
      }
    }
  };
}
basic_product_variadic!(0, 1; S0, S1; A0, A1);
basic_product_variadic!(0, 1, 2; S0, S1, S2; A0, A1, A2);
basic_product_variadic!(0, 1, 2, 3; S0, S1, S2, S3; A0, A1, A2, A3);
basic_product_variadic!(0, 1, 2, 3, 4; S0, S1, S2, S3, S4; A0, A1, A2, A3, A4);
basic_product_variadic!(0, 1, 2, 3, 4, 5; S0, S1, S2, S3, S4, S5; A0, A1, A2, A3, A4, A5);
basic_product_variadic!(0, 1, 2, 3, 4, 5, 6; S0, S1, S2, S3, S4, S5, S6; A0, A1, A2, A3, A4, A5, A6);
basic_product_variadic!(0, 1, 2, 3, 4, 5, 6, 7; S0, S1, S2, S3, S4, S5, S6, S7; A0, A1, A2, A3, A4, A5, A6, A7);
*/

/// Iterated product of state spaces: `I → (S, A)`.
///
/// Since `I` can be very large, a default state `default ∈ S` is assumed.
impl<I: Copy + Eq + Hash, S: Default + Basic<A>, A> Basic<HashMap<I, A>> for HashMap<I, S> {
  fn apply(mut s: HashMap<I, S>, a: &HashMap<I, A>) -> HashMap<I, S> {
    for (i, ai) in a {
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::take(entry.get_mut()); // See: https://github.com/rust-lang/rfcs/pull/1736
          entry.insert(S::apply(si, ai));
        }
        Entry::Vacant(entry) => {
          entry.insert(S::apply(S::default(), ai));
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
          let ai = mem::replace(entry.get_mut(), S::id());
          entry.insert(S::comp(ai, bi));
        }
        Entry::Vacant(entry) => {
          entry.insert(bi);
        }
      }
    }
    a
  }
}

/// An instance of [Joinable] is a "proof" that `(Self, A)` forms a **joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `(Self, ≼)` is semilattice
/// - `∀ s ∈ Self, ∀ a ∈ A, s ≼ f(s)`
/// - `∀ s t ∈ Self, join(s, t)` is the least upper bound of `s` and `t`
///
/// in addition to the properties of state spaces.
///
/// For performance reasons, arguments to `join` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
pub trait Joinable<A>: Basic<A> {
  fn preq(s: &Self, t: &Self) -> bool;
  fn join(s: Self, t: Self) -> Self;
}

/// Product of joinable state spaces: `(S, A) × (T, B)`.
impl<S: Joinable<A>, T: Joinable<B>, A, B> Joinable<(A, B)> for (S, T) {
  fn preq(s: &(S, T), t: &(S, T)) -> bool {
    S::preq(&s.0, &t.0) && T::preq(&s.1, &t.1)
  }
  fn join(s: (S, T), t: (S, T)) -> (S, T) {
    (S::join(s.0, t.0), T::join(s.1, t.1))
  }
}

/// Iterated product of joinable state spaces: `I → (S, A)`.
///
/// Since `I` can be very large, a default state `default ∈ S` is assumed.
/// This must be the **minimum element**:
///
/// - `∀ s ∈ S, default ≼ s`
impl<I: Copy + Eq + Hash, S: Default + Joinable<A>, A> Joinable<HashMap<I, A>> for HashMap<I, S> {
  fn preq(s: &HashMap<I, S>, t: &HashMap<I, S>) -> bool {
    let default = S::default();
    for (i, si) in s {
      let ti = t.get(i).unwrap_or(&default);
      if !S::preq(si, ti) {
        return false;
      }
    }
    true
  }
  fn join(mut s: HashMap<I, S>, t: HashMap<I, S>) -> HashMap<I, S> {
    for (i, ti) in t {
      match s.entry(i) {
        Entry::Occupied(mut entry) => {
          let si = mem::take(entry.get_mut());
          entry.insert(S::join(si, ti));
        }
        Entry::Vacant(entry) => {
          entry.insert(ti);
        }
      }
    }
    s
  }
}

/// An instance of [DeltaJoinable] is a "proof" that `(Self, A)` forms a **Δ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ Self, ∀ a b ∈ A, delta_join(s, a, b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
///
/// For performance reasons, arguments to `delta_join` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
pub trait DeltaJoinable<A>: Joinable<A> {
  fn delta_join(s: Self, a: &A, b: &A) -> Self;
}

/// Product of Δ-joinable state spaces: `(S, A) × (T, B)`.
impl<S: DeltaJoinable<A>, T: DeltaJoinable<B>, A, B> DeltaJoinable<(A, B)> for (S, T) {
  fn delta_join(s: (S, T), a: &(A, B), b: &(A, B)) -> (S, T) {
    (S::delta_join(s.0, &a.0, &b.0), T::delta_join(s.1, &a.1, &b.1))
  }
}

/// Iterated product of Δ-joinable state spaces: `I → (S, A)`.
impl<I: Copy + Eq + Hash, S: Default + DeltaJoinable<A>, A> DeltaJoinable<HashMap<I, A>> for HashMap<I, S> {
  fn delta_join(mut s: HashMap<I, S>, a: &HashMap<I, A>, b: &HashMap<I, A>) -> HashMap<I, S> {
    let id = S::id();
    for (i, ai) in a {
      let bi = b.get(i).unwrap_or(&id);
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::take(entry.get_mut());
          entry.insert(S::delta_join(si, ai, bi));
        }
        Entry::Vacant(entry) => {
          entry.insert(S::delta_join(S::default(), ai, bi));
        }
      }
    }
    for (i, bi) in b {
      if a.contains_key(i) {
        continue;
      }
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::take(entry.get_mut());
          entry.insert(S::delta_join(si, &id, bi));
        }
        Entry::Vacant(entry) => {
          entry.insert(S::delta_join(S::default(), &id, bi));
        }
      }
    }
    s
  }
}

/// An instance of [GammaJoinable] is a "proof" that `(Self, A)` forms a **Γ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ Self, ∀ a b ∈ A, gamma_join(apply(s, a), b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
///
/// For performance reasons, arguments to `gamma_join` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
pub trait GammaJoinable<A>: Joinable<A> {
  fn gamma_join(s: Self, a: &A) -> Self;
}

/// Product of Γ-joinable state spaces: `(S, A) × (T, B)`.
impl<S: GammaJoinable<A>, T: GammaJoinable<B>, A, B> GammaJoinable<(A, B)> for (S, T) {
  fn gamma_join(s: (S, T), a: &(A, B)) -> (S, T) {
    (S::gamma_join(s.0, &a.0), T::gamma_join(s.1, &a.1))
  }
}

/// Iterated product of Γ-joinable state spaces: `I → (S, A)`.
impl<I: Copy + Eq + Hash, S: Default + GammaJoinable<A>, A> GammaJoinable<HashMap<I, A>> for HashMap<I, S> {
  fn gamma_join(mut s: HashMap<I, S>, a: &HashMap<I, A>) -> HashMap<I, S> {
    for (i, ai) in a {
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::take(entry.get_mut());
          entry.insert(S::gamma_join(si, ai));
        }
        Entry::Vacant(entry) => {
          entry.insert(S::gamma_join(S::default(), ai));
        }
      }
    }
    s
  }
}
