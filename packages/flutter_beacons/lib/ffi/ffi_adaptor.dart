import 'dart:ffi' as ffi;
import 'dart:typed_data';

final class Id extends ffi.Struct {
  @ffi.Uint64()
  external int high;
  @ffi.Uint64()
  external int low;
}

final class NodeEvent {
  final int port;
  final int? value;
  const NodeEvent(this.port, this.value);
}

final class AtomEvent {
  final int port;
  final Uint8List? value;
  const AtomEvent(this.port, this.value);
}

final class EdgeEvent {
  final int port;
  final (Id, int, Id)? value;
  const EdgeEvent(this.port, this.value);
}

sealed class IdSetEvent {
  final int port;
  const IdSetEvent(this.port);
}

final class IdSetInsertEvent extends IdSetEvent {
  final Id element;
  const IdSetInsertEvent(super.port, this.element);
}

final class IdSetRemoveEvent extends IdSetEvent {
  final Id element;
  const IdSetRemoveEvent(super.port, this.element);
}

final class Events {
  List<NodeEvent> nodes = [];
  List<AtomEvent> atoms = [];
  List<EdgeEvent> edges = [];
  List<IdSetEvent> multiedges = [];
  List<IdSetEvent> backedges = [];
}

final class FfiAdaptor {
  int? node(Id id) => throw UnimplementedError();
  Uint8List? atom(Id id) => throw UnimplementedError();
  (Id, int, Id)? edge(Id id) => throw UnimplementedError();
  List<Id> queryEdgeBySrc(Id src) => throw UnimplementedError();
  List<Id> queryEdgeBySrcLabel(Id src, int label) => throw UnimplementedError();
  List<Id> queryEdgeByDstLabel(Id dst, int label) => throw UnimplementedError();

  void setNode(Id id, int? value) => throw UnimplementedError();
  void setAtom(Id id, Uint8List? value) => throw UnimplementedError();
  void setEdge(Id id, (Id, int, Id)? value) => throw UnimplementedError();
  void setEdgeDst(Id id, int dst) => throw UnimplementedError();

  void subscribeNode(Id id, int port) => throw UnimplementedError();
  void unsubscribeNode(Id id, int port) => throw UnimplementedError();
  void subscribeAtom(Id id, int port) => throw UnimplementedError();
  void unsubscribeAtom(Id id, int port) => throw UnimplementedError();
  void subscribeEdge(Id id, int port) => throw UnimplementedError();
  void unsubscribeEdge(Id id, int port) => throw UnimplementedError();
  void subscribeMultiEdge(Id src, int label, int port) => throw UnimplementedError();
  void unsubscribeMultiEdge(Id src, int label, int port) => throw UnimplementedError();
  void subscribeBackEdge(Id dst, int label, int port) => throw UnimplementedError();
  void unsubscribeBackEdge(Id dst, int label, int port) => throw UnimplementedError();

  Events takeEvents() => throw UnimplementedError();

  Uint8List syncClocks() => throw UnimplementedError();
  Uint8List syncActions(Uint8List clocks) => throw UnimplementedError();
  void syncApply(Uint8List actions) => throw UnimplementedError();

  /// Obtains the global FFI adaptor.
  static FfiAdaptor instance() => throw UnimplementedError();
}
