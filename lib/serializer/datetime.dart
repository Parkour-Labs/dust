import 'dart:typed_data';

import '../serializer.dart';

class DateTimeSerializer implements Serializer<DateTime> {
  const DateTimeSerializer();

  @override
  DateTime deserialize(BytesReader reader) =>
      DateTime.fromMicrosecondsSinceEpoch(reader.readInt64());

  @override
  void serialize(DateTime object, BytesBuilder builder) =>
      builder.writeInt64(object.microsecondsSinceEpoch);
}
