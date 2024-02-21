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

import 'dart:typed_data';

import '../reactive.dart';
import '../serializers.dart';
import '../store.dart';

class AtomOption<T> with ObservableMixin<T?> implements ObservableMut<T?> {
  final Id id;
  final Id src;
  final int label;
  final Serializer<T> _serializer;
  T? _value;

  AtomOption(this.id, this.src, this.label, this._serializer) {
    final weak = WeakReference(this);
    Dust.instance
        .subscribeAtomById(id, (slv) => weak.target?._update(slv), this);
  }

  @override
  T? get(Observer? o) {
    if (o != null) connect(o);
    return _value;
  }

  void _update((Id, int, ByteData)? slv) {
    _value =
        (slv == null) ? null : _serializer.deserialize(BytesReader(slv.$3));
    notifyAll();
  }

  @override
  void set(T? value) {
    Dust.instance.setAtom<T>(
        id, (value == null) ? null : (src, label, value, _serializer));
    Dust.instance.barrier();
  }
}

class Atom<T> with ObservableMixin<T> implements ObservableMut<T> {
  final Id id;
  final Id src;
  final int label;
  final Serializer<T> _serializer;
  T? _value;

  Atom(this.id, this.src, this.label, this._serializer) {
    final weak = WeakReference(this);
    Dust.instance
        .subscribeAtomById(id, (slv) => weak.target?._update(slv), this);
  }

  @override
  T get(Observer? o) {
    if (o != null) connect(o);
    final value = this._value;
    if (value == null) throw AlreadyDeletedException();
    return value;
  }

  void _update((Id, int, ByteData)? slv) {
    _value =
        (slv == null) ? null : _serializer.deserialize(BytesReader(slv.$3));
    notifyAll();
  }

  @override
  void set(T value) {
    Dust.instance.setAtom<T>(id, (src, label, value, _serializer));
    Dust.instance.barrier();
  }
}

/// Just a simple wrapper around [AtomOption], using a default value when there
/// is no value.
class AtomDefault<T> implements ObservableMut<T> {
  final AtomOption<T> _inner;
  final T _defaultValue;

  AtomDefault(
      Id id, Id src, int label, Serializer<T> serializer, this._defaultValue)
      : _inner = AtomOption(id, src, label, serializer);

  Id get id => _inner.id;
  Id get src => _inner.src;
  int get label => _inner.label;

  @override
  void connect(Observer o) => _inner.connect(o);

  @override
  T get(Observer? o) => _inner.get(o) ?? _defaultValue;

  @override
  void set(T? value) => _inner.set(value);
}
