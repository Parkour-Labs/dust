import 'dart:typed_data';
import 'dart:convert' show utf8;

import 'serializer.dart';

class StringSerializer implements Serializer<String> {
  const StringSerializer();

  @override
  void serialize(String object, BytesBuilder builder) {
    final bytes = utf8.encode(object);
    const Uint64Serializer().serialize(bytes.length, builder);
    builder.add(bytes);
  }

  @override
  String deserialize(BytesReader reader) {
    final length = const Uint64Serializer().deserialize(reader);
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = reader.buffer.getUint8(reader.offset);
      reader.offset += 1;
    }
    return utf8.decode(bytes, allowMalformed: true);
  }
}
