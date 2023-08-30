import '../store.dart';
import '../reactive.dart';

class Multilinks<T extends Object> extends Node implements Observable<List<T>> {
  final Repository<T> repository;
  final Id src;
  final int label;
  final Map<Id, Id> edges = {};

  Multilinks._(this.repository, this.src, this.label);

  @override
  List<T> get(Node? ref) {
    register(ref);
    return edges.values.map<T>((elem) => repository.get(elem)!).toList();
  }

  void _insert(Id id, Id dst) {
    edges[id] = dst;
    notify();
  }

  void _remove(Id id) {
    edges.remove(id);
    notify();
  }

  void insert(T value) {
    Store.instance.setEdge(Store.instance.randomId(), (src, label, repository.id(value)));
  }

  void remove(T value) {
    for (final entry in edges.entries) {
      if (entry.value == repository.id(value)) {
        Store.instance.setEdge(entry.key, null);
        break;
      }
    }
  }
}

extension GetMultilinksExtension on Store {
  Multilinks<T> getMultilinks<T extends Object>(Repository<T> repository, Id src, int label) {
    final res = Multilinks<T>._(repository, src, label);
    final weak = WeakReference(res);
    subscribeEdgeBySrcLabel(
        src, label, (id, dst) => weak.target?._insert(id, dst), (id) => weak.target?._remove(id), res);
    return res;
  }
}
