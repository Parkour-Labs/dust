import 'dart:convert';
import 'dart:typed_data';

// See: https://serde.rs/data-model.html
export 'serializer/bool.dart';
export 'serializer/datetime.dart';
export 'serializer/enum.dart';
export 'serializer/float.dart';
export 'serializer/int.dart';
export 'serializer/list.dart';
export 'serializer/map.dart';
export 'serializer/option.dart';
export 'serializer/record.dart';
export 'serializer/set.dart';
export 'serializer/string.dart';
export 'serializer/uint.dart';
export 'serializer/uint8list.dart';

const _kEndian = Endian.little;

abstract interface class Serializer<T> {
  void serialize(T object, BytesBuilder builder);
  T deserialize(BytesReader reader);
}

class BytesReader {
  final ByteData buffer;
  int offset = 0;

  BytesReader(this.buffer);

  int readInt8() {
    final byte = buffer.getInt8(offset);
    offset += 1;
    return byte;
  }

  int readUint8() {
    final byte = buffer.getUint8(offset);
    offset += 1;
    return byte;
  }

  int readInt16() {
    final byte = buffer.getInt16(offset, _kEndian);
    offset += 2;
    return byte;
  }

  int readUint16() {
    final byte = buffer.getUint16(offset, _kEndian);
    offset += 2;
    return byte;
  }

  int readInt32() {
    final byte = buffer.getInt32(offset, _kEndian);
    offset += 4;
    return byte;
  }

  int readUint32() {
    final byte = buffer.getUint32(offset, _kEndian);
    offset += 4;
    return byte;
  }

  int readInt64() {
    final byte = buffer.getInt64(offset, _kEndian);
    offset += 8;
    return byte;
  }

  int readUint64() {
    final byte = buffer.getUint64(offset, _kEndian);
    offset += 8;
    return byte;
  }

  double readFloat32() {
    final byte = buffer.getFloat32(offset, _kEndian);
    offset += 4;
    return byte;
  }

  double readFloat64() {
    final byte = buffer.getFloat64(offset, _kEndian);
    offset += 8;
    return byte;
  }

  Uint8List readBytes() {
    final length = readUint64();
    final bytes = buffer.buffer.asUint8List(offset, length);
    offset += length;
    return bytes;
  }

  String readString() {
    final bytes = readBytes();
    return utf8.decode(bytes);
  }

  BoolPack readBoolPack() {
    final byte = readUint8();
    return byte;
  }

  bool readBool() {
    final byte = readUint8();
    return byte.value0;
  }
}

extension BytesBuilderX on BytesBuilder {
  void writeInt8(int value) {
    final buffer = Uint8List(1);
    final view = ByteData.view(buffer.buffer);
    view.setInt8(0, value);
    add(buffer);
  }

  void writeUint8(int value) {
    final buffer = Uint8List(1);
    final view = ByteData.view(buffer.buffer);
    view.setUint8(0, value);
    add(buffer);
  }

  void writeInt16(int value) {
    final buffer = Uint8List(2);
    final view = ByteData.view(buffer.buffer);
    view.setInt16(0, value, _kEndian);
    add(buffer);
  }

  void writeUint16(int value) {
    final buffer = Uint8List(2);
    final view = ByteData.view(buffer.buffer);
    view.setUint16(0, value, _kEndian);
    add(buffer);
  }

  void writeInt32(int value) {
    final buffer = Uint8List(4);
    final view = ByteData.view(buffer.buffer);
    view.setInt32(0, value, _kEndian);
    add(buffer);
  }

  void writeUint32(int value) {
    final buffer = Uint8List(4);
    final view = ByteData.view(buffer.buffer);
    view.setUint32(0, value, _kEndian);
    add(buffer);
  }

  void writeInt64(int value) {
    final buffer = Uint8List(8);
    final view = ByteData.view(buffer.buffer);
    view.setInt64(0, value, _kEndian);
    add(buffer);
  }

  void writeUint64(int value) {
    final buffer = Uint8List(8);
    final view = ByteData.view(buffer.buffer);
    view.setUint64(0, value, _kEndian);
    add(buffer);
  }

  void writeFloat32(double value) {
    final buffer = Uint8List(4);
    final view = ByteData.view(buffer.buffer);
    view.setFloat32(0, value, _kEndian);
    add(buffer);
  }

  void writeFloat64(double value) {
    final buffer = Uint8List(8);
    final view = ByteData.view(buffer.buffer);
    view.setFloat64(0, value, _kEndian);
    add(buffer);
  }

  void writeBytes(List<int> value) {
    final length = value.length;
    writeUint64(length);
    add(value);
  }

  void writeString(String value) {
    final bytes = utf8.encode(value);
    writeBytes(bytes);
  }

  void writeBool(
    bool value0, [
    bool value1 = false,
    bool value2 = false,
    bool value3 = false,
    bool value4 = false,
    bool value5 = false,
    bool value6 = false,
    bool value7 = false,
  ]) {
    int value = 0;
    if (value0) value |= 1 << 0;
    if (value1) value |= 1 << 1;
    if (value2) value |= 1 << 2;
    if (value3) value |= 1 << 3;
    if (value4) value |= 1 << 4;
    if (value5) value |= 1 << 5;
    if (value6) value |= 1 << 6;
    if (value7) value |= 1 << 7;
    writeUint8(value);
  }
}

typedef BoolPack = int;

extension BoolPackX on int {
  bool get value0 => (this & (1 << 0)) != 0;
  bool get value1 => (this & (1 << 1)) != 0;
  bool get value2 => (this & (1 << 2)) != 0;
  bool get value3 => (this & (1 << 3)) != 0;
  bool get value4 => (this & (1 << 4)) != 0;
  bool get value5 => (this & (1 << 5)) != 0;
  bool get value6 => (this & (1 << 6)) != 0;
  bool get value7 => (this & (1 << 7)) != 0;
}
