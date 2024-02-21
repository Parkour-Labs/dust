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

class ListSerializer<T> implements Serializer<List<T>> {
  final Serializer<T> t;
  const ListSerializer(this.t);

  @override
  void serialize(List<T> object, BytesBuilder builder) {
    builder.writeUint64(object.length);
    for (final elem in object) {
      t.serialize(elem, builder);
    }
  }

  @override
  List<T> deserialize(BytesReader reader) {
    final length = reader.readUint64();
    final res = <T>[];
    for (var i = 0; i < length; i++) {
      res.add(t.deserialize(reader));
    }
    return res;
  }
}
