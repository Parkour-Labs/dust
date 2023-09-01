import '../store.dart';
import '../reactive.dart';

class Backlinks<T> extends Node implements Observable<List<T>> {
  final Id dst;
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> srcs = {};

  Backlinks(this.dst, this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByLabelDst(
        label, dst, (id, src) => weak.target?._insert(id, src), (id) => weak.target?._remove(id), this);
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

  void _insert(Id id, Id src) {
    srcs[id] = src;
    notify();
  }

  void _remove(Id id) {
    srcs.remove(id);
    notify();
  }
}
