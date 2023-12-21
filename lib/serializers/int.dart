import 'dart:typed_data';

import '../serializers.dart';

class Int8Serializer implements Serializer<int> {
  const Int8Serializer();

  @override
  void serialize(int object, BytesBuilder builder) => builder.writeInt8(object);

  @override
  int deserialize(BytesReader reader) => reader.readInt8();
}

class Int16Serializer implements Serializer<int> {
  const Int16Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeInt16(object);

  @override
  int deserialize(BytesReader reader) => reader.readInt16();
}

class Int32Serializer implements Serializer<int> {
  const Int32Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeInt32(object);

  @override
  int deserialize(BytesReader reader) => reader.readInt32();
}

class Int64Serializer implements Serializer<int> {
  const Int64Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeInt64(object);

  @override
  int deserialize(BytesReader reader) => reader.readInt64();
}

typedef IntSerializer = Int64Serializer;
