import 'dart:convert' show utf8;
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

void serializeBool(bool object, BytesBuilder builder) {
  builder.addByte(object ? 1 : 0);
}

bool deserializeBool(BytesReader reader) {
  final res = reader.buffer.getUint8(reader.offset);
  reader.offset += 1;
  return res != 0;
}

void serializeInt(int object, BytesBuilder builder) {
  final binary = ByteData(8);
  binary.setInt64(0, object, Endian.big);
  builder.add(binary.buffer.asUint8List());
}

int deserializeInt(BytesReader reader) {
  final res = reader.buffer.getInt64(reader.offset, Endian.big);
  reader.offset += 8;
  return res;
}

void serializeDouble(double object, BytesBuilder builder) {
  final binary = ByteData(8);
  binary.setFloat64(0, object, Endian.big);
  builder.add(binary.buffer.asUint8List());
}

double deserializeDouble(BytesReader reader) {
  final res = reader.buffer.getFloat64(reader.offset, Endian.big);
  reader.offset += 8;
  return res;
}

void serializeString(String object, BytesBuilder builder) {
  final bytes = utf8.encode(object);
  serializeInt(bytes.length, builder);
  builder.add(bytes);
}

String deserializeString(BytesReader reader) {
  final length = deserializeInt(reader);
  final bytes = <int>[];
  for (var i = 0; i < length; i++) {
    bytes.add(reader.buffer.getUint8(reader.offset + i));
  }
  reader.offset += length;
  return utf8.decode(bytes);
}

const Serializer<bool> kBoolSerializer = Serializer(serializeBool, deserializeBool);
const Serializer<int> kIntSerializer = Serializer(serializeInt, deserializeInt);
const Serializer<double> kDoubleSerializer = Serializer(serializeDouble, deserializeDouble);
const Serializer<String> kStringSerializer = Serializer(serializeString, deserializeString);
