part of 'store.dart';

abstract interface class Model<T extends Object> {
  CId id();
}

abstract interface class Repository<T extends Model> {
  T? get(CId? id);
}
