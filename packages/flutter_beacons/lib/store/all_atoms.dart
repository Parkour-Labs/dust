import 'dart:typed_data';

import '../serializer.dart';
import '../store.dart';
import '../reactive.dart';

class AllAtomValues<T> extends Node implements Observable<List<T>> {
  final int label;
  final Serializer<T> serializer;
  final Map<Id, T> values = {};

  AllAtomValues(this.label, this.serializer) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomByLabel(
        label, (id, src, value) => weak.target?._insert(id, src, value), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get(Node? o) {
    register(o);
    return values.values.toList();
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

class AllAtomOwners<T> extends Node implements Observable<List<T>> {
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> srcs = {};

  AllAtomOwners(this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomByLabel(
        label, (id, src, value) => weak.target?._insert(id, src, value), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get(Node? o) {
    register(o);
    final res = <T>[];
    for (final src in srcs.values) {
      final item = repository.get(src).get(o);
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
