import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

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

const _kEndian = Endian.big;

/// **IMPORTANT**: if you may ever need to change the serialization format of
/// your data, you should use a [VersionedSerializer] or an
/// [ExtensibleSerializer] instead of a [Serializer].
///
/// Implement this interface **ONLY IF** you are sure that you will never need
/// to change the serialization format of your data.
///
/// Qinhuai has provided a set of serializers that are **stable** and will most
/// likely never change. You can find them in the `serializer` directory. These
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
}

/// A [VersionedSerializer] is a serializer that can serialize and deserialize
/// multiple versions of the same data structure. It therefore makes it possible
/// to do migrations from one version to another of the data structure.
///
/// Data serialized using a [VersionedSerializer] has a single byte of overhead,
/// used to store the version of serializer that the data uses when being
/// serialized. Therefore, there could be **maximally 128 versions** using a
/// single [VersionedSerializer]. This would be plenty in most cases as you
/// probably would not need that many api changes in a single data object --
/// and since we are using binary based encoding, changing names of fields do
/// not need a change in the schema.
///
/// # Usage
///
/// ```dart
/// class MySerializer extends VersionedSerializer<MyData> {
///   const MySerializer(): super();
///
///   List<Serializer<MyData>> get serializers => const [
///     FirstSerializer(), // version code: 0
///     SecondSerializer(), // version code: 1
///   ];
/// }
/// ```
///
/// # Important Notes
///
/// - when adding serializer for a new version, make sure to **ADD IT TO THE
///   END**.
/// - make sure you **DO NOT** remove any serializers added previously.
///
/// # Extensibility
///
/// However, in the unlikely cases where you make more than 128 changes to the
/// serialization format, you can always extend this by making the last version
/// contain another [VersionedSerializer], effectively creating a linked list
/// of [VersionedSerializer]s. You just need to make sure that you do not
/// accidentally use the 128th serializer (last slot possible) storing a normal
/// serializer, because that would use up all of your extensibility. To prevent
/// this from accidentally happening, you will receive a warning when you only
/// have 5 versions left, and assertion will fail if you've used up all your
/// serializer slots but the last one is not a [VersionedSerializer].
abstract base class VersionedSerializer<T> implements Serializer<T> {
  const VersionedSerializer();

  /// The list of all serializers that this serializer uses. The last element
  /// represents the latest version of the serializer.
  List<Serializer<T>> get serializers;

  void checkCapacityAndShowWarning() {
    if (serializers.length > 123 &&
        serializers.last is! VersionedSerializer<T>) {
      debugPrint(
        'You have used up ${serializers.length} out of 128 versions for a '
        '`VersionedSerializer`. To ensure future extensibility, ensure to '
        'add a `VersionedSerializer` to the end.',
      );
    }
    if (serializers.length >= 128) {
      assert(
        serializers.last is VersionedSerializer<T>,
        'You have used up ${serializers.length} out of 128 versions of a'
        '`VersionedSerializer` and the last version is not a '
        '`VersionedSerializer`.',
      );
    }
  }

  @nonVirtual
  @override
  void serialize(T object, BytesBuilder builder) {
    checkCapacityAndShowWarning();
    final version = serializers.length - 1;
    builder.writeUint8(version);
    serializers[version].serialize(object, builder);
  }

  @nonVirtual
  @override
  T deserialize(BytesReader reader) {
    checkCapacityAndShowWarning();
    final version = reader.readUint8();
    return serializers[version].deserialize(reader);
  }
}

/// An [ExtensibleSerializer] is a serializer that can serialize and deserialize
/// multiple versions of the same data structure. It is based on the assumption
/// that the data's fields are in the same order in all the different
/// serialization formats. Therefore, the part of data that can be deserialized
/// would be the longest common prefix of all the serialization formats.
///
/// This makes it possible to add new fields to the data structure without
/// breaking backward compatibility with older versions of the data structure,
/// as older versions would simply ignore the new fields.
///
/// # Usage
///
/// ```dart
/// class MySerializer extends ExtensibleSerializer<MyData> {
///   const MySerializer(): super();
///
///   @override
///   List<Serializer<MyData>> get fieldSerializers => const [
///     FirstFieldSerializer(), // serializer for the first field
///     SecondFieldSerializer(), // serializer for the second field
///     ThirdFieldSerializer(), // serializer for the third field
///   ];
///
///   @override
///   List<dynamic> getFields(MyData object) => [
///     object.firstField,
///     object.secondField,
///     object.thirdField,
///   ];
///
///   @override
///   MyData createObject(List<dynamic> fields) => MyData(
///     firstField: fields[0],
///     secondField: fields[1],
///     thirdField: fields[2],
///   );
/// }
/// ```
///
/// # Discussion
///
/// While it may seem like a good idea to have the serializer being backwards
/// compatible, it is not always a good case. There are some cases where you
/// may want to enforce a breaking change in the data format, such as raising
/// the longest common prefix to include more fields as it evolves or changing
/// the order of the fields.
///
/// Therefore, in the initial design of your data structure, you may want to
/// use this as the inner serializer of a [VersionedSerializer] to ensure that
/// in the case where you need to make a breaking change, you can easily do so.
abstract base class ExtensibleSerializer<T> implements Serializer<T> {
  const ExtensibleSerializer();

  List<Serializer<dynamic>> get fieldSerializers;

  /// Maps an object to the list of data of its fields. The ordering of the
  /// fields should be the same as the one returned by [getFields].
  List<dynamic> getFields(T object);

  /// Creates an object from the list of data of its fields. The ordering of the
  /// fields should be the same as the one returned by [getFields].
  T createObject(List<dynamic> fields);

  @nonVirtual
  @override
  void serialize(T object, BytesBuilder builder) {
    final fields = getFields(object);
    final length = min(fieldSerializers.length, fields.length);
    for (var i = 0; i < length; i++) {
      final serializer = fieldSerializers[i];
      final field = fields[i];
      serializer.serialize(field, builder);
    }
  }

  @nonVirtual
  @override
  T deserialize(BytesReader reader) {
    final fields = <dynamic>[];
    for (final serializer in fieldSerializers) {
      // TODO: add `canDeserialize` method to serializer interface
      if (reader.offset >= reader.buffer.lengthInBytes) break;
      final field = serializer.deserialize(reader);
      fields.add(field);
    }
    return createObject(fields);
  }
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
