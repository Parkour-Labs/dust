import '../store.dart';
import '../reactive.dart';

class LinkOption<T> extends Node implements Observable<T?> {
  final Id id;
  final Id src;
  final int label;
  final Repository<T> repository;
  Id? dst;

  LinkOption(this.id, this.src, this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeById(id, (sld) => weak.target?._update(sld), this);
  }

  @override
  T? get(Node? o) {
    register(o);
    final dst = this.dst;
    return (dst == null) ? null : repository.get(dst).get(o);
  }

  void _update((Id, int, Id)? sld) {
    dst = (sld == null) ? null : sld.$3;
    notify();
  }

  void set(T? value) {
    Store.instance.setEdge(id, (value == null) ? null : (src, label, repository.id(value)));
  }
}

class Link<T> extends Node implements Observable<T> {
  RepositoryEntry<Object?>? parent;
  final Id id;
  final Id src;
  final int label;
  final Repository<T> repository;
  Id? dst;

  Link(this.id, this.src, this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeById(id, (sld) => weak.target?._update(sld), this);
  }

  bool get exists => dst != null;

  @override
  T get(Node? o) {
    register(o);
    final dst = this.dst;
    if (dst == null) throw AlreadyDeletedException();
    final res = repository.get(dst).get(o);
    if (res == null) throw AlreadyDeletedException();
    return res;
  }

  void _update((Id, int, Id)? sld) {
    final existenceChanged = (dst == null) != (sld == null);
    dst = (sld == null) ? null : sld.$3;
    if (existenceChanged) parent?.notify();
    notify();
  }

  void set(T value) {
    Store.instance.setEdge(id, (src, label, repository.id(value)));
  }
}
