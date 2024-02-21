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

class MapSerializer<T, U> implements Serializer<Map<T, U>> {
  final Serializer<T> t;
  final Serializer<U> u;
  const MapSerializer(this.t, this.u);

  @override
  void serialize(Map<T, U> object, BytesBuilder builder) {
    builder.writeUint64(object.length);
    for (final elem in object.entries) {
      t.serialize(elem.key, builder);
      u.serialize(elem.value, builder);
    }
  }

  @override
  Map<T, U> deserialize(BytesReader reader) {
    final length = reader.readUint64();
    final res = <T, U>{};
    for (var i = 0; i < length; i++) {
      final key = t.deserialize(reader);
      final value = u.deserialize(reader);
      res[key] = value;
    }
    return res;
  }
}
