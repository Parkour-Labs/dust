import '../store.dart';
import '../reactive.dart';

class Backlinks<T extends Object> extends Node implements Observable<List<T>> {
  final Repository<T> repository;
  final Id dst;
  final int label;
  final Map<Id, Id> edges = {};

  Backlinks._(this.repository, this.dst, this.label);

  @override
  List<T> get(Node? ref) {
    register(ref);
    return edges.values.map<T>((elem) => repository.get(elem)!).toList();
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

extension GetBacklinksExtension on Store {
  Backlinks<T> getBacklinks<T extends Object>(Repository<T> repository, Id dst, int label) {
    final res = Backlinks<T>._(repository, dst, label);
    final weak = WeakReference(res);
    subscribeEdgeByLabelDst(
        label, dst, (id, src) => weak.target?._insert(id, src), (id) => weak.target?._remove(id), res);
    return res;
  }
}
