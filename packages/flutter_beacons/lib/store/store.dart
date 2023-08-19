import 'dart:typed_data';

import '../reactive/reactive.dart';
import '../ffi/ffi_adaptor.dart';
import '../serializer/serializer.dart';

part 'repository.dart';
part 'atom.dart';
part 'link.dart';

T _deserialize<T extends Object>(Serializer<T> serializer, ByteData data) {
  return serializer.deserialize(BytesReader(data));
}

Uint8List _serialize<T extends Object>(Serializer<T> serializer, T value) {
  final bytes = BytesBuilder();
  serializer.serialize(value, bytes);
  return bytes.takeBytes();
}

final ffi = FfiAdaptor.instance();

class Store {
  int _ports = 0;
  int newPort() => _ports++;

  final Map<int, (Id, Function(ByteData?))> _atomSubscriptions = {};
  final Map<int, (Id, Function(int?))> _nodeSubscriptions = {};
  final Map<int, (Id, Function((Id, int, Id)?))> _edgeSubscriptions = {};
  final Map<int, (Id, int, Function(Id), Function(Id))> _multiedgeSubscriptions = {};
  final Map<int, (Id, int, Function(Id), Function(Id))> _backedgeSubscriptions = {};

  /// These will not get dropped since [Store] is a global singleton.
  late final Finalizer _nodeSubscriptionFinalizer = Finalizer<int>(_unsubscribeNode);
  late final Finalizer _atomSubscriptionFinalizer = Finalizer<int>(_unsubscribeAtom);
  late final Finalizer _edgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeEdge);
  late final Finalizer _multiedgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeMultiedge);
  late final Finalizer _backedgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeBackedge);

  void _subscribeNode(Id id, int port, Function(int? label) change, Object owner) {
    assert(!_nodeSubscriptions.containsKey(port));
    _nodeSubscriptions[port] = (id, change);
    ffi.subscribeNode(id, port);
    _nodeSubscriptionFinalizer.attach(owner, port);
    // TODO: take events
  }

  void _unsubscribeNode(int port) {
    final subscription = _nodeSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeNode(subscription.$1, port);
  }

  void _subscribeAtom(Id id, int port, Function(ByteData? data) change, Object owner) {
    assert(!_atomSubscriptions.containsKey(port));
    _atomSubscriptions[port] = (id, change);
    ffi.subscribeAtom(id, port);
    _atomSubscriptionFinalizer.attach(owner, port);
    // TODO: take events
  }

  void _unsubscribeAtom(int port) {
    final subscription = _atomSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeAtom(subscription.$1, port);
  }

  void _subscribeEdge(Id id, int port, Function((Id, int, Id)? value) change, Object owner) {
    assert(!_edgeSubscriptions.containsKey(port));
    _edgeSubscriptions[port] = (id, change);
    ffi.subscribeEdge(id, port);
    _edgeSubscriptionFinalizer.attach(owner, port);
    // TODO: take events
  }

  void _unsubscribeEdge(int port) {
    final subscription = _edgeSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeEdge(subscription.$1, port);
  }

  void _subscribeMultiedge(
      Id src, int label, int port, Function(Id element) insert, Function(Id element) remove, Object owner) {
    assert(!_multiedgeSubscriptions.containsKey(port));
    _multiedgeSubscriptions[port] = (src, label, insert, remove);
    ffi.subscribeMultiedge(src, label, port);
    _multiedgeSubscriptionFinalizer.attach(owner, port);
    // TODO: take events
  }

  void _unsubscribeMultiedge(int port) {
    final subscription = _multiedgeSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeMultiedge(subscription.$1, subscription.$2, port);
  }

  void _subscribeBackedge(
      Id src, int label, int port, Function(Id element) insert, Function(Id element) remove, Object owner) {
    assert(!_backedgeSubscriptions.containsKey(port));
    _backedgeSubscriptions[port] = (src, label, insert, remove);
    ffi.subscribeBackedge(src, label, port);
    _backedgeSubscriptionFinalizer.attach(owner, port);
    // TODO: take events
  }

  void _unsubscribeBackedge(int port) {
    final subscription = _backedgeSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeBackedge(subscription.$1, subscription.$2, port);
  }

  Atom<T> getAtom<T extends Object>(Serializer<T> serializer, Id id) {
    final res = Atom<T>.fromRaw(serializer, id);
    final weak = WeakReference(res);
    _subscribeAtom(id, newPort(), (data) => weak.target?._update(data), res);
    return res;
  }

  AtomOption<T> getAtomOption<T extends Object>(Serializer<T> serializer, Id id) {
    final res = AtomOption<T>.fromRaw(serializer, id);
    final weak = WeakReference(res);
    _subscribeAtom(id, newPort(), (data) => weak.target?._update(data), res);
    return res;
  }

  Link<T> getLink<T extends Model>(Repository<T> repository, Id id) {
    final res = Link<T>.fromRaw(repository, id);
    final weak = WeakReference(res);
    _subscribeEdge(id, newPort(), (data) => weak.target?._update(data), res);
    return res;
  }

  LinkOption<T> getLinkOption<T extends Model>(Repository<T> repository, Id id) {
    final res = LinkOption<T>.fromRaw(repository, id);
    final weak = WeakReference(res);
    _subscribeEdge(id, newPort(), (data) => weak.target?._update(data), res);
    return res;
  }
}
