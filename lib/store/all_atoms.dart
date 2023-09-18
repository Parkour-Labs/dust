import 'dart:typed_data';

import '../reactive.dart';
import '../serializer.dart';
import '../store.dart';

class AllAtomValues<T> with ObservableMixin<Iterable<T>> implements ObservableSet<T> {
  final int label;
  final Serializer<T> _serializer;
  final Map<Id, T> _values = {};

  AllAtomValues(this.label, this._serializer) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomByLabel(
        label, (id, src, value) => weak.target?._insert(id, src, value), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get([Observer? o]) {
    if (o != null) connect(o);
    return _values.values.toList();
  }

  void _insert(Id id, Id src, ByteData value) {
    _values[id] = _serializer.deserialize(BytesReader(value));
    notifyAll();
  }

  void _remove(Id id) {
    _values.remove(id);
    notifyAll();
  }
}

class AllAtomOwners<T> with ObservableMixin<Iterable<T>> implements ObservableSet<T> {
  final int label;
  final Repository<T> _repository;
  final Map<Id, Id> _srcs = {};

  AllAtomOwners(this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeAtomByLabel(
        label, (id, src, value) => weak.target?._insert(id, src, value), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get([Observer? o]) {
    if (o != null) connect(o);
    final res = <T>[];
    for (final src in _srcs.values) {
      final item = _repository.get(src).get(o);
      if (item != null) res.add(item);
    }
    return res;
  }

  void _insert(Id id, Id src, ByteData value) {
    _srcs[id] = src;
    notifyAll();
  }

  void _remove(Id id) {
    _srcs.remove(id);
    notifyAll();
  }
}
