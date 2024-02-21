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

import 'dart:typed_data';

import '../serializers.dart';

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
