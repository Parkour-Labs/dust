import 'dart:typed_data';

// See: https://serde.rs/data-model.html
export 'serializer/bool.dart';
export 'serializer/int.dart';
export 'serializer/uint.dart';
export 'serializer/float.dart';
export 'serializer/datetime.dart';
export 'serializer/uint8list.dart';
export 'serializer/string.dart';
export 'serializer/option.dart';
export 'serializer/list.dart';
export 'serializer/set.dart';
export 'serializer/map.dart';

abstract interface class Serializer<T> {
  void serialize(T object, BytesBuilder builder);
  T deserialize(BytesReader reader);
}

class BytesReader {
  final ByteData buffer;
  int offset = 0;

  BytesReader(this.buffer);
}
