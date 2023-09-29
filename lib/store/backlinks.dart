import '../reactive.dart';
import '../store.dart';

class Backlinks<T> with ObservableMixin<List<T>> implements ObservableSet<T> {
  final Id dst;
  final int label;
  final Repository<T> _repository;
  final Map<Id, Id> _srcs = {};

  Backlinks(this.dst, this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByDstLabel(
        dst, label, (id, src) => weak.target?._insert(id, src), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get(Observer? o) {
    if (o != null) connect(o);
    final res = <T>[];
    for (final src in _srcs.values) {
      final item = _repository.get(src).get(o);
      if (item != null) res.add(item);
    }
    return res;
  }

  void _insert(Id id, Id src) {
    _srcs[id] = src;
    notifyAll();
  }

  void _remove(Id id) {
    _srcs.remove(id);
    notifyAll();
  }
}
