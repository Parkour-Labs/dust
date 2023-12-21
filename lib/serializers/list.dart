import 'dart:typed_data';

import '../serializers.dart';

class ListSerializer<T> implements Serializer<List<T>> {
  final Serializer<T> t;
  const ListSerializer(this.t);

  @override
  void serialize(List<T> object, BytesBuilder builder) {
    builder.writeUint64(object.length);
    for (final elem in object) {
      t.serialize(elem, builder);
    }
  }

  @override
  List<T> deserialize(BytesReader reader) {
    final length = reader.readUint64();
    final res = <T>[];
    for (var i = 0; i < length; i++) {
      res.add(t.deserialize(reader));
    }
    return res;
  }
}
