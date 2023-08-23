part of '../store.dart';

class Multilinks<T extends Object> extends Node implements Observable<List<T>> {
  final Repository<T> repository;
  final Id src;
  final int label;
  final Set<(Id, Id)> edges = {};

  Multilinks._(this.repository, this.src, this.label);

  @override
  List<T> get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  List<T> peek() {
    return edges.map<T>((elem) => repository.get(elem.$2)!).toList();
  }

  void _insert(Id id, Id dst) {
    edges.add((id, dst));
    notify();
  }

  void _remove(Id id, Id dst) {
    edges.remove((id, dst));
    notify();
  }

  void insert(T value) {
    Store.instance.setEdge(Store.instance.randomId(), (src, label, repository.id(value)));
  }

  void remove(T value) {
    for (final (id, dst) in edges) {
      if (dst == repository.id(value)) {
        Store.instance.setEdge(id, null);
        break;
      }
    }
  }
}
