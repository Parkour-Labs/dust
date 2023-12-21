import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qinhuai/serializers.dart';

String randomString(Random random, int maxLength) {
  const chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890 喵了个咪';
  final length = random.nextInt(maxLength);
  return String.fromCharCodes(
    Iterable.generate(
      length,
      (_) => chars.codeUnitAt(random.nextInt(chars.length)),
    ),
  );
}

void fixedTest<T>(Iterable<T> values, Serializer<T> serializer) {
  for (final value in values) {
    final builder = BytesBuilder();
    serializer.serialize(value, builder);
    final reader = BytesReader(ByteData.view(builder.toBytes().buffer));
    expect(serializer.deserialize(reader), value);
  }
}

void randomTest<T>(
  T Function() generator,
  Serializer<T> serializer, {
  int iterations = 100,
}) {
  fixedTest(
    Iterable.generate(iterations, (_) => generator()),
    serializer,
  );
}

void randomIntTest(
  Random random,
  (int, int) intRange,
  Serializer<int> serializer, {
  int iterations = 100,
}) {
  randomTest<int>(
    () {
      final (lower, upper) = intRange;
      return random.nextInt(upper - lower + 1) + lower;
    },
    serializer,
    iterations: iterations,
  );
}

void main() {
  final random = Random();

  test('Int8Serializer should be consistent', () {
    fixedTest([-128, 0, 1, 127], const Int8Serializer());
    randomIntTest(random, (-128, 127), const Int8Serializer());
  });

  test('Uint8Serializer should be consistent', () {
    fixedTest([0, 1, 255], const Uint8Serializer());
    randomIntTest(random, (0, 255), const Uint8Serializer());
  });

  test('Int16Serializer should be consistent', () {
    fixedTest([-32768, 0, 1, 32767], const Int16Serializer());
    randomIntTest(random, (-32768, 32767), const Int16Serializer());
  });

  test('Uint16Serializer should be consistent', () {
    fixedTest([0, 1, 65535], const Uint16Serializer());
    randomIntTest(random, (0, 65535), const Uint16Serializer());
  });

  test('Int32Serializer should be consistent', () {
    fixedTest([-2147483648, 0, 1, 2147483647], const Int32Serializer());
    randomIntTest(random, (-2147483648, 2147483647), const Int32Serializer());
  });

  test('Uint32Serializer should be consistent', () {
    fixedTest([0, 1, 4294967295], const Uint32Serializer());
    randomIntTest(random, (0, 4294967295), const Uint32Serializer());
  });

  test('Int64Serializer should be consistent', () {
    fixedTest([-(1 << 63), 0, 1, (1 << 63) - 1], const Int64Serializer());
    randomTest(
      () => (random.nextInt(1 << 32) << 32) + random.nextInt(1 << 32),
      const Int64Serializer(),
    );
  });

  test('Uint64Serializer should be consistent', () {
    fixedTest([-(1 << 63), 0, 1, (1 << 63) - 1], const Uint64Serializer());
    randomTest(
      () => (random.nextInt(1 << 32) << 32) + random.nextInt(1 << 32),
      const Uint64Serializer(),
    );
  });

  test('BoolSerializer should be consistent', () {
    fixedTest([false, true], const BoolSerializer());
  });

  test('Float32Serializer should be consistent', () {
    fixedTest([0.0, 1.0], const Float32Serializer());
    randomTest(
      () {
        final value = random.nextDouble() * (1 << random.nextInt(32));
        final buffer = Uint8List(4);
        final view = ByteData.view(buffer.buffer);
        view.setFloat32(0, value, Endian.little);
        return view.getFloat32(0, Endian.little);
      },
      const Float32Serializer(),
    );
  });

  test('Float64Serializer should be consistent', () {
    fixedTest([0.0, 1.0], const Float64Serializer());
    randomTest(
      () => random.nextDouble() * (1 << random.nextInt(32)),
      const Float64Serializer(),
    );
  });

  test('Uint8ListSerializer should be consistent', () {
    fixedTest([Uint8List(0), Uint8List(1)], const Uint8ListSerializer());
    randomTest(
      () {
        final length = random.nextInt(100);
        final bytes = Uint8List(length);
        for (var i = 0; i < length; i++) {
          bytes[i] = random.nextInt(256);
        }
        return bytes;
      },
      const Uint8ListSerializer(),
      iterations: 100,
    );
  });

  test('StringSerializer should be consistent', () {
    fixedTest(['', ' '], const StringSerializer());
    randomTest(
      () => randomString(random, 100),
      const StringSerializer(),
      iterations: 100,
    );
  });
}
