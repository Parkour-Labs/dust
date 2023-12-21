export 'serializers/datetime.dart';
export 'serializers/enum.dart';
export 'serializers/float.dart';
export 'serializers/int.dart';
export 'serializers/list.dart';
export 'serializers/map.dart';
export 'serializers/option.dart';
export 'serializers/record.dart';
export 'serializers/set.dart';
export 'serializers/string.dart';
export 'serializers/uint.dart';
export 'serializers/uint8list.dart';
export 'serializers/bool.dart';

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

const _kEndian = Endian.big;

/// **Important**: if you may ever need to change the serialization format of
/// your data, you should use a [VersionedSerializer] or an
/// [ExtensibleSerializer] instead of a [Serializer].
///
/// Implement this interface **only if** you are sure that you will never need
/// to change the serialization format of your data.
///
/// Qinhuai has provided a set of serializers that are **stable** and will most
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

/// A [VersionedSerializer] is a serializer that can serialize and deserialize
/// multiple versions of the same data structure. It therefore makes it possible
/// to do migrations from one version to another of the data structure.
///
/// Data serialized using a [VersionedSerializer] has a single byte of overhead,
/// used to store the version of serializer that the data uses when being
/// serialized. Therefore, there could be **at most 256 versions** using a
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
/// - When adding new serializer, make sure only to **append** to the list.
///   Do not insert new serializers in the middle of the list.
/// - **Do not** remove or modify any serializers previously added.
///
/// # Extensibility
///
/// However, in the unlikely cases where you make more than 256 changes to the
/// serialization format, you can always extend this by making the last version
/// contain another [VersionedSerializer], effectively creating a linked list
/// of [VersionedSerializer]s. You just need to make sure that you do not
/// accidentally use the 256th serializer (last slot possible) storing a normal
/// serializer, because that would use up all of your extensibility. To prevent
/// this from accidentally happening, an assertion will fail if you've used up
/// all your serializer slots but the last one is not a [VersionedSerializer].
abstract base class VersionedSerializer<T> implements Serializer<T> {
  const VersionedSerializer();

  const factory VersionedSerializer.from(
    List<Serializer<T>> serializers,
  ) = _VersionedSerializer;

  /// The list of all serializers that this serializer uses. The last element
  /// represents the latest version of the serializer.
  List<Serializer<T>> get serializers;

  void check() {
    assert(
      serializers.length <= 256,
      'You have exceeded the 256 versions limit of a `VersionedSerializer`.',
    );
    assert(
      serializers.length != 256 || serializers.last is VersionedSerializer<T>,
      'You have used up all 256 versions of a `VersionedSerializer`, and the'
      'last slot is not a `VersionedSerializer`.',
    );
  }

  @override
  void serialize(T object, BytesBuilder builder) {
    check();
    final version = serializers.length - 1;
    builder.writeUint8(version);
    serializers[version].serialize(object, builder);
  }

  @override
  T deserialize(BytesReader reader) {
    check();
    final version = reader.readUint8();
    return serializers[version].deserialize(reader);
  }
}

final class _VersionedSerializer<T> extends VersionedSerializer<T> {
  @override
  final List<Serializer<T>> serializers;

  const _VersionedSerializer(this.serializers);
}

/// An [ExtensibleSerializer] is a serializer that can serialize and deserialize
/// multiple versions of the same data structure. It is based on the assumption
/// that the data's fields are added one by one and are ordered the same in all
/// versions of serialization formats. Therefore, the part of data that can be
/// deserialized would be the longest common prefix of the old and current
/// serialization formats.
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
///   List<Object?> getFields(MyData object) => [
///     object.firstField,
///     object.secondField,
///     object.thirdField,
///   ];
///
///   @override
///   MyData createObject(List<Object?> fields) => MyData(
///     firstField: fields[0],
///     secondField: fields[1],
///     thirdField: fields[2],
///   );
/// }
/// ```
///
/// # Important Notes
///
/// - **Do not** nest an [ExtensibleSerializer] inside another serializer.
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

  const factory ExtensibleSerializer.from(
    List<Serializer<Object?>> fieldSerializers,
    List<Object?> Function(T) getFieldsFn,
    T Function(List<Object?>) createObjectFn,
  ) = _ExtensibleSerializer;

  List<Serializer<Object?>> get fieldSerializers;

  /// Maps an object to the list of data of its fields. The ordering of the
  /// fields should be the same as the one returned by [getFields].
  List<Object?> getFields(T object);

  /// Creates an object from the list of data of its fields. The ordering of the
  /// fields should be the same as the one returned by [getFields].
  T createObject(List<Object?> fields);

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

  @override
  T deserialize(BytesReader reader) {
    final fields = <Object?>[];
    for (final serializer in fieldSerializers) {
      if (reader.offset == reader.buffer.lengthInBytes) break;
      final field = serializer.deserialize(reader);
      fields.add(field);
    }
    return createObject(fields);
  }
}

final class _ExtensibleSerializer<T> extends ExtensibleSerializer<T> {
  @override
  final List<Serializer<Object?>> fieldSerializers;
  final List<Object?> Function(T) getFieldsFn;
  final T Function(List<Object?>) createObjectFn;

  const _ExtensibleSerializer(
    this.fieldSerializers,
    this.getFieldsFn,
    this.createObjectFn,
  );

  @override
  T createObject(List fields) => createObjectFn(fields);

  @override
  List getFields(T object) => getFieldsFn(object);
}

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
