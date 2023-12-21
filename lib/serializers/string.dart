import 'dart:typed_data';

import '../serializers.dart';

class StringSerializer implements Serializer<String> {
  const StringSerializer();

  @override
  void serialize(String object, BytesBuilder builder) =>
      builder.writeString(object);

  @override
  String deserialize(BytesReader reader) => reader.readString();
}
