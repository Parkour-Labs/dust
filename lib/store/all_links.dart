import '../reactive.dart';
import '../store.dart';

class AllLinkDestinations<T>
    with ObservableMixin<Iterable<T>>
    implements ObservableSet<T> {
  final int label;
  final Repository<T> _repository;
  final Map<Id, Id> _dsts = {};

  AllLinkDestinations(this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByLabel(
        label,
        (id, src, dst) => weak.target?._insert(id, src, dst),
        (id) => weak.target?._remove(id),
        this);
  }

  @override
  List<T> get([Observer? o]) {
    if (o != null) connect(o);
    final res = <T>[];
    for (final dst in _dsts.values) {
      final item = _repository.get(dst).get(o);
      if (item != null) res.add(item);
    }
    return res;
  }

  void _insert(Id id, Id src, Id dst) {
    _dsts[id] = dst;
    notifyAll();
  }

  void _remove(Id id) {
    _dsts.remove(id);
    notifyAll();
  }
}

class AllLinkSources<T>
    with ObservableMixin<Iterable<T>>
    implements ObservableSet<T> {
  final int label;
  final Repository<T> _repository;
  final Map<Id, Id> _srcs = {};

  AllLinkSources(this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeByLabel(
        label,
        (id, src, dst) => weak.target?._insert(id, src, dst),
        (id) => weak.target?._remove(id),
        this);
  }

  @override
  List<T> get([Observer? o]) {
    if (o != null) connect(o);
    final res = <T>[];
    for (final src in _srcs.values) {
      final item = _repository.get(src).get(o);
      if (item != null) res.add(item);
    }
    return res;
  }

  void _insert(Id id, Id src, Id dst) {
    _srcs[id] = src;
    notifyAll();
  }

  void _remove(Id id) {
    _srcs.remove(id);
    notifyAll();
  }
}
