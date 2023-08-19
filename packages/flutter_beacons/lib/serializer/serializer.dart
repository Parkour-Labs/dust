import 'dart:typed_data';

class Serializer<T extends Object> {
  final void Function(T object, BytesBuilder builder) serialize;
  final T Function(BytesReader reader) deserialize;

  const Serializer(this.serialize, this.deserialize);
}

class BytesReader {
  final ByteData buffer;
  int offset = 0;

  BytesReader(this.buffer);
}

void _int8Serialize(int object, BytesBuilder builder) {
  final binary = ByteData(1);
  binary.setInt8(0, object);
  builder.add(binary.buffer.asUint8List());
}

void _int16Serialize(int object, BytesBuilder builder) {
  final binary = ByteData(2);
  binary.setInt16(0, object, Endian.big);
  builder.add(binary.buffer.asUint8List());
}

void _int32Serialize(int object, BytesBuilder builder) {
  final binary = ByteData(4);
  binary.setInt32(0, object, Endian.big);
  builder.add(binary.buffer.asUint8List());
}

void _int64Serialize(int object, BytesBuilder builder) {
  final binary = ByteData(8);
  binary.setInt64(0, object, Endian.big);
  builder.add(binary.buffer.asUint8List());
}

int _int8Deserialize(BytesReader reader) {
  final res = reader.buffer.getInt8(reader.offset);
  reader.offset += 1;
  return res;
}

int _int16Deserialize(BytesReader reader) {
  final res = reader.buffer.getInt16(reader.offset, Endian.big);
  reader.offset += 2;
  return res;
}

int _int32Deserialize(BytesReader reader) {
  final res = reader.buffer.getInt32(reader.offset, Endian.big);
  reader.offset += 4;
  return res;
}

int _int64Deserialize(BytesReader reader) {
  final res = reader.buffer.getInt64(reader.offset, Endian.big);
  reader.offset += 8;
  return res;
}

const Serializer<int> kInt8Serializer = Serializer(_int8Serialize, _int8Deserialize);
const Serializer<int> kInt16Serializer = Serializer(_int16Serialize, _int16Deserialize);
const Serializer<int> kInt32Serializer = Serializer(_int32Serialize, _int32Deserialize);
const Serializer<int> kInt64Serializer = Serializer(_int64Serialize, _int64Deserialize); // TODO
