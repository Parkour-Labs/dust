import 'dart:typed_data';

import 'serializer.dart';

class OptionSerializer<T extends Object> implements Serializer<T?> {
  final Serializer<T> t;
  const OptionSerializer(this.t);

  @override
  void serialize(T? object, BytesBuilder builder) {
    const BoolSerializer().serialize(object != null, builder);
    if (object != null) t.serialize(object, builder);
  }

  @override
  T? deserialize(BytesReader reader) {
    final some = const BoolSerializer().deserialize(reader);
    return some ? t.deserialize(reader) : null;
  }
}
