import 'dart:typed_data';

import '../serializer.dart';

class Uint8Serializer implements Serializer<int> {
  const Uint8Serializer();

  @override
  void serialize(int object, BytesBuilder builder) {
    assert(object >= 0 && object <= 255);
    final binary = ByteData(1);
    binary.setUint8(0, object);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  int deserialize(BytesReader reader) {
    final res = reader.buffer.getUint8(reader.offset);
    reader.offset += 1;
    return res;
  }
}

class Uint16Serializer implements Serializer<int> {
  const Uint16Serializer();

  @override
  void serialize(int object, BytesBuilder builder) {
    assert(object >= 0 && object <= 65535);
    final binary = ByteData(2);
    binary.setUint16(0, object, Endian.big);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  int deserialize(BytesReader reader) {
    final res = reader.buffer.getUint16(reader.offset, Endian.big);
    reader.offset += 2;
    return res;
  }
}

class Uint32Serializer implements Serializer<int> {
  const Uint32Serializer();

  @override
  void serialize(int object, BytesBuilder builder) {
    assert(object >= 0 && object <= 4294967295);
    final binary = ByteData(4);
    binary.setUint32(0, object, Endian.big);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  int deserialize(BytesReader reader) {
    final res = reader.buffer.getUint32(reader.offset, Endian.big);
    reader.offset += 4;
    return res;
  }
}

class Uint64Serializer implements Serializer<int> {
  const Uint64Serializer();

  @override
  void serialize(int object, BytesBuilder builder) {
    final binary = ByteData(8);
    binary.setUint64(0, object, Endian.big);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  int deserialize(BytesReader reader) {
    final res = reader.buffer.getUint64(reader.offset, Endian.big);
    reader.offset += 8;
    return res;
  }
}
