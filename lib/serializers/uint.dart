import 'dart:typed_data';

import '../serializer.dart';

class Uint8Serializer implements Serializer<int> {
  const Uint8Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeUint8(object);

  @override
  int deserialize(BytesReader reader) => reader.readUint8();
}

typedef BoolPackSerializer = Uint8Serializer;

class Uint16Serializer implements Serializer<int> {
  const Uint16Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeUint16(object);

  @override
  int deserialize(BytesReader reader) => reader.readUint16();
}

class Uint32Serializer implements Serializer<int> {
  const Uint32Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeUint32(object);

  @override
  int deserialize(BytesReader reader) => reader.readUint32();
}

class Uint64Serializer implements Serializer<int> {
  const Uint64Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeUint64(object);

  @override
  int deserialize(BytesReader reader) => reader.readUint64();
}
