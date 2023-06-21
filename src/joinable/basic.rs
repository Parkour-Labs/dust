use rand::Rng;
use uuid::Uuid;

use super::*;

/// Trait alias for newtypes.
pub trait Newtype: From<Self::Inner> + Into<Self::Inner> + AsRef<Self::Inner> + AsMut<Self::Inner> {
  type Inner;
}

/// Trait alias for hash map indices.
pub trait Index: Copy + Eq + Hash {}
impl<T: Copy + Eq + Hash> Index for T {}

/// Total order with a minimum element.
///
/// Implementation should satisfy the following properties:
///
/// - `(T, ≤)` is totally ordered set
/// - `∀ t ∈ T, minimum() ≤ t`
pub trait Minimum: Ord {
  fn minimum() -> Self;
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

/// [`ByMinimum`] is used to indicate that we wish to implement [`Joinable`]
/// on a type `T` by defining *actions* as *taking minimums*.
///
/// A wrapper type is required here to prevent clashes between multiple
/// typeclass instances (trait implementations). This technique is covered
/// [in the Rust book](https://doc.rust-lang.org/book/ch19-03-advanced-traits.html#using-the-newtype-pattern-to-implement-external-traits-on-external-types),
/// and is also a common practice in Lean Mathlib (e.g. pairs are partially
/// ordered by default, but the `Lex` type constructor creates a new type from
/// the pair type which is lexicographically ordered).
#[repr(transparent)]
#[derive(Clone, PartialEq, Eq, PartialOrd, Ord)]
pub struct ByMinimum<T: Clone + Minimum> {
  pub inner: T,
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

/// Newtype for identifiers.
#[repr(transparent)]
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
#[repr(transparent)]
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
pub struct Clock(u64);

impl Clock {}

impl Minimum for Clock {
  fn minimum() -> Self {
    Self(u64::minimum())
  }
}
