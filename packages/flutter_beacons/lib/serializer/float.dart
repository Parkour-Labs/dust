import 'dart:typed_data';

import '../serializer.dart';

class Float32Serializer implements Serializer<double> {
  const Float32Serializer();

  @override
  void serialize(double object, BytesBuilder builder) {
    final binary = ByteData(4);
    binary.setFloat32(0, object, Endian.big);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  double deserialize(BytesReader reader) {
    final res = reader.buffer.getFloat32(reader.offset, Endian.big);
    reader.offset += 4;
    return res;
  }
}

class Float64Serializer implements Serializer<double> {
  const Float64Serializer();

  @override
  void serialize(double object, BytesBuilder builder) {
    final binary = ByteData(8);
    binary.setFloat64(0, object, Endian.big);
    builder.add(binary.buffer.asUint8List());
  }

  @override
  double deserialize(BytesReader reader) {
    final res = reader.buffer.getFloat64(reader.offset, Endian.big);
    reader.offset += 8;
    return res;
  }
}

typedef DoubleSerializer = Float64Serializer;
