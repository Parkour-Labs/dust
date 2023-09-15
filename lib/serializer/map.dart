import 'dart:typed_data';

import '../serializer.dart';

class MapSerializer<T, U> implements Serializer<Map<T, U>> {
  final Serializer<T> t;
  final Serializer<U> u;
  const MapSerializer(this.t, this.u);

  @override
  void serialize(Map<T, U> object, BytesBuilder builder) {
    const Uint64Serializer().serialize(object.length, builder);
    for (final elem in object.entries) {
      t.serialize(elem.key, builder);
      u.serialize(elem.value, builder);
    }
  }

  @override
  Map<T, U> deserialize(BytesReader reader) {
    final length = const Uint64Serializer().deserialize(reader);
    final res = <T, U>{};
    for (var i = 0; i < length; i++) {
      final key = t.deserialize(reader);
      final value = u.deserialize(reader);
      res[key] = value;
    }
    return res;
  }
}
