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
  T? get(Node? ref) {
    register(ref);
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
  Ref<Object?>? parent;
  final Id id;
  final Id src;
  final int label;
  final Serializer<T> serializer;
  T? value;

  Atom(this.id, this.src, this.label, this.serializer) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomById(id, (slv) => weak.target?._update(slv), this);
  }

  bool get isComplete => value != null;

  @override
  T get(Node? ref) {
    register(ref);
    return value!;
  }

  void _update((Id, int, ByteData)? slv) {
    final completenessChanged = (value == null) != (slv == null);
    value = (slv == null) ? null : serializer.deserialize(BytesReader(slv.$3));
    if (completenessChanged) parent?.notify();
    notify();
  }

  void set(T value) {
    Store.instance.setAtom<T>(id, (src, label, value, serializer));
  }
}
