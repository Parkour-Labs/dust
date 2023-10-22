import 'dart:typed_data';

import '../serializer.dart';

class Uint8ListSerializer implements Serializer<Uint8List> {
  const Uint8ListSerializer();

  @override
  void serialize(Uint8List object, BytesBuilder builder) =>
      builder.writeBytes(object);

  @override
  Uint8List deserialize(BytesReader reader) => reader.readBytes();
}
