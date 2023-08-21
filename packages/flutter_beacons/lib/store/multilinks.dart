part of 'store.dart';

class Multilinks<T extends Model> extends Node implements Observable<Set<T>> {
  final Repository<T> repository;
  final CId src;
  final int label;
  final Set<(CId, CId)> edges = {};

  Multilinks.fromRaw(this.repository, this.src, this.label);

  @override
  Set<T> get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  Set<T> peek() {
    return edges.map<T>((elem) => repository.get(elem.$2)!).toSet();
  }

  void _insert(CId id, CId dst) {
    edges.add((id, dst));
    notify();
  }

  void _remove(CId id, CId dst) {
    edges.remove((id, dst));
    notify();
  }

  void insert(T value) {
    Store.instance.setEdge(Store.instance.bindings.random_id(), (src, label, value.id()));
  }

  void remove(T value) {
    for (final (id, dst) in edges) {
      if (dst == value.id()) {
        Store.instance.setEdge(id, null);
        break;
      }
    }
  }
}
