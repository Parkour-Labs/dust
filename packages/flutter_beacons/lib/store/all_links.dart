import '../store.dart';
import '../reactive.dart';

class AllLinkDestinations<T> extends Node implements Observable<List<T>> {
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> dsts = {};

  AllLinkDestinations(this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByLabel(
        label, (id, src, dst) => weak.target?._insert(id, src, dst), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get(Node? ref) {
    register(ref);
    final res = <T>[];
    for (final dst in dsts.values) {
      final item = repository.get(dst).get(ref);
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

class AllLinkSources<T> extends Node implements Observable<List<T>> {
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> srcs = {};

  AllLinkSources(this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByLabel(
        label, (id, src, dst) => weak.target?._insert(id, src, dst), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get(Node? ref) {
    register(ref);
    final res = <T>[];
    for (final src in srcs.values) {
      final item = repository.get(src).get(ref);
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
