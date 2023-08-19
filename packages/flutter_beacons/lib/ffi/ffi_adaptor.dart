import 'dart:ffi' as ffi;
import 'dart:typed_data';

final class Id extends ffi.Struct {
  @ffi.Uint64()
  external int high;
  @ffi.Uint64()
  external int low;
}

final class FfiAdaptor {
  Id hash(String name) => throw UnimplementedError();
  int? node(Id id) => throw UnimplementedError();
  Uint8List? atom(Id id) => throw UnimplementedError();
  (Id, int, Id)? edge(Id id) => throw UnimplementedError();
  List<(Id, (Id, int, Id))> getEdgesBySrc(Id src) => throw UnimplementedError();
  List<(Id, Id)> getIdDstBySrcLabel(Id src, int label) => throw UnimplementedError();
  List<(Id, Id)> getIdSrcByDstLabel(Id dst, int label) => throw UnimplementedError();

  void setNode(Id id, int? value) => throw UnimplementedError();
  void setAtom(Id id, Uint8List? value) => throw UnimplementedError();
  void setEdge(Id id, (Id, int, Id)? value) => throw UnimplementedError();
  void setEdgeDst(Id id, Id? dst) => throw UnimplementedError();

  void subscribeNode(Id id, int port) => throw UnimplementedError();
  void unsubscribeNode(Id id, int port) => throw UnimplementedError();
  void subscribeAtom(Id id, int port) => throw UnimplementedError();
  void unsubscribeAtom(Id id, int port) => throw UnimplementedError();
  void subscribeEdge(Id id, int port) => throw UnimplementedError();
  void unsubscribeEdge(Id id, int port) => throw UnimplementedError();
  void subscribeMultiedge(Id src, int label, int port) => throw UnimplementedError();
  void unsubscribeMultiedge(Id src, int label, int port) => throw UnimplementedError();
  void subscribeBackedge(Id dst, int label, int port) => throw UnimplementedError();
  void unsubscribeBackedge(Id dst, int label, int port) => throw UnimplementedError();

  Uint8List syncVersion() => throw UnimplementedError();
  Uint8List syncActions(Uint8List version) => throw UnimplementedError();
  void syncJoin(Uint8List actions) => throw UnimplementedError();

  void pollEvents() => throw UnimplementedError();

  /// Obtains the global FFI adaptor.
  static FfiAdaptor instance() => throw UnimplementedError();
}
