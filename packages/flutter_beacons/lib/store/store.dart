import 'dart:typed_data';

import '../reactive/reactive.dart';
import '../ffi/ffi_adaptor.dart';
import '../serializer/serializer.dart';

final ffi = FfiAdaptor.instance();

class Store {
  int ports = 0;
  int newPort() => ports++;

  final Map<int, (Id, Function(ByteData))> atomSubscriptions = {};
  final Map<int, (Id, Function(int))> nodeSubscriptions = {};
  final Map<int, (Id, Function(Id, int, Id))> edgeSubscriptions = {};
  final Map<int, (Id, int, Function(Id), Function(Id))> idSetSubscriptions = {};

  /// These will not get dropped since [Store] is a global singleton.
  late final Finalizer nodeSubscriptionFinalizer = Finalizer<int>(unsubscribeNode);
  late final Finalizer atomSubscriptionFinalizer = Finalizer<int>(unsubscribeAtom);
  late final Finalizer edgeSubscriptionFinalizer = Finalizer<int>(unsubscribeEdge);
  late final Finalizer multiEdgeSubscriptionFinalizer = Finalizer<int>(unsubscribeMultiEdge);
  late final Finalizer backEdgeSubscriptionFinalizer = Finalizer<int>(unsubscribeBackEdge);

  void subscribeNode(Id id, int port, Function(int label) change, Object owner) {
    assert(!nodeSubscriptions.containsKey(port));
    nodeSubscriptions[port] = (id, change);
    ffi.subscribeNode(id, port);
    nodeSubscriptionFinalizer.attach(owner, port);
  }

  void unsubscribeNode(int port) {
    final subscription = nodeSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeNode(subscription.$1, port);
  }

  void subscribeAtom(Id id, int port, Function(ByteData data) change, Object owner) {
    assert(!atomSubscriptions.containsKey(port));
    atomSubscriptions[port] = (id, change);
    ffi.subscribeAtom(id, port);
    atomSubscriptionFinalizer.attach(owner, port);
  }

  void unsubscribeAtom(int port) {
    final subscription = atomSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeAtom(subscription.$1, port);
  }

  void subscribeEdge(Id id, int port, Function(Id src, int label, Id dst) change, Object owner) {
    assert(!edgeSubscriptions.containsKey(port));
    edgeSubscriptions[port] = (id, change);
    ffi.subscribeEdge(id, port);
    edgeSubscriptionFinalizer.attach(owner, port);
  }

  void unsubscribeEdge(int port) {
    final subscription = edgeSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeEdge(subscription.$1, port);
  }

  void subscribeMultiEdge(
      Id src, int label, int port, Function(Id element) insert, Function(Id element) remove, Object owner) {
    assert(!idSetSubscriptions.containsKey(port));
    idSetSubscriptions[port] = (src, label, insert, remove);
    ffi.subscribeMultiEdge(src, label, port);
    multiEdgeSubscriptionFinalizer.attach(owner, port);
  }

  void unsubscribeMultiEdge(int port) {
    final subscription = idSetSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeMultiEdge(subscription.$1, subscription.$2, port);
  }

  void subscribeBackEdge(
      Id src, int label, int port, Function(Id element) insert, Function(Id element) remove, Object owner) {
    assert(!idSetSubscriptions.containsKey(port));
    idSetSubscriptions[port] = (src, label, insert, remove);
    ffi.subscribeBackEdge(src, label, port);
    backEdgeSubscriptionFinalizer.attach(owner, port);
  }

  void unsubscribeBackEdge(int port) {
    final subscription = idSetSubscriptions.remove(port);
    if (subscription != null) ffi.unsubscribeBackEdge(subscription.$1, subscription.$2, port);
  }

  Atom<T> atom<T>(Id id, Serializer<T> serializer) {
    final res = Atom<T>(serializer);
    final weak = WeakReference(res);
    subscribeAtom(id, newPort(), (data) => weak.target?._set(data), res);
    return res;
  }
}

class Atom<T> extends Node implements Observable<T> {
  late T value;
  final Serializer<T> serializer;

  Atom(this.serializer);

  @override
  T get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T peek() {
    return value;
  }

  void _set(ByteData data) {
    value = serializer.deserialize(BytesReader(data));
    notify();
  }
}

/*
class Edge<T extends Object> extends Node implements Observable<T> {
  WeakReference<T>? target;

  Edge() {}

  @override
  T get(WeakReference<Node> ref) {}

  @override
  T peek() {}

  void _set(ByteData data) {}
}
*/
