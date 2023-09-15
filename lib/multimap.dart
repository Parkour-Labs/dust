/// A [MultiMap] maps each key to a [Set] of values.
class MultiMap<K, V> {
  final Map<K, Set<V>> _map = {};

  bool add(K key, V value) => _map.putIfAbsent(key, () => {}).add(value);

  bool remove(K key, V value) {
    final values = _map[key];
    if (values == null) return false;
    final res = values.remove(value);
    if (values.isEmpty) _map.remove(key);
    return res;
  }

  Set<V> operator [](K key) => _map[key] ?? Set.unmodifiable({});
  operator []=(K key, Set<V> values) => _map[key] = values;

  int get length {
    var res = 0;
    for (final values in _map.values) {
      res += values.length;
    }
    return res;
  }
}
