import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qinhuai/serializer.dart';

const _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890 ';

void main() {
  final random = Random();

  String generateRandomString([int maxLength = 100]) {
    final length = random.nextInt(maxLength);
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => _chars.codeUnitAt(random.nextInt(_chars.length)),
      ),
    );
  }

  void Function() createRandomTest<T>(
    T Function(Random) generator,
    void Function(BytesBuilder, T) write,
    T Function(BytesReader) read, {
    int iterations = 1000000,
  }) {
    return () {
      final builder = BytesBuilder();
      final values = <T>[];
      for (var i = 0; i < iterations; i++) {
        final value = generator(random);
        values.add(value);
        write(builder, value);
      }
      final reader = BytesReader(ByteData.view(builder.toBytes().buffer));
      for (final value in values) {
        expect(read(reader), value);
      }
    };
  }

  void Function() createIntTest(
    (int, int) intRange,
    void Function(BytesBuilder, int) write,
    int Function(BytesReader) read, {
    int iterations = 100,
  }) {
    return createRandomTest<int>(
      (random) {
        final (lower, upper) = intRange;
        return random.nextInt(upper - lower + 1) + lower;
      },
      write,
      read,
      iterations: iterations,
    );
  }

  test(
    'readInt8 and writeInt8 should be consistent',
    createIntTest(
      (-128, 127),
      (builder, value) => builder.writeInt8(value),
      (reader) => reader.readInt8(),
    ),
  );

  test(
    'readUint8 and writeUint8 should be consistent',
    createIntTest(
      (0, 255),
      (builder, value) => builder.writeUint8(value),
      (reader) => reader.readUint8(),
    ),
  );

  test(
    'readInt16 and writeInt16 should be consistent',
    createIntTest(
      (-32768, 32767),
      (builder, value) => builder.writeInt16(value),
      (reader) => reader.readInt16(),
    ),
  );

  test(
    'readUint16 and writeUint16 should be consistent',
    createIntTest(
      (0, 65535),
      (builder, value) => builder.writeUint16(value),
      (reader) => reader.readUint16(),
    ),
  );

  test(
    'readInt32 and writeInt32 should be consistent',
    createIntTest(
      (-2147483648, 2147483647),
      (builder, value) => builder.writeInt32(value),
      (reader) => reader.readInt32(),
    ),
  );

  test(
    'readUint32 and writeUint32 should be consistent',
    createIntTest(
      (0, 4294967295),
      (builder, value) => builder.writeUint32(value),
      (reader) => reader.readUint32(),
    ),
  );

  test(
    'readInt64 and writeInt64 should be consistent',
    createRandomTest<int>(
      (random) =>
          random.nextInt(1 << 31) *
          random.nextInt(1 << 31) *
          (random.nextBool() ? 1 : -1),
      (builder, value) => builder.writeInt64(value),
      (reader) => reader.readInt64(),
    ),
  );

  test(
    'readUint64 and writeUint64 should be consistent',
    createRandomTest<int>(
      (random) => random.nextInt(1 << 32) * random.nextInt(1 << 32),
      (builder, value) => builder.writeUint64(value),
      (reader) => reader.readUint64(),
    ),
  );

  test(
    'readBool and writeBool should be consistent',
    () {
      final builder = BytesBuilder();
      final values = <bool>[];
      for (var i = 0; i < 100; i++) {
        final value = random.nextBool();
        values.add(value);
        builder.writeBool(value);
      }
      final reader = BytesReader(ByteData.view(builder.toBytes().buffer));
      for (final value in values) {
        expect(reader.readBool(), value);
      }
    },
  );

  test(
    'readFloat32 and writeFloat32 should be consistent',
    createRandomTest<double>(
      (random) {
        final value = random.nextDouble() * (1 << random.nextInt(32));
        final buffer = Uint8List(4);
        final view = ByteData.view(buffer.buffer);
        view.setFloat32(0, value, Endian.little);
        return view.getFloat32(0, Endian.little);
      },
      (builder, value) => builder.writeFloat32(value),
      (reader) => reader.readFloat32(),
    ),
  );

  test(
    'readFloat64 and writeFloat64 should be consistent',
    createRandomTest<double>(
      (random) => random.nextDouble() * (1 << random.nextInt(32)),
      (builder, value) => builder.writeFloat64(value),
      (reader) => reader.readFloat64(),
    ),
  );

  test(
    'readBytes and writeBytes should be consistent',
    createRandomTest<Uint8List>(
      (random) {
        final length = random.nextInt(100);
        final bytes = Uint8List(length);
        for (var i = 0; i < length; i++) {
          bytes[i] = random.nextInt(256);
        }
        return bytes;
      },
      (builder, value) => builder.writeBytes(value),
      (reader) => reader.readBytes(),
      iterations: 10000,
    ),
  );

  test(
    'readString and writeString should be consistent',
    createRandomTest<String>(
      (random) => generateRandomString(),
      (builder, value) => builder.writeString(value),
      (reader) => reader.readString(),
      iterations: 10000,
    ),
  );
}
