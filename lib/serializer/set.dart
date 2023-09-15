import 'dart:typed_data';

import '../serializer.dart';

class SetSerializer<T> implements Serializer<Set<T>> {
  final Serializer<T> t;
  const SetSerializer(this.t);

  @override
  void serialize(Set<T> object, BytesBuilder builder) {
    const Uint64Serializer().serialize(object.length, builder);
    for (final elem in object) {
      t.serialize(elem, builder);
    }
  }

  @override
  Set<T> deserialize(BytesReader reader) {
    final length = const Uint64Serializer().deserialize(reader);
    final res = <T>{};
    for (var i = 0; i < length; i++) {
      res.add(t.deserialize(reader));
    }
    return res;
  }
}
