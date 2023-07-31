use std::num::Wrapping;

use super::*;

fn apply<T: State>(mut s: T, a: T::Action) -> T {
  s.apply(a);
  s
}

fn join<T: Joinable>(mut s: T, t: T) -> T {
  s.join(t);
  s
}

fn delta_join<T: DeltaJoinable>(mut s: T, a: T::Action, b: T::Action) -> T {
  s.delta_join(a, b);
  s
}

fn gamma_join<T: GammaJoinable>(mut s: T, a: T::Action) -> T {
  s.gamma_join(a);
  s
}

fn rand_string(len: usize) -> String {
  let mut rng = rand::thread_rng();
  let mut res = String::new();
  for _ in 0..rng.gen_range(0..len + 1) {
    res.push(rng.gen())
  }
  res
}

pub fn assert_joinable<T: Joinable + Clone>(
  mut rand_state: impl FnMut() -> T,
  mut rand_action: impl FnMut() -> T::Action,
  mut state_eq: impl FnMut(T, T) -> bool,
  count: usize,
) where
  T::Action: Clone,
{
  for _ in 0..count {
    let s = rand_state();
    let t = rand_state();
    let u = rand_state();
    let a = rand_action();
    let b = rand_action();

    // Properties of state spaces.
    assert!(state_eq(apply(s.clone(), T::id()), s.clone()));
    assert!(state_eq(apply(apply(s.clone(), a.clone()), b.clone()), apply(s.clone(), T::comp(a.clone(), b.clone()))));

    // Properties of joinable state spaces.
    assert!(T::preq(&T::initial(), &s));
    assert!(T::preq(&s, &apply(s.clone(), a.clone())));
    let st = join(s.clone(), t.clone());
    assert!(T::preq(&s, &st));
    assert!(T::preq(&t, &st));
    if T::preq(&s, &u) && T::preq(&t, &u) {
      assert!(T::preq(&st, &u));
    }

    // Properties of joinable state spaces (equivalent, algebraic definition of semilattices).
    assert!(state_eq(join(s.clone(), join(t.clone(), u.clone())), join(join(s.clone(), t.clone()), u.clone())));
    assert!(state_eq(join(s.clone(), t.clone()), join(t.clone(), s.clone())));
    assert!(state_eq(join(s.clone(), s.clone()), s.clone()));
    assert_eq!(T::preq(&s, &t), state_eq(t.clone(), join(s.clone(), t.clone())));
  }
}

pub fn assert_delta_joinable<T: DeltaJoinable + Clone>(
  mut rand_state: impl FnMut() -> T,
  mut rand_action: impl FnMut() -> T::Action,
  mut state_eq: impl FnMut(T, T) -> bool,
  count: usize,
) where
  T::Action: Clone,
{
  for _ in 0..count {
    let s = rand_state();
    let a = rand_action();
    let b = rand_action();

    // Properties of Δ-joinable state spaces.
    assert!(state_eq(
      delta_join(s.clone(), a.clone(), b.clone()),
      join(apply(s.clone(), a.clone()), apply(s.clone(), b.clone()))
    ));
  }
}

pub fn assert_gamma_joinable<T: GammaJoinable + Clone>(
  mut rand_state: impl FnMut() -> T,
  mut rand_action: impl FnMut() -> T::Action,
  mut state_eq: impl FnMut(T, T) -> bool,
  count: usize,
) where
  T::Action: Clone,
{
  for _ in 0..count {
    let s = rand_state();
    let a = rand_action();
    let b = rand_action();

    // Properties of Γ-joinable state spaces.
    assert!(state_eq(
      gamma_join(apply(s.clone(), a.clone()), b.clone()),
      join(apply(s.clone(), a.clone()), apply(s.clone(), b.clone()))
    ));
  }
}

#[test]
fn minimum_maximum_u64_simple() {
  assert_eq!(u64::minimum(), 0);
  assert_eq!(u64::maximum(), (Wrapping(0u64) - Wrapping(1)).0);
}

#[test]
fn by_max_u64_random() {
  type T = ByMax<u64>;
  fn rand_state() -> T {
    ByMax { inner: rand::thread_rng().gen() }
  }
  fn rand_action() -> <T as State>::Action {
    rand::thread_rng().gen()
  }
  assert_eq!(T::initial(), ByMax { inner: 0 });
  assert_joinable::<T>(rand_state, rand_action, |s, t| s == t, 1000);
  assert_delta_joinable::<T>(rand_state, rand_action, |s, t| s == t, 1000);
  assert_gamma_joinable::<T>(rand_state, rand_action, |s, t| s == t, 1000);
}

#[test]
fn joinable_prod2_random() {
  type T = (ByMax<i8>, ByMax<u32>);
  fn rand_state() -> T {
    let mut rng = rand::thread_rng();
    (ByMax { inner: rng.gen() }, ByMax { inner: rng.gen() })
  }
  fn rand_action() -> <T as State>::Action {
    let mut rng = rand::thread_rng();
    (rng.gen(), rng.gen())
  }
  assert_eq!(T::initial(), (ByMax { inner: i8::minimum() }, ByMax { inner: 0 }));
  assert_joinable::<T>(rand_state, rand_action, |s, t| s == t, 1000);
  assert_delta_joinable::<T>(rand_state, rand_action, |s, t| s == t, 1000);
  assert_gamma_joinable::<T>(rand_state, rand_action, |s, t| s == t, 1000);
}

#[test]
fn joinable_prod3_random() {
  type T = (ByMax<String>, ByMax<i8>, ByMax<u32>);
  fn rand_state() -> T {
    let mut rng = rand::thread_rng();
    (ByMax { inner: rand_string(10) }, ByMax { inner: rng.gen() }, ByMax { inner: rng.gen() })
  }
  fn rand_action() -> <T as State>::Action {
    let mut rng = rand::thread_rng();
    (rand_string(10), rng.gen(), rng.gen())
  }
  assert_eq!(T::initial(), (ByMax { inner: String::new() }, ByMax { inner: i8::minimum() }, ByMax { inner: 0 },));
  assert_joinable::<T>(rand_state, rand_action, |s, t| s == t, 100);
  assert_delta_joinable::<T>(rand_state, rand_action, |s, t| s == t, 100);
  assert_gamma_joinable::<T>(rand_state, rand_action, |s, t| s == t, 100);
}

#[test]
fn joinable_prod4_random() {
  type T = (ByMax<Option<()>>, ByMax<String>, ByMax<i8>, ByMax<u32>);
  fn rand_state() -> T {
    let mut rng = rand::thread_rng();
    (
      ByMax { inner: if rng.gen::<bool>() { Some(()) } else { None } },
      ByMax { inner: rand_string(10) },
      ByMax { inner: rng.gen() },
      ByMax { inner: rng.gen() },
    )
  }
  fn rand_action() -> <T as State>::Action {
    let mut rng = rand::thread_rng();
    (if rng.gen::<bool>() { Some(()) } else { None }, rand_string(10), rng.gen(), rng.gen())
  }
  assert_eq!(
    T::initial(),
    (ByMax { inner: None }, ByMax { inner: String::new() }, ByMax { inner: i8::minimum() }, ByMax { inner: 0 },)
  );
  assert_joinable::<T>(rand_state, rand_action, |s, t| s == t, 100);
  assert_delta_joinable::<T>(rand_state, rand_action, |s, t| s == t, 100);
  assert_gamma_joinable::<T>(rand_state, rand_action, |s, t| s == t, 100);
}

#[test]
fn joinable_pi_random() {
  type T = HashMap<u8, ByMax<u8>>;
  fn rand_state() -> T {
    let mut rng = rand::thread_rng();
    let mut res = T::new();
    for _ in 0..rng.gen_range(0..100) {
      res.insert(rng.gen_range(0..100), ByMax { inner: rng.gen_range(0..10) });
    }
    res
  }
  fn rand_action() -> <T as State>::Action {
    let mut rng = rand::thread_rng();
    let mut res = <T as State>::Action::new();
    for _ in 0..rng.gen_range(0..100) {
      res.insert(rng.gen_range(0..100), rng.gen_range(0..10));
    }
    res
  }
  fn state_eq(mut s: T, mut t: T) -> bool {
    for key in s.keys() {
      if !t.contains_key(key) {
        t.insert(*key, State::initial());
      }
    }
    for key in t.keys() {
      if !s.contains_key(key) {
        s.insert(*key, State::initial());
      }
    }
    s == t
  }
  assert!(state_eq(T::initial(), HashMap::from([(233, State::initial())])));
  assert_joinable::<T>(rand_state, rand_action, state_eq, 10);
  assert_delta_joinable::<T>(rand_state, rand_action, state_eq, 10);
  assert_gamma_joinable::<T>(rand_state, rand_action, state_eq, 10);
}
