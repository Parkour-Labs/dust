import 'serializer.dart';

class Model {
  const Model();
}

class Serializable<T> {
  final Serializer<T> serializer;
  const Serializable(this.serializer);
}

class Backlink {
  final String name;
  const Backlink(this.name);
}

class Transient {
  const Transient();
}

class Global {
  const Global();
}
