import 'dart:typed_data';

import '../serializer.dart';

class DateTimeSerializer implements Serializer<DateTime> {
  const DateTimeSerializer();

  @override
  DateTime deserialize(BytesReader reader) =>
      DateTime.fromMicrosecondsSinceEpoch(const IntSerializer().deserialize(reader));

  @override
  void serialize(DateTime object, BytesBuilder builder) =>
      const IntSerializer().serialize(object.microsecondsSinceEpoch, builder);
}
