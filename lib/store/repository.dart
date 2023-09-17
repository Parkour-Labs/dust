import '../reactive.dart';
import '../store.dart';

class AlreadyDeletedException<T> implements Exception {}

class RepositoryEntry<T> extends ObservableMixin<T?> implements Observable<T?> {
  final Repository<T> _parent;
  final T model;

  RepositoryEntry(this._parent, this.model);

  @override
  T? get(Observer? o) {
    if (o != null) connect(o);
    return _parent.exists(model) ? model : null;
  }
}

abstract interface class Repository<T> {
  bool exists(T model);
  Id id(T model);
  RepositoryEntry<T> get(Id id);
  void delete(T model);
}
