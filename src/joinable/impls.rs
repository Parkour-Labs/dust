use super::*;

/// Newtype of state spaces.
impl<T: Newtype> State for T
where
  T::Inner: State,
{
  type Action = <<T as Newtype>::Inner as State>::Action;
  fn initial() -> Self {
    T::Inner::initial().into()
  }
  fn apply(s: Self, a: &Self::Action) -> Self {
    T::Inner::apply(s.into(), a).into()
  }
  fn id() -> Self::Action {
    T::Inner::id()
  }
  fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
    T::Inner::comp(a, b)
  }
}

/// Newtype of joinable state spaces.
impl<T: Newtype> Joinable for T
where
  T::Inner: Joinable,
{
  fn preq(s: &Self, t: &Self) -> bool {
    T::Inner::preq(s.as_ref(), t.as_ref())
  }
  fn join(s: Self, t: Self) -> Self {
    T::Inner::join(s.into(), t.into()).into()
  }
}

/// Newtype of delta-joinable state spaces.
impl<T: Newtype> DeltaJoinable for T
where
  T::Inner: DeltaJoinable,
{
  fn delta_join(s: Self, a: &Self::Action, b: &Self::Action) -> Self {
    T::Inner::delta_join(s.into(), a, b).into()
  }
}

/// Newtype of gamma-joinable state spaces.
impl<T: Newtype> GammaJoinable for T
where
  T::Inner: GammaJoinable,
{
  fn gamma_join(s: Self, a: &Self::Action) -> Self {
    T::Inner::gamma_join(s.into(), a).into()
  }
}

/// Newtype of restorable state spaces.
impl<T: Newtype> Restorable for T
where
  T::Inner: Restorable,
{
  type RestorePoint = <T::Inner as Restorable>::RestorePoint;
  fn mark(s: &Self) -> Self::RestorePoint {
    T::Inner::mark(s.as_ref())
  }
  fn restore(s: Self, m: Self::RestorePoint) -> (Self::Action, Self) {
    let (a, s) = T::Inner::restore(s.into(), m);
    (a, s.into())
  }
}

/// Product of state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_state_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: State),* > State for ( $($S),* ) {
      type Action = ( $($S::Action),* );
      fn initial() -> Self {
        ( $($S::initial()),* )
      }
      fn apply(s: Self, a: &Self::Action) -> Self {
        ( $($S::apply(s.$i, &a.$i)),* )
      }
      fn id() -> Self::Action {
        ( $($S::id()),* )
      }
      fn comp(a: Self::Action, b: Self::Action) -> Self::Action {
        ( $($S::comp(a.$i, b.$i)),* )
      }
    }
  };
}

/// Product of joinable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_joinable_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: Joinable),* > Joinable for ( $($S),* ) {
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
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: DeltaJoinable),* > DeltaJoinable for ( $($S),* ) {
      fn delta_join(s: Self, a: &Self::Action, b: &Self::Action) -> Self {
        ( $($S::delta_join(s.$i, &a.$i, &b.$i)),* )
      }
    }
  };
}

/// Product of Γ-joinable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_gamma_joinable_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: GammaJoinable),* > GammaJoinable for ( $($S),* ) {
      fn gamma_join(s: Self, a: &Self::Action) -> Self {
        ( $($S::gamma_join(s.$i, &a.$i)),* )
      }
    }
  };
}

/// Product of restorable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_restorable_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: Restorable),* > Restorable for ( $($S),* ) {
      type RestorePoint = ( $($S::RestorePoint),* );
      fn mark(s: &Self) -> Self::RestorePoint {
        ( $($S::mark(&s.$i)),* )
      }
      fn restore(s: Self, m: Self::RestorePoint) -> (Self::Action, Self) {
        let pairs = ( $($S::restore(s.$i, m.$i)),* );
        (( $(pairs.$i.0),* ), ( $(pairs.$i.1),* ))
      }
    }
  };
}

impl_state_product!(0, 1; S0, S1);
impl_state_product!(0, 1, 2; S0, S1, S2);
impl_state_product!(0, 1, 2, 3; S0, S1, S2, S3);

impl_joinable_product!(0, 1; S0, S1);
impl_joinable_product!(0, 1, 2; S0, S1, S2);
impl_joinable_product!(0, 1, 2, 3; S0, S1, S2, S3);

impl_delta_joinable_product!(0, 1; S0, S1);
impl_delta_joinable_product!(0, 1, 2; S0, S1, S2);
impl_delta_joinable_product!(0, 1, 2, 3; S0, S1, S2, S3);

impl_gamma_joinable_product!(0, 1; S0, S1);
impl_gamma_joinable_product!(0, 1, 2; S0, S1, S2);
impl_gamma_joinable_product!(0, 1, 2, 3; S0, S1, S2, S3);

impl_restorable_product!(0, 1; S0, S1);
impl_restorable_product!(0, 1, 2; S0, S1, S2);
impl_restorable_product!(0, 1, 2, 3; S0, S1, S2, S3);

/// Iterated product of state spaces: `I → (S, A)`.
impl<I: Index, S: State> State for HashMap<I, S> {
  type Action = Vec<(I, S::Action)>;
  fn initial() -> Self {
    HashMap::new()
  }
  fn apply(mut s: HashMap<I, S>, a: &Self::Action) -> HashMap<I, S> {
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
  fn id() -> Self::Action {
    Vec::new()
  }
  fn comp(mut a: Self::Action, mut b: Self::Action) -> Self::Action {
    a.append(&mut b);
    a
  }
}

/// Iterated product of joinable state spaces: `I → (S, A)`.
impl<I: Index, S: Joinable> Joinable for HashMap<I, S> {
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
impl<I: Index, S: DeltaJoinable> DeltaJoinable for HashMap<I, S> {
  fn delta_join(mut s: HashMap<I, S>, a: &Self::Action, b: &Self::Action) -> HashMap<I, S> {
    let mut ma = HashMap::<I, &S::Action>::new();
    let mut mb = HashMap::<I, &S::Action>::new();
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
impl<I: Index, S: GammaJoinable> GammaJoinable for HashMap<I, S> {
  fn gamma_join(mut s: HashMap<I, S>, a: &Self::Action) -> HashMap<I, S> {
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
impl<I: Index, S: Restorable> Restorable for HashMap<I, S> {
  type RestorePoint = Vec<(I, S::RestorePoint)>;
  fn mark(s: &Self) -> Self::RestorePoint {
    s.iter().map(|(i, si)| (*i, S::mark(si))).collect()
  }
  fn restore(mut s: Self, m: Self::RestorePoint) -> (Self::Action, Self) {
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

/// [`Option`] of totally-ordered types are instances of [`Minimum`].
/// See: https://doc.rust-lang.org/stable/core/option/index.html#comparison-operators
impl<T: Ord> Minimum for Option<T> {
  fn minimum() -> Self {
    None
  }
}

/// Integer numerics are instances of [`Minimum`].
macro_rules! impl_minimum_numeric {
  ( $T:ty ) => {
    impl Minimum for $T {
      fn minimum() -> Self {
        Self::MIN
      }
    }
  };
}

impl_minimum_numeric!(i8);
impl_minimum_numeric!(i16);
impl_minimum_numeric!(i32);
impl_minimum_numeric!(i64);
impl_minimum_numeric!(i128);
impl_minimum_numeric!(isize);

impl_minimum_numeric!(u8);
impl_minimum_numeric!(u16);
impl_minimum_numeric!(u32);
impl_minimum_numeric!(u64);
impl_minimum_numeric!(u128);
impl_minimum_numeric!(usize);

/// [`Clock`] is instance of [`Minimum`].
impl Minimum for Clock {
  fn minimum() -> Self {
    Self(u64::minimum())
  }
}

impl<T: Clone + Minimum> State for ByMinimum<T> {
  type Action = T;
  fn initial() -> Self {
    Self { inner: T::minimum() }
  }
  fn apply(s: Self, a: &T) -> Self {
    Self { inner: s.inner.max(a.clone()) }
  }
  fn id() -> T {
    T::minimum()
  }
  fn comp(a: T, b: T) -> T {
    a.max(b)
  }
}

impl<T: Clone + Minimum> Joinable for ByMinimum<T> {
  fn preq(s: &Self, t: &Self) -> bool {
    s.inner <= t.inner
  }
  fn join(s: Self, t: Self) -> Self {
    Self { inner: s.inner.max(t.inner) }
  }
}

impl<T: Clone + Minimum> DeltaJoinable for ByMinimum<T> {
  fn delta_join(s: Self, a: &T, b: &T) -> Self {
    Self { inner: s.inner.max(a.clone()).max(b.clone()) }
  }
}

impl<T: Clone + Minimum> GammaJoinable for ByMinimum<T> {
  fn gamma_join(s: Self, a: &T) -> Self {
    Self { inner: s.inner.max(a.clone()) }
  }
}
