part of 'store.dart';

class AtomOption<T extends Object> extends Node implements Observable<T?> {
  final Serializer<T> serializer;
  final CId id;
  T? value;

  AtomOption.fromRaw(this.serializer, this.id);

  @override
  T? get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T? peek() {
    return value;
  }

  void _update(ByteData? data) {
    value = data == null ? null : _deserialize(serializer, data);
    notify();
  }

  void set(T? value) {
    ffi.setAtom(id, value == null ? null : _serialize(serializer, value));
    // TODO: take events
  }
}

class Atom<T extends Object> extends Node implements Observable<T> {
  final Serializer<T> serializer;
  final CId id;
  late T value;

  Atom.fromRaw(this.serializer, this.id);

  @override
  T get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T peek() {
    return value;
  }

  void _update(ByteData? data) {
    value = _deserialize(serializer, data!);
    notify();
  }

  void set(T value) {
    ffi.setAtom(id, _serialize(serializer, value));
    // TODO: take events
  }
}
