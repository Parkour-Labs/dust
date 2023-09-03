import '../reactive.dart';
import '../store.dart';

// TODO: add information?
class AlreadyDeletedException<T> implements Exception {}

class RepositoryEntry<T> extends Node implements Observable<T?> {
  final Repository<T> parent;
  final T model;

  RepositoryEntry(this.parent, this.model);

  @override
  T? get(Node? o) {
    register(o);
    return parent.exists(model) ? model : null;
  }
}

abstract interface class Repository<T> {
  bool exists(T model);
  Id id(T model);
  RepositoryEntry<T> get(Id id);
  void delete(T model);
}
