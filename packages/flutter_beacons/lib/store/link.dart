part of 'store.dart';

class LinkOption<T extends Object> extends Node implements Observable<T?> {
  final Repository<T> repository;
  final Id id;
  Id? dst;

  LinkOption._(this.repository, this.id);

  @override
  T? get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T? peek() {
    return repository.get(dst);
  }

  void _update((Id, int, Id)? data) {
    dst = data?.$3;
    notify();
  }

  void set(T? value) {
    Store.instance.setEdgeDst(id, value == null ? null : repository.id(value));
  }
}

class Link<T extends Object> extends Node implements Observable<T> {
  final Repository<T> repository;
  final Id id;
  Id? dst;

  Link._(this.repository, this.id);

  @override
  T get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T peek() {
    return repository.get(dst)!;
  }

  void _update((Id, int, Id)? data) {
    dst = data?.$3;
    notify();
  }

  void set(T value) {
    Store.instance.setEdgeDst(id, repository.id(value));
  }
}
