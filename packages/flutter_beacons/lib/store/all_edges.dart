import '../store.dart';
import '../reactive.dart';

class AllEdgeDestinations<T> extends Node implements Observable<Iterable<Ref<T>>> {
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> dsts = {};

  AllEdgeDestinations(this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByLabel(
        label, (id, src, dst) => weak.target?._insert(id, src, dst), (id) => weak.target?._remove(id), this);
  }

  @override
  Iterable<Ref<T>> get(Node? ref) {
    register(ref);
    return dsts.values.map(repository.get);
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

  void _insert(Id id, Id src, Id dst) {
    dsts[id] = dst;
    notify();
  }

  void _remove(Id id) {
    dsts.remove(id);
    notify();
  }
}

class AllEdgeSources<T> extends Node implements Observable<Iterable<Ref<T>>> {
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> srcs = {};

  AllEdgeSources(this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByLabel(
        label, (id, src, dst) => weak.target?._insert(id, src, dst), (id) => weak.target?._remove(id), this);
  }

  @override
  Iterable<Ref<T>> get(Node? ref) {
    register(ref);
    return srcs.values.map(repository.get);
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

  void _insert(Id id, Id src, Id dst) {
    srcs[id] = src;
    notify();
  }

  void _remove(Id id) {
    srcs.remove(id);
    notify();
  }
}
