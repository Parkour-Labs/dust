import 'dart:typed_data';

import '../serializers.dart';

class EnumSerializer<T extends Enum> implements Serializer<T> {
  final List<T> values;
  const EnumSerializer(this.values);

  @override
  void serialize(T object, BytesBuilder builder) =>
      builder.writeUint32(object.index);

  @override
  T deserialize(BytesReader reader) => values[reader.readUint32()];
}
