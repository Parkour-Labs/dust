import '../store.dart';
import '../reactive.dart';
import '../serializer.dart';

class AtomOption<T> extends Node implements Observable<T?> {
  final Serializer<T> serializer;
  final Id id;
  final Id src;
  final int label;
  T? value;

  AtomOption._(this.serializer, this.id, this.src, this.label);

  @override
  T? get(Node? ref) {
    register(ref);
    return value;
  }

  void _update((Id, int, Object?)? slv) {
    value = slv == null ? null : (slv.$3 as T);
    notify();
  }

  void set(T? value) {
    Store.instance.setAtom<T>(id, value == null ? null : (src, label, value, serializer));
  }
}

class Atom<T> extends Node implements Observable<T> {
  final Serializer<T> serializer;
  final Id id;
  final Id src;
  final int label;
  late T value;

  Atom._(this.serializer, this.id, this.src, this.label);

  @override
  T get(Node? ref) {
    register(ref);
    return value;
  }

  void _update((Id, int, Object?)? slv) {
    value = slv!.$3 as T;
    notify();
  }

  void set(T value) {
    Store.instance.setAtom<T>(id, (src, label, value, serializer));
  }
}

extension GetAtomExtension on Store {
  Atom<T> getAtom<T>(Id id, Id src, int label, Serializer<T> serializer) {
    final res = Atom<T>._(serializer, id, src, label);
    final weak = WeakReference(res);
    subscribeAtomById(id, (data) => weak.target?._update(data), serializer, res);
    return res;
  }

  AtomOption<T> getAtomOption<T>(Id id, Id src, int label, Serializer<T> serializer) {
    final res = AtomOption<T>._(serializer, id, src, label);
    final weak = WeakReference(res);
    subscribeAtomById(id, (data) => weak.target?._update(data), serializer, res);
    return res;
  }
}
