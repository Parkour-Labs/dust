import '../store.dart';
import '../reactive.dart';

class LinkOption<T extends Object> extends Node implements Observable<T?> {
  final Repository<T> repository;
  final Id id;
  final Id src;
  final int label;
  Id? dst;

  LinkOption._(this.repository, this.id, this.src, this.label);

  @override
  T? get(Node? ref) {
    register(ref);
    return repository.get(dst);
  }

  void _update((Id, int, Id)? sld) {
    dst = sld?.$3;
    notify();
  }

  void set(T? value) {
    Store.instance.setEdge(id, value == null ? null : (src, label, repository.id(value)));
  }
}

class Link<T extends Object> extends Node implements Observable<T> {
  final Repository<T> repository;
  final Id id;
  final Id src;
  final int label;
  late Id dst;

  Link._(this.repository, this.id, this.src, this.label);

  @override
  T get(Node? ref) {
    register(ref);
    return repository.get(dst)!;
  }

  void _update((Id, int, Id)? data) {
    dst = data!.$3;
    notify();
  }

  void set(T value) {
    Store.instance.setEdge(id, (src, label, repository.id(value)));
  }
}

extension GetLinkExtension on Store {
  Link<T> getLink<T extends Object>(Id id, Id src, int label, Repository<T> repository) {
    final res = Link<T>._(repository, id, src, label);
    final weak = WeakReference(res);
    subscribeEdgeById(id, (data) => weak.target?._update(data), res);
    return res;
  }

  LinkOption<T> getLinkOption<T extends Object>(Id id, Id src, int label, Repository<T> repository) {
    final res = LinkOption<T>._(repository, id, src, label);
    final weak = WeakReference(res);
    subscribeEdgeById(id, (data) => weak.target?._update(data), res);
    return res;
  }
}
