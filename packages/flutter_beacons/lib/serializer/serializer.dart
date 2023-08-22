import 'dart:typed_data';

// See: https://serde.rs/data-model.html
export 'bool.dart';
export 'int.dart';
export 'uint.dart';
export 'float.dart';
export 'bytes.dart';
export 'string.dart';
export 'option.dart';
export 'list.dart';
export 'set.dart';
export 'map.dart';

abstract interface class Serializer<T> {
  void serialize(T object, BytesBuilder builder);
  T deserialize(BytesReader reader);
}

class BytesReader {
  final ByteData buffer;
  int offset = 0;

  BytesReader(this.buffer);
}
