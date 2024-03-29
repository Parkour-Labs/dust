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

class Float32Serializer implements Serializer<double> {
  const Float32Serializer();

  @override
  void serialize(double object, BytesBuilder builder) =>
      builder.writeFloat32(object);

  @override
  double deserialize(BytesReader reader) => reader.readFloat32();
}

class Float64Serializer implements Serializer<double> {
  const Float64Serializer();

  @override
  void serialize(double object, BytesBuilder builder) =>
      builder.writeFloat64(object);

  @override
  double deserialize(BytesReader reader) => reader.readFloat64();
}

typedef DoubleSerializer = Float64Serializer;
