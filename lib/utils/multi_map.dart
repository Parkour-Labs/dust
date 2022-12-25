import 'package:meta/meta.dart';

/// A [MultiMap] maps each key to a [Set] of values.
@immutable
class MultiMap<K, V> {
  final Map<K, Set<V>> map = {};

  void add(K key, V value) {
    map.putIfAbsent(key, () => {}).add(value);
  }

  Iterable<V> findAll(K key) => map[key] ?? [];

  void remove(K key, V value) {
    final values = map[key];
    if (values == null) {
      assert(false);
      return;
    }
    final res = values.remove(value);
    if (values.isEmpty) map.remove(key);
    assert(res);
  }

  Iterable<V> removeAll(K key) => map.remove(key) ?? [];

  int get length {
    var res = 0;
    for (final values in map.values) {
      res += values.length;
    }
    return res;
  }
}
