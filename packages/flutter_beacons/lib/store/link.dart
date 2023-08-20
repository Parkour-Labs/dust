part of 'store.dart';

class LinkOption<T extends Model> extends Node implements Observable<T?> {
  final Repository<T> repository;
  final CId id;
  CId? dst;

  LinkOption.fromRaw(this.repository, this.id);

  @override
  T? get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T? peek() {
    return repository.get(dst);
  }

  void _update((CId, int, CId)? data) {
    dst = data?.$3;
    notify();
  }

  void set(T? value) {
    ffi.setEdgeDst(id, value?.id());
    // TODO: take events
  }
}

class Link<T extends Model> extends Node implements Observable<T> {
  final Repository<T> repository;
  final CId id;
  late CId dst;

  Link.fromRaw(this.repository, this.id);

  @override
  T get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T peek() {
    return repository.get(dst)!;
  }

  void _update((CId, int, CId)? data) {
    dst = data!.$3;
    notify();
  }

  void set(T value) {
    ffi.setEdgeDst(id, value.id());
    // TODO: take events
  }
}
