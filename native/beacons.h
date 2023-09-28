#include <stdint.h>

#define CURRENT_VERSION 1

typedef struct CId {
  uint64_t high;
  uint64_t low;
} CId;

typedef struct CArrayUint8 {
  uint64_t len;
  uint8_t *ptr;
} CArrayUint8;

typedef struct CAtom {
  CId src;
  uint64_t label;
  CArrayUint8 value;
} CAtom;

typedef struct COptionAtom {
  uint8_t tag;
  CAtom some;
} COptionAtom;

typedef struct CResultOptionAtom {
  uint8_t tag;
  union {
    COptionAtom ok;
    CArrayUint8 err;
  };
} CResultOptionAtom;

typedef struct CTripleIdUint64ArrayUint8 {
  CId first;
  uint64_t second;
  CArrayUint8 third;
} CTripleIdUint64ArrayUint8;

typedef struct CArrayTripleIdUint64ArrayUint8 {
  uint64_t len;
  CTripleIdUint64ArrayUint8 *ptr;
} CArrayTripleIdUint64ArrayUint8;

typedef struct CResultArrayTripleIdUint64ArrayUint8 {
  uint8_t tag;
  union {
    CArrayTripleIdUint64ArrayUint8 ok;
    CArrayUint8 err;
  };
} CResultArrayTripleIdUint64ArrayUint8;

typedef struct CPairIdId {
  CId first;
  CId second;
} CPairIdId;

typedef struct CArrayPairIdId {
  uint64_t len;
  CPairIdId *ptr;
} CArrayPairIdId;

typedef struct CResultArrayPairIdId {
  uint8_t tag;
  union {
    CArrayPairIdId ok;
    CArrayUint8 err;
  };
} CResultArrayPairIdId;

typedef struct CTripleIdIdArrayUint8 {
  CId first;
  CId second;
  CArrayUint8 third;
} CTripleIdIdArrayUint8;

typedef struct CArrayTripleIdIdArrayUint8 {
  uint64_t len;
  CTripleIdIdArrayUint8 *ptr;
} CArrayTripleIdIdArrayUint8;

typedef struct CResultArrayTripleIdIdArrayUint8 {
  uint8_t tag;
  union {
    CArrayTripleIdIdArrayUint8 ok;
    CArrayUint8 err;
  };
} CResultArrayTripleIdIdArrayUint8;

typedef struct CPairIdArrayUint8 {
  CId first;
  CArrayUint8 second;
} CPairIdArrayUint8;

typedef struct CArrayPairIdArrayUint8 {
  uint64_t len;
  CPairIdArrayUint8 *ptr;
} CArrayPairIdArrayUint8;

typedef struct CResultArrayPairIdArrayUint8 {
  uint8_t tag;
  union {
    CArrayPairIdArrayUint8 ok;
    CArrayUint8 err;
  };
} CResultArrayPairIdArrayUint8;

typedef struct CNode {
  uint64_t label;
} CNode;

typedef struct COptionNode {
  uint8_t tag;
  CNode some;
} COptionNode;

typedef struct CEdge {
  CId src;
  uint64_t label;
  CId dst;
} CEdge;

typedef struct COptionEdge {
  uint8_t tag;
  CEdge some;
} COptionEdge;

typedef struct NodeBody {
  CId id;
  COptionNode prev;
  COptionNode curr;
} NodeBody;

typedef struct AtomBody {
  CId id;
  COptionAtom prev;
  COptionAtom curr;
} AtomBody;

typedef struct EdgeBody {
  CId id;
  COptionEdge prev;
  COptionEdge curr;
} EdgeBody;

typedef struct CEventData {
  uint8_t tag;
  union {
    NodeBody node;
    AtomBody atom;
    EdgeBody edge;
  };
} CEventData;

typedef struct CArrayEventData {
  uint64_t len;
  CEventData *ptr;
} CArrayEventData;

typedef struct CResultArrayEventData {
  uint8_t tag;
  union {
    CArrayEventData ok;
    CArrayUint8 err;
  };
} CResultArrayEventData;

typedef struct CUnit {
  uint8_t dummy;
} CUnit;

typedef struct CResultUnit {
  uint8_t tag;
  union {
    CUnit ok;
    CArrayUint8 err;
  };
} CResultUnit;

typedef struct CArrayId {
  uint64_t len;
  CId *ptr;
} CArrayId;

typedef struct CTripleIdIdUint64 {
  CId first;
  CId second;
  uint64_t third;
} CTripleIdIdUint64;

typedef struct CArrayTripleIdIdUint64 {
  uint64_t len;
  CTripleIdIdUint64 *ptr;
} CArrayTripleIdIdUint64;

typedef struct CTripleIdUint64Id {
  CId first;
  uint64_t second;
  CId third;
} CTripleIdUint64Id;

typedef struct CArrayTripleIdUint64Id {
  uint64_t len;
  CTripleIdUint64Id *ptr;
} CArrayTripleIdUint64Id;

typedef struct CResultOptionEdge {
  uint8_t tag;
  union {
    COptionEdge ok;
    CArrayUint8 err;
  };
} CResultOptionEdge;

typedef struct CResultArrayTripleIdUint64Id {
  uint8_t tag;
  union {
    CArrayTripleIdUint64Id ok;
    CArrayUint8 err;
  };
} CResultArrayTripleIdUint64Id;

typedef struct CResultArrayTripleIdIdUint64 {
  uint8_t tag;
  union {
    CArrayTripleIdIdUint64 ok;
    CArrayUint8 err;
  };
} CResultArrayTripleIdIdUint64;

typedef struct CResultOptionNode {
  uint8_t tag;
  union {
    COptionNode ok;
    CArrayUint8 err;
  };
} CResultOptionNode;

typedef struct CResultArrayId {
  uint8_t tag;
  union {
    CArrayId ok;
    CArrayUint8 err;
  };
} CResultArrayId;

typedef struct CResultArrayUint8 {
  uint8_t tag;
  union {
    CArrayUint8 ok;
    CArrayUint8 err;
  };
} CResultArrayUint8;

void add_acyclic_edge(uint64_t label);

void add_sticky_atom(uint64_t label);

void add_sticky_edge(uint64_t label);

void add_sticky_node(uint64_t label);

CResultOptionAtom atom(uint64_t idh, uint64_t idl);

CResultArrayTripleIdUint64ArrayUint8 atom_id_label_value_by_src(uint64_t srch,
                                                                uint64_t srcl);

CResultArrayPairIdId atom_id_src_by_label_value(uint64_t label, uint64_t len,
                                                uint8_t *ptr);

CResultArrayTripleIdIdArrayUint8 atom_id_src_value_by_label(uint64_t label);

CResultArrayPairIdArrayUint8
atom_id_value_by_src_label(uint64_t srch, uint64_t srcl, uint64_t label);

CResultArrayEventData barrier(void);

CResultUnit close(void);

CResultUnit commit(void);

/**
 * Drops the return value of [`barrier`].
 */
void drop_array_event_data(CArrayEventData value);

/**
 * Drops the return value of [`node_id_by_label`].
 */
void drop_array_id(CArrayId value);

/**
 * Drops the return value of [`atom_id_value_by_src_label`].
 */
void drop_array_id_array_u8(CArrayPairIdArrayUint8 value);

/**
 * Drops the return value of [`atom_id_src_by_label_value`],
 * [`edge_id_dst_by_src_label`] and [`edge_id_src_by_dst_label`].
 */
void drop_array_id_id(CArrayPairIdId value);

/**
 * Drops the return value of [`atom_id_src_value_by_label`].
 */
void drop_array_id_id_array_u8(CArrayTripleIdIdArrayUint8 value);

/**
 * Drops the return value of [`edge_id_src_label_by_dst`].
 */
void drop_array_id_id_u64(CArrayTripleIdIdUint64 value);

/**
 * Drops the return value of [`atom_id_label_value_by_src`].
 */
void drop_array_id_u64_array_u8(CArrayTripleIdUint64ArrayUint8 value);

/**
 * Drops the return value of [`edge_id_label_dst_by_src`].
 */
void drop_array_id_u64_id(CArrayTripleIdUint64Id value);

/**
 * Drops the return value of [`sync_version`] and [`sync_actions`] and all error
 * results.
 */
void drop_array_u8(CArrayUint8 value);

/**
 * Drops the return value of [`atom`].
 */
void drop_option_atom(COptionAtom value);

CResultOptionEdge edge(uint64_t idh, uint64_t idl);

CResultArrayPairIdId edge_id_dst_by_src_label(uint64_t srch, uint64_t srcl,
                                              uint64_t label);

CResultArrayTripleIdUint64Id edge_id_label_dst_by_src(uint64_t srch,
                                                      uint64_t srcl);

CResultArrayPairIdId edge_id_src_by_dst_label(uint64_t dsth, uint64_t dstl,
                                              uint64_t label);

CResultArrayTripleIdIdUint64 edge_id_src_label_by_dst(uint64_t dsth,
                                                      uint64_t dstl);

CResultOptionNode node(uint64_t idh, uint64_t idl);

CResultArrayId node_id_by_label(uint64_t label);

CResultUnit open(uint64_t len, uint8_t *ptr);

CId random_id(void);

CResultUnit set_atom_none(uint64_t idh, uint64_t idl);

CResultUnit set_atom_some(uint64_t idh, uint64_t idl, uint64_t srch,
                          uint64_t srcl, uint64_t label, uint64_t len,
                          uint8_t *ptr);

CResultUnit set_edge_none(uint64_t idh, uint64_t idl);

CResultUnit set_edge_some(uint64_t idh, uint64_t idl, uint64_t srch,
                          uint64_t srcl, uint64_t label, uint64_t dsth,
                          uint64_t dstl);

CResultUnit set_node_none(uint64_t idh, uint64_t idl);

CResultUnit set_node_some(uint64_t idh, uint64_t idl, uint64_t label);

CResultArrayUint8 sync_actions(uint64_t len, uint8_t *ptr);

CResultUnit sync_join(uint64_t len, uint8_t *ptr);

CResultArrayUint8 sync_version(void);

CArrayEventData test_array_event_data(void);

CArrayEventData test_array_event_data_big(uint64_t entries, uint64_t size);

CArrayPairIdId test_array_id_id(void);

CArrayTripleIdUint64Id test_array_id_u64_id(void);

CArrayUint8 test_array_u8(void);

CArrayUint8 test_array_u8_big(uint64_t size);

CId test_id(void);

CId test_id_unsigned(void);

COptionAtom test_option_atom_none(void);

COptionAtom test_option_atom_some(void);

COptionEdge test_option_edge_none(void);

COptionEdge test_option_edge_some(void);
