import 'dart:ffi';

final class CId extends Struct {
  @Uint64()
  external int high;
  @Uint64()
  external int low;
}

final class CPairIdArrayUint8 extends Struct {
  external CId first;
  external CArrayUint8 second;
}

final class CPairIdId extends Struct {
  external CId first;
  external CId second;
}

final class CTripleIdUint64ArrayUint8 extends Struct {
  external CId first;
  @Uint64()
  external int second;
  external CArrayUint8 third;
}

final class CTripleIdIdArrayUint8 extends Struct {
  external CId first;
  external CId second;
  external CArrayUint8 third;
}

final class CTripleIdUint64Id extends Struct {
  external CId first;
  @Uint64()
  external int second;
  external CId third;
}

final class CTripleIdIdId extends Struct {
  external CId first;
  external CId second;
  external CId third;
}

final class COptionAtom extends Struct {
  @Uint8()
  external int tag;
  external CAtom some;
}

final class COptionEdge extends Struct {
  @Uint8()
  external int tag;
  external CEdge some;
}

final class COptionArrayUint8 extends Struct {
  @Uint8()
  external int tag;
  external CArrayUint8 some;
}

final class CArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<Uint8> ptr;
}

final class CArrayPairIdArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<CPairIdArrayUint8> ptr;
}

final class CArrayPairIdId extends Struct {
  @Uint64()
  external int len;
  external Pointer<CPairIdId> ptr;
}

final class CArrayTripleIdUint64ArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<CTripleIdUint64ArrayUint8> ptr;
}

final class CArrayTripleIdIdArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<CTripleIdIdArrayUint8> ptr;
}

final class CArrayTripleIdUint64Id extends Struct {
  @Uint64()
  external int len;
  external Pointer<CTripleIdUint64Id> ptr;
}

final class CArrayTripleIdIdId extends Struct {
  @Uint64()
  external int len;
  external Pointer<CTripleIdIdId> ptr;
}

final class CArrayEventData extends Struct {
  @Uint64()
  external int len;
  external Pointer<CEventData> ptr;
}

final class CAtom extends Struct {
  external CId src;
  @Uint64()
  external int label;
  external CArrayUint8 value;
}

final class CEdge extends Struct {
  external CId src;
  @Uint64()
  external int label;
  external CId dst;
}

final class CEventDataAtom extends Struct {
  external CId id;
  external COptionAtom prev;
  external COptionAtom curr;
}

final class CEventDataEdge extends Struct {
  external CId id;
  external COptionEdge prev;
  external COptionEdge curr;
}

final class CEventDataUnion extends Union {
  external CEventDataAtom atom;
  external CEventDataEdge edge;
}

final class CEventData extends Struct {
  @Uint8()
  external int tag;
  external CEventDataUnion union;
}
