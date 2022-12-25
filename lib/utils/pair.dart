import 'package:meta/meta.dart';

/// Immutable product type.
@immutable
class Pair<S, T> {
  final S first;
  final T second;

  const Pair(this.first, this.second);

  @override
  bool operator ==(Object other) => other is Pair<S, T> && first == other.first && second == other.second;

  @override
  int get hashCode => Object.hash(first, second);
}
