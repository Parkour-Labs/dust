import '../store.dart';

abstract interface class Repository<T extends Object> {
  Id id(T object);
  T? get(Id? id);
}
