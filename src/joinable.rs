//! ----------------------------------------------------------------------------
//!
//! To understand the code below, please refer to the
//! [core theory](docs/state-management-theory.pdf).
//!
//! (Sorry, I have almost surely made this way too formal...)
//!
//! ----------------------------------------------------------------------------

pub mod basic;
pub mod counter;
pub mod graph;
pub mod register;
pub mod set;

use std::cmp::Eq;
use std::collections::hash_map::Entry;
use std::collections::{HashMap, HashSet};
use std::hash::Hash;
use std::mem;

use basic::Index;

/// An instance of [State] is a "proof" that `(Self, A)` forms a **state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ Self, apply(s, id()) == s`
/// - `∀ s ∈ Self, ∀ a b ∈ A, apply(apply(s, a), b) == apply(s, comp(a, b))`
pub trait State<A> {
  fn initial() -> Self;
  fn apply(s: Self, a: &A) -> Self;
  fn id() -> A;
  fn comp(a: A, b: A) -> A;
}

/// An instance of [Joinable] is a "proof" that `(Self, A)` forms a **joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `(Self, ≼)` is semilattice
/// - `∀ s ∈ Self, initial() ≼ s`
/// - `∀ s ∈ Self, ∀ a ∈ A, s ≼ apply(s, a)`
/// - `∀ s t ∈ Self, join(s, t)` is the least upper bound of `s` and `t`
///
/// in addition to the properties of state spaces.
pub trait Joinable<A>: State<A> {
  fn preq(s: &Self, t: &Self) -> bool;
  fn join(s: Self, t: Self) -> Self;
}

/// An instance of [DeltaJoinable] is a "proof" that `(Self, A)` forms a **Δ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ Self, ∀ a b ∈ A, delta_join(s, a, b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
pub trait DeltaJoinable<A>: Joinable<A> {
  fn delta_join(s: Self, a: &A, b: &A) -> Self;
}

/// An instance of [GammaJoinable] is a "proof" that `(Self, A)` forms a **Γ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ Self, ∀ a b ∈ A, gamma_join(apply(s, a), b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
pub trait GammaJoinable<A>: Joinable<A> {
  fn gamma_join(s: Self, a: &A) -> Self;
}

/// An instance of [Restorable] is a "proof" that `(Self, A)` forms a **restorable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ Self, ∀ a ∈ A, restore(apply(s, a), mark(s)) = (a, s)`
///
/// in addition to the properties of state spaces.
pub trait Restorable<A>: State<A> {
  type Mark;
  fn mark(s: &Self) -> Self::Mark;
  fn restore(s: Self, m: Self::Mark) -> (A, Self);
}

/// Product of state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_state_product {
  ( $($i:tt),* ; $($S:ident),* ; $($A:ident),* ) => {
    impl< $($S: State<$A>),* , $($A),* > State<( $($A),* )> for ( $($S),* ) {
      fn initial() -> Self {
        ( $($S::initial()),* )
      }
      fn apply(s: Self, a: &( $($A),* )) -> Self {
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

/// Product of joinable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_joinable_product {
  ( $($i:tt),* ; $($S:ident),* ; $($A:ident),* ) => {
    impl< $($S: Joinable<$A>),* , $($A),* > Joinable<( $($A),* )> for ( $($S),* ) {
      fn preq(s: &Self, t: &Self) -> bool {
        ( $($S::preq(&s.$i, &t.$i))&&* )
      }
      fn join(s: Self, t: Self) -> Self {
        ( $($S::join(s.$i, t.$i)),* )
      }
    }
  };
}

/// Product of Δ-joinable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_delta_joinable_product {
  ( $($i:tt),* ; $($S:ident),* ; $($A:ident),* ) => {
    impl< $($S: DeltaJoinable<$A>),* , $($A),* > DeltaJoinable<( $($A),* )> for ( $($S),* ) {
      fn delta_join(s: Self, a: &( $($A),* ), b: &( $($A),* )) -> Self {
        ( $($S::delta_join(s.$i, &a.$i, &b.$i)),* )
      }
    }
  };
}

/// Product of Γ-joinable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_gamma_joinable_product {
  ( $($i:tt),* ; $($S:ident),* ; $($A:ident),* ) => {
    impl< $($S: GammaJoinable<$A>),* , $($A),* > GammaJoinable<( $($A),* )> for ( $($S),* ) {
      fn gamma_join(s: Self, a: &( $($A),* )) -> Self {
        ( $($S::gamma_join(s.$i, &a.$i)),* )
      }
    }
  };
}

/// Product of restorable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_restorable_product {
  ( $($i:tt),* ; $($S:ident),* ; $($A:ident),* ) => {
    impl< $($S: Restorable<$A>),* , $($A),* > Restorable<( $($A),* )> for ( $($S),* ) {
      type Mark = ( $($S::Mark),* );
      fn mark(s: &Self) -> Self::Mark {
        ( $($S::mark(&s.$i)),* )
      }
      fn restore(s: Self, m: Self::Mark) -> (( $($A),* ), Self) {
        let pairs = ( $($S::restore(s.$i, m.$i)),* );
        (( $(pairs.$i.0),* ), ( $(pairs.$i.1),* ))
      }
    }
  };
}

impl_state_product!(0, 1; S0, S1; A0, A1);
impl_state_product!(0, 1, 2; S0, S1, S2; A0, A1, A2);
impl_state_product!(0, 1, 2, 3; S0, S1, S2, S3; A0, A1, A2, A3);

impl_joinable_product!(0, 1; S0, S1; A0, A1);
impl_joinable_product!(0, 1, 2; S0, S1, S2; A0, A1, A2);
impl_joinable_product!(0, 1, 2, 3; S0, S1, S2, S3; A0, A1, A2, A3);

impl_delta_joinable_product!(0, 1; S0, S1; A0, A1);
impl_delta_joinable_product!(0, 1, 2; S0, S1, S2; A0, A1, A2);
impl_delta_joinable_product!(0, 1, 2, 3; S0, S1, S2, S3; A0, A1, A2, A3);

impl_gamma_joinable_product!(0, 1; S0, S1; A0, A1);
impl_gamma_joinable_product!(0, 1, 2; S0, S1, S2; A0, A1, A2);
impl_gamma_joinable_product!(0, 1, 2, 3; S0, S1, S2, S3; A0, A1, A2, A3);

impl_restorable_product!(0, 1; S0, S1; A0, A1);
impl_restorable_product!(0, 1, 2; S0, S1, S2; A0, A1, A2);
impl_restorable_product!(0, 1, 2, 3; S0, S1, S2, S3; A0, A1, A2, A3);

/// Iterated product of state spaces: `I → (S, A)`.
impl<I: Index, S: State<A>, A> State<Vec<(I, A)>> for HashMap<I, S> {
  fn initial() -> Self {
    HashMap::new()
  }
  fn apply(mut s: HashMap<I, S>, a: &Vec<(I, A)>) -> HashMap<I, S> {
    for (i, ai) in a {
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::replace(entry.get_mut(), S::initial());
          entry.insert(S::apply(si, ai));
        }
        Entry::Vacant(entry) => {
          entry.insert(S::apply(S::initial(), ai));
        }
      };
    }
    s
  }
  fn id() -> Vec<(I, A)> {
    Vec::new()
  }
  fn comp(mut a: Vec<(I, A)>, mut b: Vec<(I, A)>) -> Vec<(I, A)> {
    a.append(&mut b);
    a
  }
}

/// Iterated product of joinable state spaces: `I → (S, A)`.
impl<I: Index, S: Joinable<A>, A> Joinable<Vec<(I, A)>> for HashMap<I, S> {
  fn preq(s: &HashMap<I, S>, t: &HashMap<I, S>) -> bool {
    let initial = S::initial();
    for (i, si) in s {
      let ti = t.get(i).unwrap_or(&initial);
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
          let si = mem::replace(entry.get_mut(), S::initial());
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

/// Iterated product of Δ-joinable state spaces: `I → (S, A)`.
impl<I: Index, S: DeltaJoinable<A>, A> DeltaJoinable<Vec<(I, A)>> for HashMap<I, S> {
  fn delta_join(mut s: HashMap<I, S>, a: &Vec<(I, A)>, b: &Vec<(I, A)>) -> HashMap<I, S> {
    let mut ma = HashMap::<I, &A>::new();
    let mut mb = HashMap::<I, &A>::new();
    for (i, ai) in a {
      ma.insert(*i, ai);
    }
    for (i, bi) in b {
      mb.insert(*i, bi);
    }
    let id = S::id();
    for (i, ai) in a {
      let bi = *mb.get(i).unwrap_or(&&id);
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::replace(entry.get_mut(), S::initial());
          entry.insert(S::delta_join(si, ai, bi));
        }
        Entry::Vacant(entry) => {
          entry.insert(S::delta_join(S::initial(), ai, bi));
        }
      }
    }
    for (i, bi) in b {
      if ma.contains_key(i) {
        continue;
      }
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::replace(entry.get_mut(), S::initial());
          entry.insert(S::delta_join(si, &id, bi));
        }
        Entry::Vacant(entry) => {
          entry.insert(S::delta_join(S::initial(), &id, bi));
        }
      }
    }
    s
  }
}

/// Iterated product of Γ-joinable state spaces: `I → (S, A)`.
impl<I: Index, S: GammaJoinable<A>, A> GammaJoinable<Vec<(I, A)>> for HashMap<I, S> {
  fn gamma_join(mut s: HashMap<I, S>, a: &Vec<(I, A)>) -> HashMap<I, S> {
    for (i, ai) in a {
      match s.entry(*i) {
        Entry::Occupied(mut entry) => {
          let si = mem::replace(entry.get_mut(), S::initial());
          entry.insert(S::gamma_join(si, ai));
        }
        Entry::Vacant(entry) => {
          entry.insert(S::gamma_join(S::initial(), ai));
        }
      }
    }
    s
  }
}

/// Iterated product of restorable state spaces: `I → (S, A)`.
impl<I: Index, S: Restorable<A>, A> Restorable<Vec<(I, A)>> for HashMap<I, S> {
  type Mark = Vec<(I, S::Mark)>;
  fn mark(s: &Self) -> Self::Mark {
    s.iter().map(|(i, si)| (*i, S::mark(si))).collect()
  }
  fn restore(mut s: Self, m: Self::Mark) -> (Vec<(I, A)>, Self) {
    let mut a = Vec::new();
    let mut is: HashSet<I> = s.keys().copied().collect();
    for (i, mi) in m {
      match s.entry(i) {
        Entry::Occupied(mut entry) => {
          let si = mem::replace(entry.get_mut(), S::initial());
          let (ai, si) = S::restore(si, mi);
          a.push((i, ai));
          entry.insert(si);
        }
        Entry::Vacant(entry) => {
          let (ai, si) = S::restore(S::initial(), mi);
          a.push((i, ai));
          entry.insert(si);
        }
      }
      is.remove(&i);
    }
    let initial = S::initial();
    for i in is {
      if let Some(si) = s.remove(&i) {
        let (ai, _) = S::restore(si, S::mark(&initial));
        a.push((i, ai));
      }
    }
    (a, s)
  }
}
