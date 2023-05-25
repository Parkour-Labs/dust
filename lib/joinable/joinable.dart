/// ----------------------------------------------------------------------------
///
/// To understand the code below, please refer to the
/// [core theory](docs/state-management-theory.pdf).
///
/// (Sorry, I have almost surely made this way too formal...)
///
/// ----------------------------------------------------------------------------

/// An instance of [Basic] is a "proof" that `(S, A)` forms a **state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, apply(s, id()) == s`
/// - `∀ s ∈ S, ∀ a b ∈ A, apply(apply(s, a), b) == apply(s, comp(a, b))`
///
/// For performance reasons, arguments to `apply` and `comp` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
class Basic<S, A> {
  final S Function(S s, A a) apply;
  final A Function() id;
  final A Function(A a, A b) comp;

  const Basic({
    required this.apply,
    required this.id,
    required this.comp,
  });

  /// Product of state spaces: `(S, A) × (T, B)`.
  static Basic<(S, T), (A, B)> prod<S, A, T, B>(Basic<S, A> sa, Basic<T, B> tb) {
    return Basic(
      apply: (s, a) => (sa.apply(s.$1, a.$1), tb.apply(s.$2, a.$2)),
      id: () => (sa.id(), tb.id()),
      comp: (a, b) => (sa.comp(a.$1, b.$1), tb.comp(a.$2, b.$2)),
    );
  }

  /// Iterated product of state spaces: `I → (S, A)`.
  ///
  /// Since `I` can be very large, a default state `initial ∈ S` is assumed.
  static Basic<Map<I, S>, Map<I, A>> pi<I, S, A>(Basic<S, A> sa, S Function() initial) {
    return Basic(
      apply: (s, a) {
        for (final entry in a.entries) {
          final i = entry.key;
          final ai = entry.value;
          s[i] = sa.apply(s[i] ?? initial(), ai);
        }
        return s;
      },
      id: () => {},
      comp: (a, b) {
        for (final entry in b.entries) {
          final i = entry.key;
          final ai = a[i];
          final bi = entry.value;
          a[i] = (ai == null) ? bi : sa.comp(ai, bi);
        }
        return a;
      },
    );
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
class Joinable<S, A> extends Basic<S, A> {
  final bool Function(S s, S t) le;
  final S Function(S s, S t) join;

  const Joinable({
    required super.apply,
    required super.id,
    required super.comp,
    required this.le,
    required this.join,
  });

  /// Product of joinable state spaces: `(S, A) × (T, B)`.
  static Joinable<(S, T), (A, B)> prod<S, A, T, B>(Joinable<S, A> sa, Joinable<T, B> tb) {
    final base = Basic.prod<S, A, T, B>(sa, tb);
    return Joinable(
      apply: base.apply,
      id: base.id,
      comp: base.comp,
      le: (s, t) => sa.le(s.$1, t.$1) && tb.le(s.$2, t.$2),
      join: (s, t) => (sa.join(s.$1, t.$1), tb.join(s.$2, t.$2)),
    );
  }

  /// Iterated product of joinable state spaces: `I → (S, A)`.
  ///
  /// Since `I` can be very large, a default state `initial ∈ S` is assumed.
  /// This must be the **minimum element**:
  ///
  /// - `∀ s ∈ S, initial ≤ s`
  static Joinable<Map<I, S>, Map<I, A>> pi<I, S, A>(Joinable<S, A> sa, S Function() initial) {
    final base = Basic.pi<I, S, A>(sa, initial);
    return Joinable(
      apply: base.apply,
      id: base.id,
      comp: base.comp,
      le: (s, t) {
        for (final entry in s.entries) {
          final i = entry.key;
          final si = entry.value;
          final ti = t[i] ?? initial();
          if (!sa.le(si, ti)) return false;
        }
        return true;
      },
      join: (s, t) {
        for (final entry in t.entries) {
          final i = entry.key;
          final si = s[i];
          final ti = entry.value;
          s[i] = (si == null) ? ti : sa.join(si, ti);
        }
        return s;
      },
    );
  }
}

/// An instance of [DeltaJoinable] is a "proof" that `(S, A)` forms a **Δ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, ∀ a b ∈ A, deltaJoin(s, a, b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
///
/// For performance reasons, arguments to `deltaJoin` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
class DeltaJoinable<S, A> extends Joinable<S, A> {
  final S Function(S s, A a, A b) deltaJoin;

  const DeltaJoinable({
    required super.apply,
    required super.id,
    required super.comp,
    required super.le,
    required super.join,
    required this.deltaJoin,
  });

  /// Product of Δ-joinable state spaces: `(S, A) × (T, B)`.
  static DeltaJoinable<(S, T), (A, B)> prod<S, A, T, B>(DeltaJoinable<S, A> sa, DeltaJoinable<T, B> tb) {
    final base = Joinable.prod<S, A, T, B>(sa, tb);
    return DeltaJoinable(
      apply: base.apply,
      id: base.id,
      comp: base.comp,
      le: base.le,
      join: base.join,
      deltaJoin: (s, a, b) => (sa.deltaJoin(s.$1, a.$1, b.$1), tb.deltaJoin(s.$2, a.$2, b.$2)),
    );
  }

  /// Iterated product of Δ-joinable state spaces: `I → (S, A)`.
  static DeltaJoinable<Map<I, S>, Map<I, A>> pi<I, S, A>(DeltaJoinable<S, A> sa, S Function() initial) {
    final base = Joinable.pi<I, S, A>(sa, initial);
    return DeltaJoinable(
      apply: base.apply,
      id: base.id,
      comp: base.comp,
      le: base.le,
      join: base.join,
      deltaJoin: (s, a, b) {
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
      },
    );
  }
}

/// An instance of [GammaJoinable] is a "proof" that `(S, A)` forms a **Γ-joinable state space**.
///
/// Implementation should satisfy the following properties:
///
/// - `∀ s ∈ S, ∀ a b ∈ A, gammaJoin(apply(s, a), b) == join(apply(s, a), apply(s, b))`
///
/// in addition to the properties of joinable state spaces.
///
/// For performance reasons, arguments to `gammaJoin` are considered to be **moved**
/// (their values may be changed) and must be **non-overlapping**.
class GammaJoinable<S, A> extends Joinable<S, A> {
  final S Function(S s, A a) gammaJoin;

  const GammaJoinable({
    required super.apply,
    required super.id,
    required super.comp,
    required super.le,
    required super.join,
    required this.gammaJoin,
  });

  /// Product of Γ-joinable state spaces: `(S, A) × (T, B)`.
  static GammaJoinable<(S, T), (A, B)> prod<S, A, T, B>(GammaJoinable<S, A> sa, GammaJoinable<T, B> tb) {
    final base = Joinable.prod<S, A, T, B>(sa, tb);
    return GammaJoinable(
      apply: base.apply,
      id: base.id,
      comp: base.comp,
      le: base.le,
      join: base.join,
      gammaJoin: (s, a) => (sa.gammaJoin(s.$1, a.$1), tb.gammaJoin(s.$2, a.$2)),
    );
  }

  /// Iterated product of Γ-joinable state spaces: `I → (S, A)`.
  static GammaJoinable<Map<I, S>, Map<I, A>> pi<I, S, A>(GammaJoinable<S, A> sa, S Function() initial) {
    final base = Joinable.pi<I, S, A>(sa, initial);
    return GammaJoinable(
      apply: base.apply,
      id: base.id,
      comp: base.comp,
      le: base.le,
      join: base.join,
      gammaJoin: (s, a) {
        for (final entry in a.entries) {
          final i = entry.key;
          final ai = entry.value;
          final si = s[i] ?? initial();
          s[i] = sa.gammaJoin(si, ai);
        }
        return s;
      },
    );
  }
}
