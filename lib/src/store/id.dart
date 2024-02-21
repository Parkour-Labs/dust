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

import '../ffi/native_structs.dart';

final class Id {
  final int high;
  final int low;

  const Id(this.high, this.low);

  Id.fromNative(CId cid)
      : high = cid.high,
        low = cid.low;

  @override
  bool operator ==(Object other) =>
      other is Id && other.high == high && other.low == low;

  @override
  int get hashCode => high ^ low;

  /// This is used for generating a deterministic, unique ID for unique atoms/links.
  /// Since both entity ID and label are random, a simple bitwise XOR would suffice.
  Id operator ^(int rhs) => Id(high, low ^ rhs);

  @override
  String toString() {
    return '${high.toRadixString(16)}${low.toRadixString(16)}';
  }
}
