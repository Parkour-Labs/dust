// Copyright 2024 ParkourLabs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
export 'serializer.dart';

import 'serializer.dart';
import 'dart:math';
import 'dart:typed_data';

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
