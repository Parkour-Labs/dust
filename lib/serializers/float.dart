import 'dart:typed_data';

import '../serializer.dart';

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
