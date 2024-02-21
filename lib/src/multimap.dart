// Copyright 2024 ParkourLabs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
