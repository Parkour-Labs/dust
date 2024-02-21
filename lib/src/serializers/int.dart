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

class Int8Serializer implements Serializer<int> {
  const Int8Serializer();

  @override
  void serialize(int object, BytesBuilder builder) => builder.writeInt8(object);

  @override
  int deserialize(BytesReader reader) => reader.readInt8();
}

class Int16Serializer implements Serializer<int> {
  const Int16Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeInt16(object);

  @override
  int deserialize(BytesReader reader) => reader.readInt16();
}

class Int32Serializer implements Serializer<int> {
  const Int32Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeInt32(object);

  @override
  int deserialize(BytesReader reader) => reader.readInt32();
}

class Int64Serializer implements Serializer<int> {
  const Int64Serializer();

  @override
  void serialize(int object, BytesBuilder builder) =>
      builder.writeInt64(object);

  @override
  int deserialize(BytesReader reader) => reader.readInt64();
}

typedef IntSerializer = Int64Serializer;
