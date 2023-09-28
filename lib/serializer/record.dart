import 'dart:typed_data';

import '../serializer.dart';

class Record1Serializer<A> implements Serializer<(A,)> {
  final Serializer<A> a;
  const Record1Serializer(this.a);

  @override
  void serialize((A,) object, BytesBuilder builder) {
    a.serialize(object.$1, builder);
  }

  @override
  (A,) deserialize(BytesReader reader) {
    final a = this.a.deserialize(reader);
    return (a,);
  }
}

class Record2Serializer<A, B> implements Serializer<(A, B)> {
  final Serializer<A> a;
  final Serializer<B> b;
  const Record2Serializer(this.a, this.b);

  @override
  void serialize((A, B) object, BytesBuilder builder) {
    a.serialize(object.$1, builder);
    b.serialize(object.$2, builder);
  }

  @override
  (A, B) deserialize(BytesReader reader) {
    final a = this.a.deserialize(reader);
    final b = this.b.deserialize(reader);
    return (a, b);
  }
}

class Record3Serializer<A, B, C> implements Serializer<(A, B, C)> {
  final Serializer<A> a;
  final Serializer<B> b;
  final Serializer<C> c;
  const Record3Serializer(this.a, this.b, this.c);

  @override
  void serialize((A, B, C) object, BytesBuilder builder) {
    a.serialize(object.$1, builder);
    b.serialize(object.$2, builder);
    c.serialize(object.$3, builder);
  }

  @override
  (A, B, C) deserialize(BytesReader reader) {
    final a = this.a.deserialize(reader);
    final b = this.b.deserialize(reader);
    final c = this.c.deserialize(reader);
    return (a, b, c);
  }
}

class Record4Serializer<A, B, C, D> implements Serializer<(A, B, C, D)> {
  final Serializer<A> a;
  final Serializer<B> b;
  final Serializer<C> c;
  final Serializer<D> d;
  const Record4Serializer(this.a, this.b, this.c, this.d);

  @override
  void serialize((A, B, C, D) object, BytesBuilder builder) {
    a.serialize(object.$1, builder);
    b.serialize(object.$2, builder);
    c.serialize(object.$3, builder);
    d.serialize(object.$4, builder);
  }

  @override
  (A, B, C, D) deserialize(BytesReader reader) {
    final a = this.a.deserialize(reader);
    final b = this.b.deserialize(reader);
    final c = this.c.deserialize(reader);
    final d = this.d.deserialize(reader);
    return (a, b, c, d);
  }
}
