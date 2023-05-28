use super::joinable;

/// Total order with a minimum element.
///
/// Implementation should satisfy the following properties:
///
/// - `(T, ≤)` is totally ordered set
/// - `∀ t ∈ T, min() ≤ t`
pub trait OrdMin: Ord {
  fn minimum() -> Self;
}

/// Timestamp type.
type Clock = u64;

/// [Clock] is an instance of [OrdMin].
impl OrdMin for Clock {
  fn minimum() -> Self {
    Clock::MIN
  }
}

/// A last-writer-win register.
#[derive(PartialEq, Eq, PartialOrd, Ord, Clone)]
struct JoinableRegister<T: OrdMin + Clone> {
  clock: Clock,
  value: T,
}

/// [JoinableRegister] is an instance of [OrdMin].
impl<T: OrdMin + Clone> OrdMin for JoinableRegister<T> {
  fn minimum() -> Self {
    JoinableRegister {
      clock: Clock::minimum(),
      value: T::minimum(),
    }
  }
}

impl<T: OrdMin + Clone> joinable::Basic<JoinableRegister<T>, JoinableRegister<T>> for JoinableRegister<T> {
  fn apply(s: JoinableRegister<T>, a: &JoinableRegister<T>) -> JoinableRegister<T> {
    if &s <= a {
      s
    } else {
      a.clone()
    }
  }
  fn id() -> JoinableRegister<T> {
    Self::minimum()
  }
  fn comp(a: JoinableRegister<T>, b: JoinableRegister<T>) -> JoinableRegister<T> {
    a.max(b)
  }
}

impl<T: OrdMin + Clone> joinable::Joinable<JoinableRegister<T>, JoinableRegister<T>> for JoinableRegister<T> {
  fn le(s: &JoinableRegister<T>, t: &JoinableRegister<T>) -> bool {
    s <= t
  }
  fn join(s: JoinableRegister<T>, t: JoinableRegister<T>) -> JoinableRegister<T> {
    s.max(t)
  }
}
