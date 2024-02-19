import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dust/serializers.dart';

Uint8List serialize<T>(T value, Serializer<T> serializer) {
  final builder = BytesBuilder();
  serializer.serialize(value, builder);
  return builder.takeBytes();
}

T deserialize<T>(List<int> bytes, Serializer<T> serializer) {
  return serializer
      .deserialize(BytesReader(Uint8List.fromList(bytes).buffer.asByteData()));
}

bool listEquals<T>(List<T> lhs, List<T> rhs) {
  if (lhs.length != rhs.length) return false;
  for (var i = 0; i < lhs.length; i++) {
    if (lhs[i] != rhs[i]) return false;
  }
  return true;
}

void main() {
  test('Example should work', () {
    assert(listEquals(
      serialize(1, const Uint64Serializer()),
      [0, 0, 0, 0, 0, 0, 0, 1],
    ));

    assert(listEquals(
      serialize(-2, const Int64Serializer()),
      [255, 255, 255, 255, 255, 255, 255, 254],
    ));

    assert(deserialize(
          [0, 0, 0, 0, 0, 0, 0, 1],
          const Uint64Serializer(),
        ) ==
        1);

    assert(deserialize(
          [255, 255, 255, 255, 255, 255, 255, 254],
          const Int64Serializer(),
        ) ==
        -2);

    assert(listEquals(
      serialize(null, const OptionSerializer(Int64Serializer())),
      [0],
    ));

    assert(listEquals(
      serialize(-1, const OptionSerializer(Int64Serializer())),
      [1, 255, 255, 255, 255, 255, 255, 255, 255],
    ));

    assert(deserialize(
          [0],
          const OptionSerializer(Int64Serializer()),
        ) ==
        null);

    assert(deserialize(
          [1, 255, 255, 255, 255, 255, 255, 255, 255],
          const OptionSerializer(Int64Serializer()),
        ) ==
        -1);
  });
}
