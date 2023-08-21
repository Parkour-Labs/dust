part of 'store.dart';

abstract interface class Model<T extends Object> {
  Id get id;
}

abstract interface class Repository<T extends Model> {
  T? get(Id? id);
}
