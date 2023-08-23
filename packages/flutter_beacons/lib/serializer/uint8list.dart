import 'dart:typed_data';

import '../serializer.dart';

class Uint8ListSerializer implements Serializer<Uint8List> {
  const Uint8ListSerializer();

  @override
  void serialize(Uint8List object, BytesBuilder builder) {
    const Uint64Serializer().serialize(object.length, builder);
    builder.add(object);
  }

  @override
  Uint8List deserialize(BytesReader reader) {
    final length = const Uint64Serializer().deserialize(reader);
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = reader.buffer.getUint8(reader.offset);
      reader.offset += 1;
    }
    return bytes;
  }
}
