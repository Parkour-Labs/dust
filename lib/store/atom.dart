import 'dart:typed_data';

import '../store.dart';
import '../reactive.dart';
import '../serializer.dart';

class AtomOption<T> with ObservableMixin<T?> implements ObservableMut<T?> {
  final Id id;
  final Id src;
  final int label;
  final Serializer<T> _serializer;
  T? _value;

  AtomOption(this.id, this.src, this.label, this._serializer) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomById(id, (slv) => weak.target?._update(slv), this);
  }

  @override
  T? get(Observer? o) {
    if (o != null) connect(o);
    return _value;
  }

  void _update((Id, int, ByteData)? slv) {
    _value = (slv == null) ? null : _serializer.deserialize(BytesReader(slv.$3));
    notifyAll();
  }

  @override
  void set(T? value) {
    Store.instance.setAtom<T>(id, (value == null) ? null : (src, label, value, _serializer));
  }
}

class Atom<T> with ObservableMixin<T> implements ObservableMut<T> {
  RepositoryEntry<Object?>? parent;
  final Id id;
  final Id src;
  final int label;
  final Serializer<T> _serializer;
  T? _value;

  Atom(this.id, this.src, this.label, this._serializer) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomById(id, (slv) => weak.target?._update(slv), this);
  }

  bool get exists => _value != null;

  @override
  T get(Observer? o) {
    if (o != null) connect(o);
    final value = this._value;
    if (value == null) throw AlreadyDeletedException();
    return value;
  }

  void _update((Id, int, ByteData)? slv) {
    final existenceChanged = (_value == null) != (slv == null);
    _value = (slv == null) ? null : _serializer.deserialize(BytesReader(slv.$3));
    if (existenceChanged) parent?.notifyAll();
    notifyAll();
  }

  @override
  void set(T value) {
    Store.instance.setAtom<T>(id, (src, label, value, _serializer));
  }
}

/// Just a simple wrapper around [AtomOption], using a default value when there
/// is no value.
class AtomDefault<T> with ObservableMixin<T> implements ObservableMut<T> {
  final AtomOption<T> _inner;
  final T _defaultValue;

  AtomDefault(Id id, Id src, int label, Serializer<T> serializer, this._defaultValue)
      : _inner = AtomOption(id, src, label, serializer);

  Id get id => _inner.id;
  Id get src => _inner.src;
  int get label => _inner.label;

  @override
  T get(Observer? o) => _inner.get(o) ?? _defaultValue;

  @override
  void set(T? value) => _inner.set(value);
}
