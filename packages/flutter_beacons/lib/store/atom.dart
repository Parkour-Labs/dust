part of 'store.dart';

class AtomOption<T> extends Node implements Observable<T?> {
  final Serializer<T> serializer;
  final Id id;
  T? value;

  AtomOption._(this.serializer, this.id);

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

class Atom<T> extends Node implements Observable<T> {
  final Serializer<T> serializer;
  final Id id;
  T? value;

  Atom._(this.serializer, this.id);

  @override
  T get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T peek() {
    return value!;
  }

  void _update(T? data) {
    value = data;
    notify();
  }

  void set(T? value) {
    Store.instance.setAtom<T>(serializer, id, value);
  }
}
