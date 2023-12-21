import 'dart:typed_data';

import '../serializers.dart';

class OptionSerializer<T extends Object> implements Serializer<T?> {
  final Serializer<T> t;
  const OptionSerializer(this.t);

  @override
  void serialize(T? object, BytesBuilder builder) {
    builder.writeBool(object != null);
    if (object != null) t.serialize(object, builder);
  }

  @override
  T? deserialize(BytesReader reader) {
    final some = reader.readBool();
    return some ? t.deserialize(reader) : null;
  }
}
