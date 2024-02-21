import 'dart:convert';
import 'dart:typed_data';

/// **Important**: if you may ever need to change the serialization format of
/// your data, you should use a [VersionedSerializer] or an
/// [ExtensibleSerializer] instead of a [Serializer].
///
/// Implement this interface **only if** you are sure that you will never need
/// to change the serialization format of your data.
///
/// Dust has provided a set of serializers that are **stable** and will most
/// likely never change. You can find them in the `serializers` directory. These
/// serializers implement this interface directly.
///
/// If you are a little unsure about whether if you will need to change the
/// bit encoding of your data, you can extend the [VersionedSerializer] class.
/// It adds a little overhead to your serialization format (one extra byte),
/// but it allows you to migrate from one version to another of your data.
///
/// If you will only append new fields in later versions of your data, you can
/// extend the [ExtensibleSerializer] class. It adds no overhead to your
/// serialization format, and it also allows backward compatibility with older
/// versions of your data.
///
/// # Discussion
///
/// Investigate on whether if we should change the name of this interface to
/// `UnsafeSerializer` or `UnversionedSerializer` or `RawSerializer` to alert
/// users that they should be careful when using this interface.
abstract interface class Serializer<T> {
  /// Serializes the [object] of type [T] into bytes by writing it to the
  /// `BytesBuilder` [builder].
  void serialize(T object, BytesBuilder builder);

  /// Reads the bytes from the `BytesReader` [reader] and deserializes to the
  /// object of type [T].
  T deserialize(BytesReader reader);

  /// Creates a [Serializer] from the given [serializeFn] and [deserializeFn].
  const factory Serializer(
    void Function(T, BytesBuilder) serializeFn,
    T Function(BytesReader) deserializeFn,
  ) = _Serializer;
}

final class _Serializer<T> implements Serializer<T> {
  final void Function(T, BytesBuilder) serializeFn;
  final T Function(BytesReader) deserializeFn;

  const _Serializer(this.serializeFn, this.deserializeFn);

  @override
  T deserialize(BytesReader reader) => deserializeFn(reader);

  @override
  void serialize(T object, BytesBuilder builder) =>
      serializeFn(object, builder);
}

const _kEndian = Endian.big;

class BytesReader {
  final ByteData buffer;
  int _offset = 0;

  BytesReader(this.buffer);

  int get offset => _offset;

  int readInt8() {
    final byte = buffer.getInt8(_offset);
    _offset += 1;
    return byte;
  }

  int readUint8() {
    final byte = buffer.getUint8(_offset);
    _offset += 1;
    return byte;
  }

  int readInt16() {
    final byte = buffer.getInt16(_offset, _kEndian);
    _offset += 2;
    return byte;
  }

  int readUint16() {
    final byte = buffer.getUint16(_offset, _kEndian);
    _offset += 2;
    return byte;
  }

  int readInt32() {
    final byte = buffer.getInt32(_offset, _kEndian);
    _offset += 4;
    return byte;
  }

  int readUint32() {
    final byte = buffer.getUint32(_offset, _kEndian);
    _offset += 4;
    return byte;
  }

  int readInt64() {
    final byte = buffer.getInt64(_offset, _kEndian);
    _offset += 8;
    return byte;
  }

  int readUint64() {
    final byte = buffer.getUint64(_offset, _kEndian);
    _offset += 8;
    return byte;
  }

  double readFloat32() {
    final byte = buffer.getFloat32(_offset, _kEndian);
    _offset += 4;
    return byte;
  }

  double readFloat64() {
    final byte = buffer.getFloat64(_offset, _kEndian);
    _offset += 8;
    return byte;
  }

  Uint8List readBytes() {
    final length = readUint64();
    final bytes = buffer.buffer.asUint8List(_offset, length);
    _offset += length;
    return bytes;
  }

  String readString() {
    final bytes = readBytes();
    return utf8.decode(bytes);
  }

  bool readBool() {
    final byte = readUint8();
    return byte != 0;
  }

  BoolPack readBoolPack() {
    final byte = readUint8();
    return BoolPack(byte);
  }
}

extension BytesBuilderWriteExtension on BytesBuilder {
  void writeInt8(int value) {
    assert(value >= -(1 << 7) && value < (1 << 7), 'Out of range');
    final buffer = Uint8List(1);
    final view = ByteData.view(buffer.buffer);
    view.setInt8(0, value);
    add(buffer);
  }

  void writeUint8(int value) {
    assert(value >= 0 && value < (1 << 8), 'Out of range');
    final buffer = Uint8List(1);
    final view = ByteData.view(buffer.buffer);
    view.setUint8(0, value);
    add(buffer);
  }

  void writeInt16(int value) {
    assert(value >= -(1 << 15) && value < (1 << 15), 'Out of range');
    final buffer = Uint8List(2);
    final view = ByteData.view(buffer.buffer);
    view.setInt16(0, value, _kEndian);
    add(buffer);
  }

  void writeUint16(int value) {
    assert(value >= 0 && value < (1 << 16), 'Out of range');
    final buffer = Uint8List(2);
    final view = ByteData.view(buffer.buffer);
    view.setUint16(0, value, _kEndian);
    add(buffer);
  }

  void writeInt32(int value) {
    assert(value >= -(1 << 31) && value < (1 << 31), 'Out of range');
    final buffer = Uint8List(4);
    final view = ByteData.view(buffer.buffer);
    view.setInt32(0, value, _kEndian);
    add(buffer);
  }

  void writeUint32(int value) {
    assert(value >= 0 && value < (1 << 32), 'Out of range');
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

  void writeBool(bool value) {
    writeUint8(value ? 1 : 0);
  }

  void writeBoolPack(BoolPack value) {
    writeUint8(value.data);
  }
}

class BoolPack {
  final int data;

  const BoolPack(this.data);

  bool get value0 => (data & (1 << 0)) != 0;

  bool get value1 => (data & (1 << 1)) != 0;

  bool get value2 => (data & (1 << 2)) != 0;

  bool get value3 => (data & (1 << 3)) != 0;

  bool get value4 => (data & (1 << 4)) != 0;

  bool get value5 => (data & (1 << 5)) != 0;

  bool get value6 => (data & (1 << 6)) != 0;

  bool get value7 => (data & (1 << 7)) != 0;

  factory BoolPack.values([
    bool value0 = false,
    bool value1 = false,
    bool value2 = false,
    bool value3 = false,
    bool value4 = false,
    bool value5 = false,
    bool value6 = false,
    bool value7 = false,
  ]) {
    var data = 0;
    data |= (value0 ? 1 : 0) << 0;
    data |= (value1 ? 1 : 0) << 1;
    data |= (value2 ? 1 : 0) << 2;
    data |= (value3 ? 1 : 0) << 3;
    data |= (value4 ? 1 : 0) << 4;
    data |= (value5 ? 1 : 0) << 5;
    data |= (value6 ? 1 : 0) << 6;
    data |= (value7 ? 1 : 0) << 7;
    return BoolPack(data);
  }

  BoolPack copyWith({
    bool? value0,
    bool? value1,
    bool? value2,
    bool? value3,
    bool? value4,
    bool? value5,
    bool? value6,
    bool? value7,
  }) {
    var result = data;
    result = _setIfNotNull(result, 0, value0);
    result = _setIfNotNull(result, 1, value1);
    result = _setIfNotNull(result, 2, value2);
    result = _setIfNotNull(result, 3, value3);
    result = _setIfNotNull(result, 4, value4);
    result = _setIfNotNull(result, 5, value5);
    result = _setIfNotNull(result, 6, value6);
    result = _setIfNotNull(result, 7, value7);
    return BoolPack(result);
  }

  static int _setIfNotNull(int data, int index, bool? value) {
    if (value == null) return data;
    if (value) {
      return data | (1 << index);
    } else {
      return data & ~(1 << index);
    }
  }
}
