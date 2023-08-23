import 'dart:typed_data';

import '../serializer.dart';

class BoolSerializer implements Serializer<bool> {
  const BoolSerializer();

  @override
  void serialize(bool object, BytesBuilder builder) {
    builder.addByte(object ? 1 : 0);
  }

  @override
  bool deserialize(BytesReader reader) {
    final res = reader.buffer.getUint8(reader.offset);
    reader.offset += 1;
    return res != 0;
  }
}
