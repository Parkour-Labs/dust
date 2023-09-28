import '../reactive.dart';
import '../store.dart';

class Multilinks<T> with ObservableMixin<Iterable<T>> implements ObservableMutSet<T> {
  final Id src;
  final int label;
  final Repository<T> _repository;
  final Map<Id, Id> _dsts = {};

  Multilinks(this.src, this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeBySrcLabel(
        src, label, (id, dst) => weak.target?._insert(id, dst), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get(Observer? o) {
    if (o != null) connect(o);
    final res = <T>[];
    for (final dst in _dsts.values) {
      final item = _repository.get(dst).get(o);
      if (item != null) res.add(item);
    }
    return res;
  }

  void _insert(Id id, Id dst) {
    _dsts[id] = dst;
    notifyAll();
  }

  void _remove(Id id) {
    _dsts.remove(id);
    notifyAll();
  }

  @override
  void insert(T value) {
    Store.instance.setEdge(Store.instance.randomId(), (src, label, _repository.id(value)));
    Store.instance.barrier();
  }

  @override
  void remove(T value) {
    for (final entry in _dsts.entries) {
      if (entry.value == _repository.id(value)) {
        Store.instance.setEdge(entry.key, null);
        Store.instance.barrier();
        break;
      }
    }
  }
}
