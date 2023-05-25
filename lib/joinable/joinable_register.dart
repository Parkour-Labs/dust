import 'joinable.dart';

/// Total order with a minimum element.
///
/// Implementation should satisfy the following properties:
///
/// - `(T, ≤)` is totally ordered set
/// - `∀ t ∈ T, min() ≤ t`
class TotalOrderMin<T> {
  final bool Function(T x, T y) le;
  final T Function() min;

  const TotalOrderMin({
    required this.le,
    required this.min,
  });
}

/// `int` is an instance of [TotalOrderMin].
const instIntTotalOrderMin = TotalOrderMin<int>(le: _intLe, min: _intMin);
bool _intLe(int x, int y) => x <= y;
int _intMin() => -9223372036854775808;

/// `double` is an instance of [TotalOrderMin].
const instDoubleTotalOrderMin = TotalOrderMin<double>(le: _doubleLe, min: _doubleMin);
bool _doubleLe(double x, double y) => x <= y;
double _doubleMin() => double.negativeInfinity;

/// A last-writer-win register.
class JoinableRegister<T> {
  final T value;
  final int timeStamp;

  const JoinableRegister(this.value, this.timeStamp);

  static bool le<T>(TotalOrderMin<T> order, JoinableRegister<T> x, JoinableRegister<T> y) {
    if (x.timeStamp != y.timeStamp) return x.timeStamp < y.timeStamp;
    return order.le(x.value, y.value);
  }

  static JoinableRegister<T> max<T>(TotalOrderMin<T> order, JoinableRegister<T> x, JoinableRegister<T> y) {
    if (x.timeStamp != y.timeStamp) return x.timeStamp < y.timeStamp ? y : x;
    return order.le(x.value, y.value) ? y : x;
  }

  /// [JoinableRegister] is an instance of [TotalOrderMin].
  static TotalOrderMin<JoinableRegister<T>> instTotalOrderMin<T>(TotalOrderMin<T> order) {
    return TotalOrderMin(
      le: (x, y) => le(order, x, y),
      min: () => JoinableRegister(order.min(), _intMin()),
    );
  }

  /// [JoinableRegister] is an instance of [Joinable].
  static Joinable<JoinableRegister<T>, JoinableRegister<T>> instJoinable<T>(TotalOrderMin<T> order) {
    return Joinable(
      apply: (s, a) => max(order, s, a),
      id: () => JoinableRegister(order.min(), _intMin()),
      comp: (a, b) => max(order, a, b),
      le: (s, t) => le(order, s, t),
      join: (s, a) => max(order, s, a),
    );
  }

  /// [JoinableRegister] is an instance of [DeltaJoinable].
  static DeltaJoinable<JoinableRegister<T>, JoinableRegister<T>> instDeltaJoinable<T>(TotalOrderMin<T> order) {
    final base = instJoinable(order);
    return DeltaJoinable(
      apply: base.apply,
      id: base.id,
      comp: base.comp,
      le: base.le,
      join: base.join,
      deltaJoin: (s, a, b) => max(order, max(order, s, a), b),
    );
  }

  /// [JoinableRegister] is an instance of [GammaJoinable].
  static GammaJoinable<JoinableRegister<T>, JoinableRegister<T>> instGammaJoinable<T>(TotalOrderMin<T> order) {
    final base = instJoinable(order);
    return GammaJoinable(
      apply: base.apply,
      id: base.id,
      comp: base.comp,
      le: base.le,
      join: base.join,
      gammaJoin: (s, a) => max(order, s, a),
    );
  }
}
