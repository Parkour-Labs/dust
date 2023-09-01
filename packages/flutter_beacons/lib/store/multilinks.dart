import '../store.dart';
import '../reactive.dart';

class Multilinks<T> extends Node implements Observable<List<T>> {
  final Id src;
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> dsts = {};

  Multilinks(this.src, this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeBySrcLabel(
        src, label, (id, dst) => weak.target?._insert(id, dst), (id) => weak.target?._remove(id), this);
  }

  /// A more convenient variant of [get].
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

  void _insert(Id id, Id dst) {
    dsts[id] = dst;
    notify();
  }

  void _remove(Id id) {
    dsts.remove(id);
    notify();
  }

  void insert(T value) {
    Store.instance.setEdge(Store.instance.randomId(), (src, label, repository.id(value)));
  }

  void remove(T value) {
    for (final entry in dsts.entries) {
      if (entry.value == repository.id(value)) {
        Store.instance.setEdge(entry.key, null);
        break;
      }
    }
  }
}
