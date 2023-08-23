import 'dart:typed_data';

import '../serializer.dart';

class Int8Serializer implements Serializer<int> {
  const Int8Serializer();

  @override
  void serialize(int object, BytesBuilder builder) {
    assert(object >= -128 && object <= 127);
    final binary = ByteData(1);
    binary.setInt8(0, object);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  int deserialize(BytesReader reader) {
    final res = reader.buffer.getInt8(reader.offset);
    reader.offset += 1;
    return res;
  }
}

class Int16Serializer implements Serializer<int> {
  const Int16Serializer();

  @override
  void serialize(int object, BytesBuilder builder) {
    assert(object >= -32768 && object <= 32767);
    final binary = ByteData(2);
    binary.setInt16(0, object, Endian.big);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  int deserialize(BytesReader reader) {
    final res = reader.buffer.getInt16(reader.offset, Endian.big);
    reader.offset += 2;
    return res;
  }
}

class Int32Serializer implements Serializer<int> {
  const Int32Serializer();

  @override
  void serialize(int object, BytesBuilder builder) {
    assert(object >= -2147483648 && object <= 2147483647);
    final binary = ByteData(4);
    binary.setInt32(0, object, Endian.big);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  int deserialize(BytesReader reader) {
    final res = reader.buffer.getInt32(reader.offset, Endian.big);
    reader.offset += 4;
    return res;
  }
}

class Int64Serializer implements Serializer<int> {
  const Int64Serializer();

  @override
  void serialize(int object, BytesBuilder builder) {
    final binary = ByteData(8);
    binary.setInt64(0, object, Endian.big);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  int deserialize(BytesReader reader) {
    final res = reader.buffer.getInt64(reader.offset, Endian.big);
    reader.offset += 8;
    return res;
  }
}

typedef IntSerializer = Int64Serializer;
