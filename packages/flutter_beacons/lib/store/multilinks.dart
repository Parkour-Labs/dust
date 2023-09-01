import '../store.dart';
import '../reactive.dart';

class Multilinks<T> extends Node implements Observable<Iterable<Ref<T>>> {
  final Id src;
  final int label;
  final Repository<T> repository;
  final Map<Id, Id> edges = {};

  Multilinks(this.src, this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeBySrcLabel(
        src, label, (id, dst) => weak.target?._insert(id, dst), (id) => weak.target?._remove(id), this);
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

  void _insert(Id id, Id dst) {
    edges[id] = dst;
    notify();
  }

  void _remove(Id id) {
    edges.remove(id);
    notify();
  }

  void insert(Ref<T> value) {
    Store.instance.setEdge(Store.instance.randomId(), (src, label, value.id));
  }

  void remove(Ref<T> value) {
    for (final entry in edges.entries) {
      if (entry.value == value.id) {
        Store.instance.setEdge(entry.key, null);
        break;
      }
    }
  }
}
