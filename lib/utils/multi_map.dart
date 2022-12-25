import 'package:meta/meta.dart';

/// A [MultiMap] maps each key to a [Set] of values.
@immutable
class MultiMap<K, V> {
  final Map<K, Set<V>> _m = {};

  void add(K key, V value) {
    _m.putIfAbsent(key, () => {}).add(value);
  }

  Iterable<V> findAll(K key) => _m[key] ?? [];

  void remove(K key, V value) {
    final values = _m[key];
    if (values == null) {
      assert(false);
      return;
    }
    final res = values.remove(value);
    if (values.isEmpty) _m.remove(key);
    assert(res);
  }

  Iterable<V> removeAll(K key) => _m.remove(key) ?? [];

  int get length {
    var res = 0;
    for (final values in _m.values) {
      res += values.length;
    }
    return res;
  }
}
