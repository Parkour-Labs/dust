import 'dart:typed_data';

import '../store.dart';
import '../reactive.dart';
import '../serializer.dart';

class AtomOption<T> extends Node implements Observable<T?> {
  final Id id;
  final Id src;
  final int label;
  final Serializer<T> serializer;
  T? value;

  AtomOption(this.id, this.src, this.label, this.serializer) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomById(id, (slv) => weak.target?._update(slv), this);
  }

  @override
  T? get(Node? o) {
    register(o);
    return value;
  }

  void _update((Id, int, ByteData)? slv) {
    value = (slv == null) ? null : serializer.deserialize(BytesReader(slv.$3));
    notify();
  }

  void set(T? value) {
    Store.instance.setAtom<T>(id, (value == null) ? null : (src, label, value, serializer));
  }
}

class Atom<T> extends Node implements Observable<T> {
  RepositoryEntry<Object?>? parent;
  final Id id;
  final Id src;
  final int label;
  final Serializer<T> serializer;
  T? value;

  Atom(this.id, this.src, this.label, this.serializer) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomById(id, (slv) => weak.target?._update(slv), this);
  }

  bool get exists => value != null;

  @override
  T get(Node? o) {
    register(o);
    final value = this.value;
    if (value == null) throw AlreadyDeletedException();
    return value;
  }

  void _update((Id, int, ByteData)? slv) {
    final existenceChanged = (value == null) != (slv == null);
    value = (slv == null) ? null : serializer.deserialize(BytesReader(slv.$3));
    if (existenceChanged) parent?.notify();
    notify();
  }

  void set(T value) {
    Store.instance.setAtom<T>(id, (src, label, value, serializer));
  }
}

/// Just a simple wrapper around [AtomOption], using a default value when there
/// is no value.
class AtomDefault<T> implements Observable<T> {
  AtomOption<T> inner;
  T defaultValue;

  AtomDefault(Id id, Id src, int label, Serializer<T> serializer, this.defaultValue)
      : inner = AtomOption(id, src, label, serializer);

  @override
  void register(Node? o) => inner.register(o);

  @override
  void notify() => inner.notify();

  @override
  T get(Node? o) => inner.get(o) ?? defaultValue;

  void set(T? value) => inner.set(value);
}
