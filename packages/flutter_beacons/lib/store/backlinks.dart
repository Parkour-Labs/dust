import '../store.dart';
import '../reactive.dart';

class Backlinks<T> extends Node implements Observable<Iterable<Ref<T>>> {
  final Id dst;
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> edges = {};

  Backlinks(this.dst, this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByLabelDst(
        label, dst, (id, src) => weak.target?._insert(id, src), (id) => weak.target?._remove(id), this);
  }

  @override
  Iterable<Ref<T>> get(Node? ref) {
    register(ref);
    return edges.values.map(repository.get);
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

  void _insert(Id id, Id src) {
    edges[id] = src;
    notify();
  }

  void _remove(Id id) {
    edges.remove(id);
    notify();
  }
}
