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
  fn apply(&mut self, a: &Self::Action) {
    T::Inner::apply(self.as_mut(), a)
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
  fn preq(&self, t: &Self) -> bool {
    T::Inner::preq(self.as_ref(), t.as_ref())
  }
  fn join(&mut self, t: Self) {
    T::Inner::join(self.as_mut(), t.into())
  }
}

/// Newtype of delta-joinable state spaces.
impl<T: Newtype> DeltaJoinable for T
where
  T::Inner: DeltaJoinable,
{
  fn delta_join(&mut self, a: &Self::Action, b: &Self::Action) {
    T::Inner::delta_join(self.as_mut(), a, b)
  }
}

/// Newtype of gamma-joinable state spaces.
impl<T: Newtype> GammaJoinable for T
where
  T::Inner: GammaJoinable,
{
  fn gamma_join(&mut self, a: &Self::Action) {
    T::Inner::gamma_join(self.as_mut(), a)
  }
}

/// Newtype of restorable state spaces.
impl<T: Newtype> Restorable for T
where
  T::Inner: Restorable,
{
  type RestorePoint = <T::Inner as Restorable>::RestorePoint;
  fn mark(&self) -> Self::RestorePoint {
    T::Inner::mark(self.as_ref())
  }
  fn restore(&mut self, m: Self::RestorePoint) -> Self::Action {
    T::Inner::restore(self.as_mut(), m)
  }
}

/// Product of state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_state_for_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: State),* > State for ( $($S),* ) {
      type Action = ( $($S::Action),* );
      fn initial() -> Self {
        ( $($S::initial()),* )
      }
      fn apply(&mut self, a: &Self::Action) {
        $($S::apply(&mut self.$i, &a.$i);)*
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
macro_rules! impl_joinable_for_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: Joinable),* > Joinable for ( $($S),* ) {
      fn preq(&self, t: &Self) -> bool {
        $($S::preq(&self.$i, &t.$i))&&*
      }
      fn join(&mut self, t: Self) {
        $($S::join(&mut self.$i, t.$i);)*
      }
    }
  };
}

/// Product of Δ-joinable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_delta_joinable_for_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: DeltaJoinable),* > DeltaJoinable for ( $($S),* ) {
      fn delta_join(&mut self, a: &Self::Action, b: &Self::Action) {
        $($S::delta_join(&mut self.$i, &a.$i, &b.$i);)*
      }
    }
  };
}

/// Product of Γ-joinable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_gamma_joinable_for_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: GammaJoinable),* > GammaJoinable for ( $($S),* ) {
      fn gamma_join(&mut self, a: &Self::Action) {
        $($S::gamma_join(&mut self.$i, &a.$i);)*
      }
    }
  };
}

/// Product of restorable state spaces: `(S1, A1) × ... × (Sn, An)`.
macro_rules! impl_restorable_for_product {
  ( $($i:tt),* ; $($S:ident),* ) => {
    impl< $($S: Restorable),* > Restorable for ( $($S),* ) {
      type RestorePoint = ( $($S::RestorePoint),* );
      fn mark(&self) -> Self::RestorePoint {
        ( $($S::mark(&self.$i)),* )
      }
      fn restore(&mut self, m: Self::RestorePoint) -> Self::Action {
        ( $($S::restore(&mut self.$i, m.$i)),* )
      }
    }
  };
}

impl_state_for_product!(0, 1; S0, S1);
impl_state_for_product!(0, 1, 2; S0, S1, S2);
impl_state_for_product!(0, 1, 2, 3; S0, S1, S2, S3);

impl_joinable_for_product!(0, 1; S0, S1);
impl_joinable_for_product!(0, 1, 2; S0, S1, S2);
impl_joinable_for_product!(0, 1, 2, 3; S0, S1, S2, S3);

impl_delta_joinable_for_product!(0, 1; S0, S1);
impl_delta_joinable_for_product!(0, 1, 2; S0, S1, S2);
impl_delta_joinable_for_product!(0, 1, 2, 3; S0, S1, S2, S3);

impl_gamma_joinable_for_product!(0, 1; S0, S1);
impl_gamma_joinable_for_product!(0, 1, 2; S0, S1, S2);
impl_gamma_joinable_for_product!(0, 1, 2, 3; S0, S1, S2, S3);

impl_restorable_for_product!(0, 1; S0, S1);
impl_restorable_for_product!(0, 1, 2; S0, S1, S2);
impl_restorable_for_product!(0, 1, 2, 3; S0, S1, S2, S3);

/// Iterated product of state spaces: `I → (S, A)`.
impl<I: Index, S: State> State for HashMap<I, S> {
  type Action = HashMap<I, S::Action>;
  fn initial() -> Self {
    HashMap::new()
  }
  fn apply(&mut self, a: &Self::Action) {
    for (i, ai) in a {
      S::apply(self.entry(*i).or_insert(S::initial()), ai);
    }
  }
  fn id() -> Self::Action {
    HashMap::new()
  }
  fn comp(mut a: Self::Action, b: Self::Action) -> Self::Action {
    for (i, bi) in b {
      let curr = S::comp(a.remove(&i).unwrap_or(S::id()), bi);
      a.insert(i, curr);
    }
    a
  }
}

/// Iterated product of joinable state spaces: `I → (S, A)`.
impl<I: Index, S: Joinable> Joinable for HashMap<I, S> {
  fn preq(&self, t: &HashMap<I, S>) -> bool {
    let initial = S::initial();
    for (i, si) in self {
      let ti = t.get(i).unwrap_or(&initial);
      if !S::preq(si, ti) {
        return false;
      }
    }
    true
  }
  fn join(&mut self, t: HashMap<I, S>) {
    for (i, ti) in t {
      S::join(self.entry(i).or_insert(S::initial()), ti);
    }
  }
}

/// Iterated product of Δ-joinable state spaces: `I → (S, A)`.
impl<I: Index, S: DeltaJoinable> DeltaJoinable for HashMap<I, S> {
  fn delta_join(&mut self, a: &Self::Action, b: &Self::Action) {
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
      if let Some(bi) = mb.get(i) {
        S::delta_join(self.entry(*i).or_insert(S::initial()), ai, bi);
      } else {
        S::delta_join(self.entry(*i).or_insert(S::initial()), ai, &id);
      }
    }
    for (i, bi) in b {
      if !ma.contains_key(i) {
        S::delta_join(self.entry(*i).or_insert(S::initial()), &id, bi);
      }
    }
  }
}

/// Iterated product of Γ-joinable state spaces: `I → (S, A)`.
impl<I: Index, S: GammaJoinable> GammaJoinable for HashMap<I, S> {
  fn gamma_join(&mut self, a: &Self::Action) {
    for (i, ai) in a {
      S::gamma_join(self.entry(*i).or_insert(S::initial()), ai);
    }
  }
}

/// Iterated product of restorable state spaces: `I → (S, A)`.
impl<I: Index, S: Restorable> Restorable for HashMap<I, S> {
  type RestorePoint = HashMap<I, S::RestorePoint>;
  fn mark(&self) -> Self::RestorePoint {
    self.iter().map(|(i, si)| (*i, S::mark(si))).collect()
  }
  fn restore(&mut self, m: Self::RestorePoint) -> Self::Action {
    let mut keys: HashSet<I> = self.keys().copied().collect();
    let mut res = HashMap::new();
    for (i, mi) in m {
      res.insert(i, S::restore(self.entry(i).or_insert(S::initial()), mi));
      keys.remove(&i);
    }
    for i in keys {
      if let Some(mut si) = self.remove(&i) {
        res.insert(i, S::restore(&mut si, S::mark(&S::initial())));
      }
    }
    res
  }
}

/// [`String`] is instance of [`Minimum`].
impl Minimum for String {
  fn minimum() -> Self {
    String::new()
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
macro_rules! impl_minimum_for_numeric {
  ( $T:ty ) => {
    impl Minimum for $T {
      fn minimum() -> Self {
        Self::MIN
      }
    }
  };
}

/// Integer numerics are instances of [`Maximum`].
macro_rules! impl_maximum_for_numeric {
  ( $T:ty ) => {
    impl Maximum for $T {
      fn maximum() -> Self {
        Self::MAX
      }
    }
  };
}

impl_minimum_for_numeric!(i8);
impl_minimum_for_numeric!(i16);
impl_minimum_for_numeric!(i32);
impl_minimum_for_numeric!(i64);
impl_minimum_for_numeric!(i128);
impl_minimum_for_numeric!(isize);

impl_minimum_for_numeric!(u8);
impl_minimum_for_numeric!(u16);
impl_minimum_for_numeric!(u32);
impl_minimum_for_numeric!(u64);
impl_minimum_for_numeric!(u128);
impl_minimum_for_numeric!(usize);

impl_maximum_for_numeric!(i8);
impl_maximum_for_numeric!(i16);
impl_maximum_for_numeric!(i32);
impl_maximum_for_numeric!(i64);
impl_maximum_for_numeric!(i128);
impl_maximum_for_numeric!(isize);

impl_maximum_for_numeric!(u8);
impl_maximum_for_numeric!(u16);
impl_maximum_for_numeric!(u32);
impl_maximum_for_numeric!(u64);
impl_maximum_for_numeric!(u128);
impl_maximum_for_numeric!(usize);

/// [`Clock`] is instance of [`Minimum`].
impl Minimum for Clock {
  fn minimum() -> Self {
    Self { measured: Minimum::minimum(), count: Minimum::minimum(), random: Minimum::minimum() }
  }
}

/// [`Clock`] is instance of [`Maximum`].
impl Maximum for Clock {
  fn maximum() -> Self {
    Self { measured: Maximum::maximum(), count: Maximum::maximum(), random: Maximum::maximum() }
  }
}

impl<T: Clone + Minimum> State for ByMax<T> {
  type Action = T;
  fn initial() -> Self {
    Self { inner: Minimum::minimum() }
  }
  fn apply(&mut self, a: &T) {
    self.inner = self.inner.clone().max(a.clone())
  }
  fn id() -> T {
    Minimum::minimum()
  }
  fn comp(a: T, b: T) -> T {
    a.max(b)
  }
}

impl<T: Clone + Minimum> Joinable for ByMax<T> {
  fn preq(&self, t: &Self) -> bool {
    self.inner <= t.inner
  }
  fn join(&mut self, t: Self) {
    self.inner = self.inner.clone().max(t.inner)
  }
}

impl<T: Clone + Minimum> DeltaJoinable for ByMax<T> {
  fn delta_join(&mut self, a: &T, b: &T) {
    self.inner = self.inner.clone().max(a.clone()).max(b.clone())
  }
}

impl<T: Clone + Minimum> GammaJoinable for ByMax<T> {
  fn gamma_join(&mut self, a: &T) {
    self.inner = self.inner.clone().max(a.clone())
  }
}
