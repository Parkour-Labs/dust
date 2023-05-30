use rand::Rng;
use uuid::Uuid;

use super::*;

/// Trait alias for hash map indices.
pub trait Index: Copy + Eq + Hash {}

/// Total order with a minimum element.
///
/// Implementation should satisfy the following properties:
///
/// - `(T, ≤)` is totally ordered set
/// - `∀ t ∈ T, minimum() ≤ t`
pub trait Minimum: Ord {
  fn minimum() -> Self;
}

/// [Option] of totally-ordered types are instances of [Minimum].
/// See: https://doc.rust-lang.org/stable/core/option/index.html#comparison-operators
impl<T: Ord> Minimum for Option<T> {
  fn minimum() -> Self {
    None
  }
}

/// Integer numerics are instances of [Minimum].
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

impl<T: Clone + Minimum> State<Self> for T {
  fn initial() -> Self {
    Self::minimum()
  }
  fn apply(s: Self, a: &Self) -> Self {
    s.max(a.clone())
  }
  fn id() -> Self {
    Self::minimum()
  }
  fn comp(a: Self, b: Self) -> Self {
    a.max(b)
  }
}

impl<T: Clone + Minimum> Joinable<Self> for T {
  fn preq(s: &Self, t: &Self) -> bool {
    s <= t
  }
  fn join(s: Self, t: Self) -> Self {
    s.max(t)
  }
}

impl<T: Clone + Minimum> DeltaJoinable<Self> for T {
  fn delta_join(s: Self, a: &Self, b: &Self) -> Self {
    s.max(a.clone()).max(b.clone())
  }
}

impl<T: Clone + Minimum> GammaJoinable<Self> for T {
  fn gamma_join(s: Self, a: &Self) -> Self {
    s.max(a.clone())
  }
}

/// Newtype for identifiers.
#[derive(Clone, Copy, PartialEq, Eq)]
pub struct Id(u128);

impl Id {
  pub fn get(&self) -> u128 {
    self.0
  }
  pub fn new(value: u128) -> Self {
    Self(value)
  }
  pub fn random() -> Self {
    Self(rand::thread_rng().gen())
  }
  pub fn uuid() -> Self {
    Self(Uuid::new_v4().as_u128())
  }
}

/// Newtype for time stamps.
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Clock(u64);

impl Clock {}

impl Minimum for Clock {
  fn minimum() -> Self {
    Self(u64::minimum())
  }
}
