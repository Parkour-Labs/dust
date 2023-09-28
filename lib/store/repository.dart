import '../store.dart';

abstract interface class Repository<T> {
  Schema init();
  Id id(T model);
  NodeOption<T> get(Id id);
  void delete(T model);
}
