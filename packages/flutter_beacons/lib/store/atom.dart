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

  void _update(T? data) {
    value = data;
    notify();
  }

  void set(T? value) {
    Store.instance.setAtom<T>(serializer, id, value);
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

  void _update(T? data) {
    value = data!;
    notify();
  }

  void set(T value) {
    Store.instance.setAtom<T>(serializer, id, value);
  }
}
