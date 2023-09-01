import '../reactive.dart';
import '../store.dart';

class Ref<T> extends Node implements Observable<T?> {
  final Id id;
  final T model;
  final Repository<T> repository;

  Ref(this.id, this.model, this.repository);

  @override
  T? get(Node? ref) {
    register(ref);
    return repository.isComplete(model) ? model : null;
  }

  void delete() {
    repository.delete(id);
  }
}

abstract interface class Repository<T> {
  bool isComplete(T model);
  Ref<T> get(Id id);
  void delete(Id id);
}
