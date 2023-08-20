import 'dart:ffi';

final class CId extends Struct {
  @Uint64()
  external int high;
  @Uint64()
  external int low;
}

final class CEdge extends Struct {
  external CId src;
  @Uint64()
  external int label;
  external CId dst;
}

final class CPairIdId extends Struct {
  external CId first;
  external CId second;
}

final class CPairIdEdge extends Struct {
  external CId first;
  external CEdge second;
}

final class CArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<Uint8> ptr;
}

final class CArrayPairIdId extends Struct {
  @Uint64()
  external int len;
  external Pointer<CPairIdId> ptr;
}

final class CArrayPairIdEdge extends Struct {
  @Uint64()
  external int len;
  external Pointer<CPairIdEdge> ptr;
}

final class COptionUint64 extends Struct {
  @Uint8()
  external int tag;
  @Uint64()
  external int some;
}

final class COptionArrayUint8 extends Struct {
  @Uint8()
  external int tag;
  external CArrayUint8 some;
}

final class COptionEdge extends Struct {
  @Uint8()
  external int tag;
  external CEdge some;
}

final class CEventDataUnion extends Union {
  external COptionUint64 node;
  external COptionArrayUint8 atom;
  external COptionEdge edge;
  external CPairIdId multiedgeInsert;
  external CPairIdId multiedgeRemove;
  external CPairIdId backedgeInsert;
  external CPairIdId backedgeRemove;
}

final class CEventData extends Struct {
  @Uint8()
  external int tag;
  external CEventDataUnion union;
}

final class CPairUint64EventData extends Struct {
  @Uint64()
  external int first;
  external CEventData second;
}

final class CArrayPairUint64EventData extends Struct {
  @Uint64()
  external int len;
  external Pointer<CPairUint64EventData> ptr;
}
