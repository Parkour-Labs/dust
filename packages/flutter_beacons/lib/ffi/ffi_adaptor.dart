import 'dart:typed_data';

import 'structs.dart';

final class FfiAdaptor {
  CId hash(String name) => throw UnimplementedError();
  int? node(CId id) => throw UnimplementedError();
  Uint8List? atom(CId id) => throw UnimplementedError();
  (CId, int, CId)? edge(CId id) => throw UnimplementedError();
  List<(CId, (CId, int, CId))> getEdgesBySrc(CId src) => throw UnimplementedError();
  List<(CId, CId)> getIdDstBySrcLabel(CId src, int label) => throw UnimplementedError();
  List<(CId, CId)> getIdSrcByDstLabel(CId dst, int label) => throw UnimplementedError();

  void setNode(CId id, int? value) => throw UnimplementedError();
  void setAtom(CId id, Uint8List? value) => throw UnimplementedError();
  void setEdge(CId id, (CId, int, CId)? value) => throw UnimplementedError();
  void setEdgeDst(CId id, CId? dst) => throw UnimplementedError();

  void subscribeNode(CId id, int port) => throw UnimplementedError();
  void unsubscribeNode(CId id, int port) => throw UnimplementedError();
  void subscribeAtom(CId id, int port) => throw UnimplementedError();
  void unsubscribeAtom(CId id, int port) => throw UnimplementedError();
  void subscribeEdge(CId id, int port) => throw UnimplementedError();
  void unsubscribeEdge(CId id, int port) => throw UnimplementedError();
  void subscribeMultiedge(CId src, int label, int port) => throw UnimplementedError();
  void unsubscribeMultiedge(CId src, int label, int port) => throw UnimplementedError();
  void subscribeBackedge(CId dst, int label, int port) => throw UnimplementedError();
  void unsubscribeBackedge(CId dst, int label, int port) => throw UnimplementedError();

  Uint8List syncVersion() => throw UnimplementedError();
  Uint8List syncActions(Uint8List version) => throw UnimplementedError();
  void syncJoin(Uint8List actions) => throw UnimplementedError();

  void pollEvents() => throw UnimplementedError();

  /// Obtains the global FFI adaptor.
  static FfiAdaptor instance() => throw UnimplementedError();
}
