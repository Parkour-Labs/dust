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

class LinkOption<T> with ObservableMixin<T?> implements ObservableMut<T?> {
  final Id id;
  final Id src;
  final int label;
  final Repository<T> _repository;
  Id? _dst;

  LinkOption(this.id, this.src, this.label, this._repository) {
    final weak = WeakReference(this);
    Dust.instance
        .subscribeEdgeById(id, (sld) => weak.target?._update(sld), this);
  }

  @override
  T? get(Observer? o) {
    if (o != null) connect(o);
    final dst = this._dst;
    return (dst == null) ? null : _repository.get(dst).get(o);
  }

  void _update((Id, int, Id)? sld) {
    _dst = (sld == null) ? null : sld.$3;
    notifyAll();
  }

  @override
  void set(T? value) {
    Dust.instance.setEdge(
        id, (value == null) ? null : (src, label, _repository.id(value)));
    Dust.instance.barrier();
  }
}

class Link<T> with ObservableMixin<T> implements ObservableMut<T> {
  final Id id;
  final Id src;
  final int label;
  final Repository<T> _repository;
  Id? _dst;

  Link(this.id, this.src, this.label, this._repository) {
    final weak = WeakReference(this);
    Dust.instance
        .subscribeEdgeById(id, (sld) => weak.target?._update(sld), this);
  }

  @override
  T get(Observer? o) {
    if (o != null) connect(o);
    final dst = this._dst;
    if (dst == null) throw AlreadyDeletedException();
    return _repository.get(dst).get(o)!;
    // This should never be `null`, and is guaranteed by stickiness constraints.
  }

  void _update((Id, int, Id)? sld) {
    _dst = (sld == null) ? null : sld.$3;
    notifyAll();
  }

  @override
  void set(T value) {
    Dust.instance.setEdge(id, (src, label, _repository.id(value)));
    Dust.instance.barrier();
  }
}
