import '../reactive.dart';
import '../store.dart';

class NodeOption<T> extends ObservableMixin<T?> implements Observable<T?> {
  final Id id;
  final int label;
  final T _model;
  int? _value;

  NodeOption(this.id, this.label, this._model) {
    final weak = WeakReference(this);
    Store.instance.subscribeNodeById(id, (l) => weak.target?._update(l), this);
  }

  @override
  T? get(Observer? o) {
    if (o != null) connect(o);
    return _value == label ? _model : null;
  }

  void _update(int? label) {
    _value = label;
    notifyAll();
  }
}

/// Just a simple wrapper around [NodeOption], calling an initialiser function
/// when there is no node present.
class NodeAuto<T> implements Observable<T> {
  final NodeOption _inner;
  final void Function() _callback;

  NodeAuto(this._inner, this._callback);

  @override
  void connect(Observer o) => _inner.connect(o);

  @override
  T get(Observer? o) {
    final res = _inner.get(o);
    if (res != null) return res;
    _callback();
    return _inner.get(o)!;
  }
}

class NodesByLabel<T> with ObservableMixin<Iterable<T>> implements ObservableSet<T> {
  final int label;
  final Repository<T> _repository;
  final Set<Id> _ids = {};

  NodesByLabel(this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance
        .subscribeNodeByLabel(label, (id) => weak.target?._insert(id), (id) => weak.target?._remove(id), this);
  }

  @override
  List<T> get(Observer? o) {
    if (o != null) connect(o);
    final res = <T>[];
    for (final id in _ids) {
      final item = _repository.get(id).get(o);
      if (item != null) res.add(item);
    }
    return res;
  }

  void _insert(Id id) {
    _ids.add(id);
    notifyAll();
  }

  void _remove(Id id) {
    _ids.remove(id);
    notifyAll();
  }
}