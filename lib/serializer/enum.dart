import 'dart:typed_data';

import '../serializer.dart';

class EnumSerializer<T extends Enum> implements Serializer<T> {
  final List<T> values;
  const EnumSerializer(this.values) : assert(values.length <= 256);

  @override
  void serialize(T object, BytesBuilder builder) => const Uint8Serializer().serialize(object.index, builder);

  @override
  T deserialize(BytesReader reader) => values[const Uint8Serializer().deserialize(reader)];
}
