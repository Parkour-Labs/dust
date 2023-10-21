import 'dart:typed_data';

import '../serializer.dart';

class BoolSerializer implements Serializer<bool> {
  const BoolSerializer();

  @override
  void serialize(bool object, BytesBuilder builder) {
    builder.writeBool(object);
  }

  @override
  bool deserialize(BytesReader reader) {
    return reader.readBool();
  }
}
