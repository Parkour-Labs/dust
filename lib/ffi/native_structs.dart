import 'dart:ffi';

final class CId extends Struct {
  @Uint64()
  external int high;
  @Uint64()
  external int low;
}

final class CArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<Uint8> ptr;
}

final class CAtom extends Struct {
  external CId src;
  @Uint64()
  external int label;
  external CArrayUint8 value;
}

final class COptionAtom extends Struct {
  @Uint8()
  external int tag;
  external CAtom some;
}

final class CResultOptionAtom extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion1 body;
}

final class UnnamedUnion1 extends Union {
  external COptionAtom ok;
  external CArrayUint8 err;
}

final class CTripleIdUint64ArrayUint8 extends Struct {
  external CId first;
  @Uint64()
  external int second;
  external CArrayUint8 third;
}

final class CArrayTripleIdUint64ArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<CTripleIdUint64ArrayUint8> ptr;
}

final class CResultArrayTripleIdUint64ArrayUint8 extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion2 body;
}

final class UnnamedUnion2 extends Union {
  external CArrayTripleIdUint64ArrayUint8 ok;
  external CArrayUint8 err;
}

final class CPairIdId extends Struct {
  external CId first;
  external CId second;
}

final class CArrayPairIdId extends Struct {
  @Uint64()
  external int len;
  external Pointer<CPairIdId> ptr;
}

final class CResultArrayPairIdId extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion3 body;
}

final class UnnamedUnion3 extends Union {
  external CArrayPairIdId ok;
  external CArrayUint8 err;
}

final class CTripleIdIdArrayUint8 extends Struct {
  external CId first;
  external CId second;
  external CArrayUint8 third;
}

final class CArrayTripleIdIdArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<CTripleIdIdArrayUint8> ptr;
}

final class CResultArrayTripleIdIdArrayUint8 extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion4 body;
}

final class UnnamedUnion4 extends Union {
  external CArrayTripleIdIdArrayUint8 ok;
  external CArrayUint8 err;
}

final class CPairIdArrayUint8 extends Struct {
  external CId first;
  external CArrayUint8 second;
}

final class CArrayPairIdArrayUint8 extends Struct {
  @Uint64()
  external int len;
  external Pointer<CPairIdArrayUint8> ptr;
}

final class CResultArrayPairIdArrayUint8 extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion5 body;
}

final class UnnamedUnion5 extends Union {
  external CArrayPairIdArrayUint8 ok;
  external CArrayUint8 err;
}

final class CNode extends Struct {
  @Uint64()
  external int label;
}

final class COptionNode extends Struct {
  @Uint8()
  external int tag;
  external CNode some;
}

final class CEdge extends Struct {
  external CId src;
  @Uint64()
  external int label;
  external CId dst;
}

final class COptionEdge extends Struct {
  @Uint8()
  external int tag;
  external CEdge some;
}

final class NodeBody extends Struct {
  external CId id;
  external COptionNode prev;
  external COptionNode curr;
}

final class AtomBody extends Struct {
  external CId id;
  external COptionAtom prev;
  external COptionAtom curr;
}

final class EdgeBody extends Struct {
  external CId id;
  external COptionEdge prev;
  external COptionEdge curr;
}

final class CEventData extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion6 body;
}

final class UnnamedUnion6 extends Union {
  external NodeBody node;
  external AtomBody atom;
  external EdgeBody edge;
}

final class CArrayEventData extends Struct {
  @Uint64()
  external int len;
  external Pointer<CEventData> ptr;
}

final class CResultArrayEventData extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion7 body;
}

final class UnnamedUnion7 extends Union {
  external CArrayEventData ok;
  external CArrayUint8 err;
}

final class CUnit extends Struct {
  @Uint8()
  external int dummy;
}

final class CResultUnit extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion8 body;
}

final class UnnamedUnion8 extends Union {
  external CUnit ok;
  external CArrayUint8 err;
}

final class CArrayId extends Struct {
  @Uint64()
  external int len;
  external Pointer<CId> ptr;
}

final class CTripleIdIdUint64 extends Struct {
  external CId first;
  external CId second;
  @Uint64()
  external int third;
}

final class CArrayTripleIdIdUint64 extends Struct {
  @Uint64()
  external int len;
  external Pointer<CTripleIdIdUint64> ptr;
}

final class CTripleIdUint64Id extends Struct {
  external CId first;
  @Uint64()
  external int second;
  external CId third;
}

final class CArrayTripleIdUint64Id extends Struct {
  @Uint64()
  external int len;
  external Pointer<CTripleIdUint64Id> ptr;
}

final class CResultOptionEdge extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion9 body;
}

final class UnnamedUnion9 extends Union {
  external COptionEdge ok;
  external CArrayUint8 err;
}

final class CResultArrayTripleIdUint64Id extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion10 body;
}

final class UnnamedUnion10 extends Union {
  external CArrayTripleIdUint64Id ok;
  external CArrayUint8 err;
}

final class CResultArrayTripleIdIdUint64 extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion11 body;
}

final class UnnamedUnion11 extends Union {
  external CArrayTripleIdIdUint64 ok;
  external CArrayUint8 err;
}

final class CResultOptionNode extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion12 body;
}

final class UnnamedUnion12 extends Union {
  external COptionNode ok;
  external CArrayUint8 err;
}

final class CResultArrayId extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion13 body;
}

final class UnnamedUnion13 extends Union {
  external CArrayId ok;
  external CArrayUint8 err;
}

final class CResultArrayUint8 extends Struct {
  @Uint8()
  external int tag;
  external UnnamedUnion14 body;
}

final class UnnamedUnion14 extends Union {
  external CArrayUint8 ok;
  external CArrayUint8 err;
}
