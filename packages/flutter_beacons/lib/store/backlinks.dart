part of 'store.dart';

class Backlinks<T extends Model> extends Node implements Observable<Set<T>> {
  final Repository<T> repository;
  final CId dst;
  final int label;
  final Set<CId> edges = {};

  Backlinks.fromRaw(this.repository, this.dst, this.label);

  @override
  Set<T> get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  Set<T> peek() {
    return edges.map<T>((elem) => repository.get(elem)!).toSet();
  }

  void _insert(CId id, CId src) {
    edges.add(src);
    notify();
  }

  void _remove(CId id, CId src) {
    edges.remove(src);
    notify();
  }
}
