import '../reactive.dart';
import '../store.dart';

class LinkOption<T> with ObservableMixin<T?> implements ObservableMut<T?> {
  final Id id;
  final Id src;
  final int label;
  final Repository<T> _repository;
  Id? _dst;

  LinkOption(this.id, this.src, this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeById(id, (sld) => weak.target?._update(sld), this);
  }

  @override
  T? get([Observer? o]) {
    if (o != null) connect(o);
    final dst = this._dst;
    return (dst == null) ? null : _repository.get(dst).get(o);
  }

  void _update((Id, int, Id)? sld) {
    _dst = (sld == null) ? null : sld.$3;
    notifyAll();
  }

  @override
  void set(T? value) {
    Store.instance.setEdge(id, (value == null) ? null : (src, label, _repository.id(value)));
  }
}

class Link<T> with ObservableMixin<T> implements ObservableMut<T> {
  RepositoryEntry<Object?>? parent;
  final Id id;
  final Id src;
  final int label;
  final Repository<T> _repository;
  Id? _dst;

  Link(this.id, this.src, this.label, this._repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeById(id, (sld) => weak.target?._update(sld), this);
  }

  bool get exists => _dst != null;

  @override
  T get([Observer? o]) {
    if (o != null) connect(o);
    final dst = this._dst;
    if (dst == null) throw AlreadyDeletedException();
    final res = _repository.get(dst).get(o);
    if (res == null) throw AlreadyDeletedException();
    return res;
  }

  void _update((Id, int, Id)? sld) {
    final existenceChanged = (_dst == null) != (sld == null);
    _dst = (sld == null) ? null : sld.$3;
    if (existenceChanged) parent?.notifyAll();
    notifyAll();
  }

  @override
  void set(T value) {
    Store.instance.setEdge(id, (src, label, _repository.id(value)));
  }
}
