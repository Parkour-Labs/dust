/// ----------------------------------------------------------------------------
///
/// To understand the code below, please refer to the
/// [core theory](docs/state-management-theory.pdf).
///
/// (Sorry, I have almost surely made this way too formal...)
///
/// ----------------------------------------------------------------------------

/// An instance of `Basic<S, A>` is a "proof" that `(S, A)` forms a **state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, apply(s, id()) == s`
/// - `∀ s ∈ S, ∀ a b ∈ A, apply(apply(s, a), b) == apply(s, comp(a, b))`
///
/// For performance reasons, arguments to `apply` and `comp` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
abstract class Basic<S, A> {
  S apply(S s, A a);
  A id();
  A comp(A a, A b);
}

/// Product of state spaces: `(S, A) × (T, B)`.
class BasicProd<S, A, SA extends Basic<S, A>, T, B, TB extends Basic<T, B>> implements Basic<(S, T), (A, B)> {
  final SA sa;
  final TB tb;

  const BasicProd(this.sa, this.tb);

  @override
  apply(s, a) => (sa.apply(s.$1, a.$1), tb.apply(s.$2, a.$2));

  @override
  id() => (sa.id(), tb.id());

  @override
  comp(a, b) => (sa.comp(a.$1, b.$1), tb.comp(a.$2, b.$2));
}

/// Iterated product of state spaces: `I → (S, A)`.
///
/// Since `I` can be very large, a default state `initial ∈ S` is assumed.
class BasicPi<I, S, A, SA extends Basic<S, A>> implements Basic<Map<I, S>, Map<I, A>> {
  final SA sa;
  final S Function() initial;

  const BasicPi(this.sa, this.initial);

  @override
  apply(s, a) {
    for (final entry in a.entries) {
      final i = entry.key;
      final ai = entry.value;
      s[i] = sa.apply(s[i] ?? initial(), ai);
    }
    return s;
  }

  @override
  id() => {};

  @override
  comp(a, b) {
    for (final entry in b.entries) {
      final i = entry.key;
      final ai = a[i];
      final bi = entry.value;
      a[i] = (ai == null) ? bi : sa.comp(ai, bi);
    }
    return a;
  }
}

/// An instance of `Joinable<S, A>` is a "proof" that `(S, A)` forms a **joinable state space**.
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
abstract class Joinable<S, A> extends Basic<S, A> {
  bool le(S s, S t);
  S join(S s, S t);
}

/// Product of joinable state spaces: `(S, A) × (T, B)`.
class JoinableProd<S, A, SA extends Joinable<S, A>, T, B, TB extends Joinable<T, B>>
    extends BasicProd<S, A, SA, T, B, TB> implements Joinable<(S, T), (A, B)> {
  const JoinableProd(super.sa, super.tb);

  @override
  le(s, t) => sa.le(s.$1, t.$1) && tb.le(s.$2, t.$2);

  @override
  join(s, t) => (sa.join(s.$1, t.$1), tb.join(s.$2, t.$2));
}

/// Iterated product of joinable state spaces: `I → (S, A)`.
///
/// Since `I` can be very large, a default state `initial ∈ S` is assumed.
/// This must be the **minimum element**:
///
/// - `∀ s ∈ S, initial ≤ s`
class JoinablePi<I, S, A, SA extends Joinable<S, A>> extends BasicPi<I, S, A, SA>
    implements Joinable<Map<I, S>, Map<I, A>> {
  const JoinablePi(super.sa, super.initial);

  @override
  le(s, t) {
    for (final entry in s.entries) {
      final i = entry.key;
      final si = entry.value;
      final ti = t[i] ?? initial();
      if (!sa.le(si, ti)) return false;
    }
    return true;
  }

  @override
  join(s, t) {
    for (final entry in t.entries) {
      final i = entry.key;
      final si = s[i];
      final ti = entry.value;
      s[i] = (si == null) ? ti : sa.join(si, ti);
    }
    return s;
  }
}

/// An instance of `DeltaJoinable<S, A>` is a "proof" that `(S, A)` forms a **Δ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, ∀ a b ∈ A, deltaJoin(s, a, b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
///
/// For performance reasons, arguments to `deltaJoin` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
abstract class DeltaJoinable<S, A> extends Joinable<S, A> {
  S deltaJoin(S s, A a, A b);
}

/// Product of Δ-joinable state spaces: `(S, A) × (T, B)`.
class DeltaJoinableProd<S, A, SA extends DeltaJoinable<S, A>, T, B, TB extends DeltaJoinable<T, B>>
    extends JoinableProd<S, A, SA, T, B, TB> implements DeltaJoinable<(S, T), (A, B)> {
  const DeltaJoinableProd(super.sa, super.tb);
  
  @override
  deltaJoin(s, a, b) => (sa.deltaJoin(s.$1, a.$1, b.$1), tb.deltaJoin(s.$2, a.$2, b.$2));
}

/// Iterated product of Δ-joinable state spaces: `I → (S, A)`.
class DeltaJoinablePi<I, S, A, SA extends DeltaJoinable<S, A>> extends JoinablePi<I, S, A, SA>
    implements DeltaJoinable<Map<I, S>, Map<I, A>> {
  const DeltaJoinablePi(super.sa, super.initial);

  @override
  deltaJoin(s, a, b) {
    for (final entry in a.entries) {
      final i = entry.key;
      final ai = entry.value;
      final bi = b[i] ?? sa.id();
      final si = s[i] ?? initial();
      s[i] = sa.deltaJoin(si, ai, bi);
    }
    for (final entry in b.entries) {
      final i = entry.key;
      if (a.containsKey(i)) continue;
      final bi = entry.value;
      final si = s[i] ?? initial();
      s[i] = sa.apply(si, bi);
    }
    return s;
  }
}

/// An instance of `GammaJoinable<S, A>` is a "proof" that `(S, A)` forms a **Γ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, ∀ a b ∈ A, gammaJoin(apply(s, a), b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
///
/// For performance reasons, arguments to `gammaJoin` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
abstract class GammaJoinable<S, A> extends Joinable<S, A> {
  S gammaJoin(S s, A a);
}

/// Product of Γ-joinable state spaces: `(S, A) × (T, B)`.
class GammaJoinableProd<S, A, SA extends GammaJoinable<S, A>, T, B, TB extends GammaJoinable<T, B>>
    extends JoinableProd<S, A, SA, T, B, TB> implements GammaJoinable<(S, T), (A, B)> {
  GammaJoinableProd(super.sa, super.tb);
  
  @override
  gammaJoin(s, a) => (sa.gammaJoin(s.$1, a.$1), tb.gammaJoin(s.$2, a.$2));
}

/// Iterated product of Γ-joinable state spaces: `I → (S, A)`.
class GammaJoinablePi<I, S, A, SA extends GammaJoinable<S, A>> extends JoinablePi<I, S, A, SA>
    implements GammaJoinable<Map<I, S>, Map<I, A>> {
  GammaJoinablePi(super.sa, super.initial);
  
  @override
  gammaJoin(s, a) {
    for (final entry in a.entries) {
      final i = entry.key;
      final ai = entry.value;
      final si = s[i] ?? initial();
      s[i] = sa.gammaJoin(si, ai);
    }
    return s;
  }
}
