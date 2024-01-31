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

import '../reactive.dart';
import '../store.dart';

class Multilinks<T>
    with ObservableMixin<List<T>>
    implements ObservableMutSet<T> {
  final Id src;
  final int label;
  final Repository<T> _repository;
  final Map<Id, Id> _dsts = {};

  Multilinks(this.src, this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeBySrcLabel(
        src,
        label,
        (id, dst) => weak.target?._insert(id, dst),
        (id) => weak.target?._remove(id),
        this);
  }

  @override
  List<T> get(Observer? o) {
    if (o != null) connect(o);
    final res = <T>[];
    for (final dst in _dsts.values) {
      final item = _repository.get(dst).get(o);
      if (item != null) res.add(item);
    }
    return res;
  }

  void _insert(Id id, Id dst) {
    _dsts[id] = dst;
    notifyAll();
  }

  void _remove(Id id) {
    _dsts.remove(id);
    notifyAll();
  }

  @override
  void insert(T value) {
    Store.instance.setEdge(
        Store.instance.randomId(), (src, label, _repository.id(value)));
    Store.instance.barrier();
  }

  @override
  void remove(T value) {
    for (final entry in _dsts.entries) {
      if (entry.value == _repository.id(value)) {
        Store.instance.setEdge(entry.key, null);
        Store.instance.barrier();
        break;
      }
    }
  }
}
