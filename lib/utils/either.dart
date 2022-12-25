import 'package:meta/meta.dart';

/// Immutable sum type. At most one of [left] and [right] is non-null.
@immutable
abstract class Either<L, R> {
  const Either._();

  factory Either.inl(L l) => _Inl._(l);
  factory Either.inr(R r) => _Inr._(r);

  T cases<T>(T Function(L) f, T Function(R) g);

  bool get isLeft;
  bool get isRight;

  L? get left;
  R? get right;

  @override
  bool operator ==(Object other);
  @override
  int get hashCode;

  /// Monad operations for `Either T`.
  static const pure = Either.inr;

  /// Monad operations for `Either T`.
  static Either<T, B> flatMap<T, A, B>(Either<T, A> a, Either<T, B> Function(A) m) =>
      a.cases((l) => Either.inl(l), (r) => m(r));

  /// If [l] is not null, returns [Either.inl], otherwise returns [Either.inr].
  static Either<L, R> itel<L extends Object, R>(L? l, R r) => l != null ? Either.inl(l) : Either.inr(r);

  /// If [r] is not null, returns [Either.inr], otherwise returns [Either.inl].
  static Either<L, R> iter<L, R extends Object>(L l, R? r) => r != null ? Either.inr(r) : Either.inl(l);
}

@immutable
class _Inl<L, R> extends Either<L, R> {
  final L _l;

  const _Inl._(this._l) : super._();

  @override
  T cases<T>(T Function(L l) f, T Function(R r) g) => f(_l);

  @override
  bool get isLeft => true;
  @override
  bool get isRight => false;

  @override
  L? get left => _l;
  @override
  R? get right => null;

  @override
  bool operator ==(Object other) => other is _Inl<L, R> && other._l == _l;
  @override
  int get hashCode => Object.hash(runtimeType, _l);
}

@immutable
class _Inr<L, R> extends Either<L, R> {
  final R _r;

  const _Inr._(this._r) : super._();

  @override
  T cases<T>(T Function(L l) f, T Function(R r) g) => g(_r);

  @override
  bool get isLeft => false;
  @override
  bool get isRight => true;

  @override
  L? get left => null;
  @override
  R? get right => _r;

  @override
  bool operator ==(Object other) => other is _Inr<L, R> && other._r == _r;
  @override
  int get hashCode => Object.hash(runtimeType, _r);
}
