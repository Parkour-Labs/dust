import 'dart:typed_data';

import '../serializer.dart';
import '../store.dart';
import '../reactive.dart';

class AllAtomValues<T> extends Node implements Observable<Iterable<T>> {
  final int label;
  final Serializer<T> serializer;
  final Map<Id, T> values = {};

  AllAtomValues(this.label, this.serializer) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomByLabel(
        label, (id, src, value) => weak.target?._insert(id, src, value), (id) => weak.target?._remove(id), this);
  }

  @override
  Iterable<T> get(Node? ref) {
    register(ref);
    return values.values;
  }

  void _insert(Id id, Id src, ByteData value) {
    values[id] = serializer.deserialize(BytesReader(value));
    notify();
  }

  void _remove(Id id) {
    values.remove(id);
    notify();
  }
}

class AllAtomOwners<T> extends Node implements Observable<Iterable<Ref<T>>> {
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> srcs = {};

  AllAtomOwners(this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomByLabel(
        label, (id, src, value) => weak.target?._insert(id, src, value), (id) => weak.target?._remove(id), this);
  }

  @override
  Iterable<Ref<T>> get(Node? ref) {
    register(ref);
    return srcs.keys.map(repository.get);
  }

  /// A more convenient variant for [get].
  List<T> filter(Node? ref) {
    final res = <T>[];
    for (final e in get(ref)) {
      final item = e.get(ref);
      if (item != null) res.add(item);
    }
    return res;
  }

  void _insert(Id id, Id src, ByteData value) {
    srcs[id] = src;
    notify();
  }

  void _remove(Id id) {
    srcs.remove(id);
    notify();
  }
}
