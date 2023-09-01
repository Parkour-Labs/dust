import '../store.dart';
import '../reactive.dart';

class LinkOption<T> extends Node implements Observable<Ref<T>?> {
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
  Ref<T>? get(Node? ref) {
    register(ref);
    final dst = this.dst;
    return (dst == null) ? null : repository.get(dst);
  }

  /// A more convenient variant for [get].
  T? filter(Node? ref) => get(ref)?.get(ref);

  void _update((Id, int, Id)? sld) {
    dst = (sld == null) ? null : sld.$3;
    notify();
  }

  void set(Ref<T>? value) {
    Store.instance.setEdge(id, (value == null) ? null : (src, label, value.id));
  }
}

class Link<T> extends Node implements Observable<Ref<T>> {
  Ref<Object?>? parent;
  final Id id;
  final Id src;
  final int label;
  final Repository<T> repository;
  Id? dst;

  Link(this.id, this.src, this.label, this.repository) {
    final weak = WeakReference(this);
    Store.instance.subscribeEdgeById(id, (sld) => weak.target?._update(sld), this);
  }

  bool get isComplete => dst != null;

  @override
  Ref<T> get(Node? ref) {
    register(ref);
    return repository.get(dst!);
  }

  /// A more convenient variant for [get].
  T? filter(Node? ref) => get(ref).get(ref);

  void _update((Id, int, Id)? sld) {
    final completenessChanged = (dst == null) != (sld == null);
    dst = (sld == null) ? null : sld.$3;
    if (completenessChanged) parent?.notify();
    notify();
  }

  void set(Ref<T> value) {
    Store.instance.setEdge(id, (src, label, value.id));
  }
}
