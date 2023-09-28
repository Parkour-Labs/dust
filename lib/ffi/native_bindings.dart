// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ffi';
import 'dart:convert';

import 'native_structs.dart';
import 'native_library.dart';

/// Load and get the native function bindings.
NativeBindings getNativeBindings() => _nativeBindings ??= NativeBindings(getNativeLibrary());

NativeBindings? _nativeBindings;

/// Error thrown by native code.
class NativeError implements Exception {
  final String message;
  const NativeError(this.message);
  @override
  String toString() => message;
}

class NativeBindings {
  /// Holds the symbol lookup function.
  final Pointer<T> Function<T extends NativeType>(String symbolName) _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  NativeBindings(DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NativeBindings.fromLookup(Pointer<T> Function<T extends NativeType>(String symbolName) lookup) : _lookup = lookup;

  /// Handles native error.
  void _err(CArrayUint8 error) {
    final message = utf8.decode(error.ptr.asTypedList(error.len));
    drop_array_u8(error);
    throw NativeError(message);
  }

  void add_acyclic_edge(int label) {
    return _add_acyclic_edge(label);
  }

  late final _add_acyclic_edgePtr = _lookup<NativeFunction<Void Function(Uint64)>>('add_acyclic_edge');
  late final _add_acyclic_edge = _add_acyclic_edgePtr.asFunction<void Function(int)>();

  void add_sticky_atom(int label) {
    return _add_sticky_atom(label);
  }

  late final _add_sticky_atomPtr = _lookup<NativeFunction<Void Function(Uint64)>>('add_sticky_atom');
  late final _add_sticky_atom = _add_sticky_atomPtr.asFunction<void Function(int)>();

  void add_sticky_edge(int label) {
    return _add_sticky_edge(label);
  }

  late final _add_sticky_edgePtr = _lookup<NativeFunction<Void Function(Uint64)>>('add_sticky_edge');
  late final _add_sticky_edge = _add_sticky_edgePtr.asFunction<void Function(int)>();

  void add_sticky_node(int label) {
    return _add_sticky_node(label);
  }

  late final _add_sticky_nodePtr = _lookup<NativeFunction<Void Function(Uint64)>>('add_sticky_node');
  late final _add_sticky_node = _add_sticky_nodePtr.asFunction<void Function(int)>();

  COptionAtom atom(int idh, int idl) {
    final res = _atom(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _atomPtr = _lookup<NativeFunction<CResultOptionAtom Function(Uint64, Uint64)>>('atom');
  late final _atom = _atomPtr.asFunction<CResultOptionAtom Function(int, int)>();

  CArrayTripleIdUint64ArrayUint8 atom_id_label_value_by_src(int srch, int srcl) {
    final res = _atom_id_label_value_by_src(srch, srcl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _atom_id_label_value_by_srcPtr =
      _lookup<NativeFunction<CResultArrayTripleIdUint64ArrayUint8 Function(Uint64, Uint64)>>(
          'atom_id_label_value_by_src');
  late final _atom_id_label_value_by_src =
      _atom_id_label_value_by_srcPtr.asFunction<CResultArrayTripleIdUint64ArrayUint8 Function(int, int)>();

  CArrayPairIdId atom_id_src_by_label_value(int label, int len, Pointer<Uint8> ptr) {
    final res = _atom_id_src_by_label_value(label, len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _atom_id_src_by_label_valuePtr =
      _lookup<NativeFunction<CResultArrayPairIdId Function(Uint64, Uint64, Pointer<Uint8>)>>(
          'atom_id_src_by_label_value');
  late final _atom_id_src_by_label_value =
      _atom_id_src_by_label_valuePtr.asFunction<CResultArrayPairIdId Function(int, int, Pointer<Uint8>)>();

  CArrayTripleIdIdArrayUint8 atom_id_src_value_by_label(int label) {
    final res = _atom_id_src_value_by_label(label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _atom_id_src_value_by_labelPtr =
      _lookup<NativeFunction<CResultArrayTripleIdIdArrayUint8 Function(Uint64)>>('atom_id_src_value_by_label');
  late final _atom_id_src_value_by_label =
      _atom_id_src_value_by_labelPtr.asFunction<CResultArrayTripleIdIdArrayUint8 Function(int)>();

  CArrayPairIdArrayUint8 atom_id_value_by_src_label(int srch, int srcl, int label) {
    final res = _atom_id_value_by_src_label(srch, srcl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _atom_id_value_by_src_labelPtr =
      _lookup<NativeFunction<CResultArrayPairIdArrayUint8 Function(Uint64, Uint64, Uint64)>>(
          'atom_id_value_by_src_label');
  late final _atom_id_value_by_src_label =
      _atom_id_value_by_src_labelPtr.asFunction<CResultArrayPairIdArrayUint8 Function(int, int, int)>();

  CArrayEventData barrier() {
    final res = _barrier();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _barrierPtr = _lookup<NativeFunction<CResultArrayEventData Function()>>('barrier');
  late final _barrier = _barrierPtr.asFunction<CResultArrayEventData Function()>();

  CUnit close() {
    final res = _close();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _closePtr = _lookup<NativeFunction<CResultUnit Function()>>('close');
  late final _close = _closePtr.asFunction<CResultUnit Function()>();

  CUnit commit() {
    final res = _commit();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _commitPtr = _lookup<NativeFunction<CResultUnit Function()>>('commit');
  late final _commit = _commitPtr.asFunction<CResultUnit Function()>();

  /// Drops the return value of [`barrier`].
  void drop_array_event_data(CArrayEventData value) {
    return _drop_array_event_data(value);
  }

  late final _drop_array_event_dataPtr =
      _lookup<NativeFunction<Void Function(CArrayEventData)>>('drop_array_event_data');
  late final _drop_array_event_data = _drop_array_event_dataPtr.asFunction<void Function(CArrayEventData)>();

  /// Drops the return value of [`node_id_by_label`].
  void drop_array_id(CArrayId value) {
    return _drop_array_id(value);
  }

  late final _drop_array_idPtr = _lookup<NativeFunction<Void Function(CArrayId)>>('drop_array_id');
  late final _drop_array_id = _drop_array_idPtr.asFunction<void Function(CArrayId)>();

  /// Drops the return value of [`atom_id_value_by_src_label`].
  void drop_array_id_array_u8(CArrayPairIdArrayUint8 value) {
    return _drop_array_id_array_u8(value);
  }

  late final _drop_array_id_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayPairIdArrayUint8)>>('drop_array_id_array_u8');
  late final _drop_array_id_array_u8 = _drop_array_id_array_u8Ptr.asFunction<void Function(CArrayPairIdArrayUint8)>();

  /// Drops the return value of [`atom_id_src_by_label_value`],
  /// [`edge_id_dst_by_src_label`] and [`edge_id_src_by_dst_label`].
  void drop_array_id_id(CArrayPairIdId value) {
    return _drop_array_id_id(value);
  }

  late final _drop_array_id_idPtr = _lookup<NativeFunction<Void Function(CArrayPairIdId)>>('drop_array_id_id');
  late final _drop_array_id_id = _drop_array_id_idPtr.asFunction<void Function(CArrayPairIdId)>();

  /// Drops the return value of [`atom_id_src_value_by_label`].
  void drop_array_id_id_array_u8(CArrayTripleIdIdArrayUint8 value) {
    return _drop_array_id_id_array_u8(value);
  }

  late final _drop_array_id_id_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdArrayUint8)>>('drop_array_id_id_array_u8');
  late final _drop_array_id_id_array_u8 =
      _drop_array_id_id_array_u8Ptr.asFunction<void Function(CArrayTripleIdIdArrayUint8)>();

  /// Drops the return value of [`edge_id_src_label_by_dst`].
  void drop_array_id_id_u64(CArrayTripleIdIdUint64 value) {
    return _drop_array_id_id_u64(value);
  }

  late final _drop_array_id_id_u64Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdUint64)>>('drop_array_id_id_u64');
  late final _drop_array_id_id_u64 = _drop_array_id_id_u64Ptr.asFunction<void Function(CArrayTripleIdIdUint64)>();

  /// Drops the return value of [`atom_id_label_value_by_src`].
  void drop_array_id_u64_array_u8(CArrayTripleIdUint64ArrayUint8 value) {
    return _drop_array_id_u64_array_u8(value);
  }

  late final _drop_array_id_u64_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64ArrayUint8)>>('drop_array_id_u64_array_u8');
  late final _drop_array_id_u64_array_u8 =
      _drop_array_id_u64_array_u8Ptr.asFunction<void Function(CArrayTripleIdUint64ArrayUint8)>();

  /// Drops the return value of [`edge_id_label_dst_by_src`].
  void drop_array_id_u64_id(CArrayTripleIdUint64Id value) {
    return _drop_array_id_u64_id(value);
  }

  late final _drop_array_id_u64_idPtr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64Id)>>('drop_array_id_u64_id');
  late final _drop_array_id_u64_id = _drop_array_id_u64_idPtr.asFunction<void Function(CArrayTripleIdUint64Id)>();

  /// Drops the return value of [`sync_version`] and [`sync_actions`]
  /// and all error results.
  void drop_array_u8(CArrayUint8 value) {
    return _drop_array_u8(value);
  }

  late final _drop_array_u8Ptr = _lookup<NativeFunction<Void Function(CArrayUint8)>>('drop_array_u8');
  late final _drop_array_u8 = _drop_array_u8Ptr.asFunction<void Function(CArrayUint8)>();

  /// Drops the return value of [`atom`].
  void drop_option_atom(COptionAtom value) {
    return _drop_option_atom(value);
  }

  late final _drop_option_atomPtr = _lookup<NativeFunction<Void Function(COptionAtom)>>('drop_option_atom');
  late final _drop_option_atom = _drop_option_atomPtr.asFunction<void Function(COptionAtom)>();

  COptionEdge edge(int idh, int idl) {
    final res = _edge(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _edgePtr = _lookup<NativeFunction<CResultOptionEdge Function(Uint64, Uint64)>>('edge');
  late final _edge = _edgePtr.asFunction<CResultOptionEdge Function(int, int)>();

  CArrayPairIdId edge_id_dst_by_src_label(int srch, int srcl, int label) {
    final res = _edge_id_dst_by_src_label(srch, srcl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _edge_id_dst_by_src_labelPtr =
      _lookup<NativeFunction<CResultArrayPairIdId Function(Uint64, Uint64, Uint64)>>('edge_id_dst_by_src_label');
  late final _edge_id_dst_by_src_label =
      _edge_id_dst_by_src_labelPtr.asFunction<CResultArrayPairIdId Function(int, int, int)>();

  CArrayTripleIdUint64Id edge_id_label_dst_by_src(int srch, int srcl) {
    final res = _edge_id_label_dst_by_src(srch, srcl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _edge_id_label_dst_by_srcPtr =
      _lookup<NativeFunction<CResultArrayTripleIdUint64Id Function(Uint64, Uint64)>>('edge_id_label_dst_by_src');
  late final _edge_id_label_dst_by_src =
      _edge_id_label_dst_by_srcPtr.asFunction<CResultArrayTripleIdUint64Id Function(int, int)>();

  CArrayPairIdId edge_id_src_by_dst_label(int dsth, int dstl, int label) {
    final res = _edge_id_src_by_dst_label(dsth, dstl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _edge_id_src_by_dst_labelPtr =
      _lookup<NativeFunction<CResultArrayPairIdId Function(Uint64, Uint64, Uint64)>>('edge_id_src_by_dst_label');
  late final _edge_id_src_by_dst_label =
      _edge_id_src_by_dst_labelPtr.asFunction<CResultArrayPairIdId Function(int, int, int)>();

  CArrayTripleIdIdUint64 edge_id_src_label_by_dst(int dsth, int dstl) {
    final res = _edge_id_src_label_by_dst(dsth, dstl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _edge_id_src_label_by_dstPtr =
      _lookup<NativeFunction<CResultArrayTripleIdIdUint64 Function(Uint64, Uint64)>>('edge_id_src_label_by_dst');
  late final _edge_id_src_label_by_dst =
      _edge_id_src_label_by_dstPtr.asFunction<CResultArrayTripleIdIdUint64 Function(int, int)>();

  COptionNode node(int idh, int idl) {
    final res = _node(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _nodePtr = _lookup<NativeFunction<CResultOptionNode Function(Uint64, Uint64)>>('node');
  late final _node = _nodePtr.asFunction<CResultOptionNode Function(int, int)>();

  CArrayId node_id_by_label(int label) {
    final res = _node_id_by_label(label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _node_id_by_labelPtr = _lookup<NativeFunction<CResultArrayId Function(Uint64)>>('node_id_by_label');
  late final _node_id_by_label = _node_id_by_labelPtr.asFunction<CResultArrayId Function(int)>();

  CUnit open(int len, Pointer<Uint8> ptr) {
    final res = _open(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _openPtr = _lookup<NativeFunction<CResultUnit Function(Uint64, Pointer<Uint8>)>>('open');
  late final _open = _openPtr.asFunction<CResultUnit Function(int, Pointer<Uint8>)>();

  CId random_id() {
    return _random_id();
  }

  late final _random_idPtr = _lookup<NativeFunction<CId Function()>>('random_id');
  late final _random_id = _random_idPtr.asFunction<CId Function()>();

  CUnit set_atom_none(int idh, int idl) {
    final res = _set_atom_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _set_atom_nonePtr = _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>('set_atom_none');
  late final _set_atom_none = _set_atom_nonePtr.asFunction<CResultUnit Function(int, int)>();

  CUnit set_atom_some(int idh, int idl, int srch, int srcl, int label, int len, Pointer<Uint8> ptr) {
    final res = _set_atom_some(idh, idl, srch, srcl, label, len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _set_atom_somePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64, Pointer<Uint8>)>>(
          'set_atom_some');
  late final _set_atom_some =
      _set_atom_somePtr.asFunction<CResultUnit Function(int, int, int, int, int, int, Pointer<Uint8>)>();

  CUnit set_edge_none(int idh, int idl) {
    final res = _set_edge_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _set_edge_nonePtr = _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>('set_edge_none');
  late final _set_edge_none = _set_edge_nonePtr.asFunction<CResultUnit Function(int, int)>();

  CUnit set_edge_some(int idh, int idl, int srch, int srcl, int label, int dsth, int dstl) {
    final res = _set_edge_some(idh, idl, srch, srcl, label, dsth, dstl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _set_edge_somePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64, Uint64)>>(
          'set_edge_some');
  late final _set_edge_some = _set_edge_somePtr.asFunction<CResultUnit Function(int, int, int, int, int, int, int)>();

  CUnit set_node_none(int idh, int idl) {
    final res = _set_node_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _set_node_nonePtr = _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>('set_node_none');
  late final _set_node_none = _set_node_nonePtr.asFunction<CResultUnit Function(int, int)>();

  CUnit set_node_some(int idh, int idl, int label) {
    final res = _set_node_some(idh, idl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _set_node_somePtr = _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64, Uint64)>>('set_node_some');
  late final _set_node_some = _set_node_somePtr.asFunction<CResultUnit Function(int, int, int)>();

  CArrayUint8 sync_actions(int len, Pointer<Uint8> ptr) {
    final res = _sync_actions(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _sync_actionsPtr =
      _lookup<NativeFunction<CResultArrayUint8 Function(Uint64, Pointer<Uint8>)>>('sync_actions');
  late final _sync_actions = _sync_actionsPtr.asFunction<CResultArrayUint8 Function(int, Pointer<Uint8>)>();

  CUnit sync_join(int len, Pointer<Uint8> ptr) {
    final res = _sync_join(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _sync_joinPtr = _lookup<NativeFunction<CResultUnit Function(Uint64, Pointer<Uint8>)>>('sync_join');
  late final _sync_join = _sync_joinPtr.asFunction<CResultUnit Function(int, Pointer<Uint8>)>();

  CArrayUint8 sync_version() {
    final res = _sync_version();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _sync_versionPtr = _lookup<NativeFunction<CResultArrayUint8 Function()>>('sync_version');
  late final _sync_version = _sync_versionPtr.asFunction<CResultArrayUint8 Function()>();

  CArrayEventData test_array_event_data() {
    return _test_array_event_data();
  }

  late final _test_array_event_dataPtr = _lookup<NativeFunction<CArrayEventData Function()>>('test_array_event_data');
  late final _test_array_event_data = _test_array_event_dataPtr.asFunction<CArrayEventData Function()>();

  CArrayEventData test_array_event_data_big(int entries, int size) {
    return _test_array_event_data_big(entries, size);
  }

  late final _test_array_event_data_bigPtr =
      _lookup<NativeFunction<CArrayEventData Function(Uint64, Uint64)>>('test_array_event_data_big');
  late final _test_array_event_data_big =
      _test_array_event_data_bigPtr.asFunction<CArrayEventData Function(int, int)>();

  CArrayPairIdId test_array_id_id() {
    return _test_array_id_id();
  }

  late final _test_array_id_idPtr = _lookup<NativeFunction<CArrayPairIdId Function()>>('test_array_id_id');
  late final _test_array_id_id = _test_array_id_idPtr.asFunction<CArrayPairIdId Function()>();

  CArrayTripleIdUint64Id test_array_id_u64_id() {
    return _test_array_id_u64_id();
  }

  late final _test_array_id_u64_idPtr =
      _lookup<NativeFunction<CArrayTripleIdUint64Id Function()>>('test_array_id_u64_id');
  late final _test_array_id_u64_id = _test_array_id_u64_idPtr.asFunction<CArrayTripleIdUint64Id Function()>();

  CArrayUint8 test_array_u8() {
    return _test_array_u8();
  }

  late final _test_array_u8Ptr = _lookup<NativeFunction<CArrayUint8 Function()>>('test_array_u8');
  late final _test_array_u8 = _test_array_u8Ptr.asFunction<CArrayUint8 Function()>();

  CArrayUint8 test_array_u8_big(int size) {
    return _test_array_u8_big(size);
  }

  late final _test_array_u8_bigPtr = _lookup<NativeFunction<CArrayUint8 Function(Uint64)>>('test_array_u8_big');
  late final _test_array_u8_big = _test_array_u8_bigPtr.asFunction<CArrayUint8 Function(int)>();

  CId test_id() {
    return _test_id();
  }

  late final _test_idPtr = _lookup<NativeFunction<CId Function()>>('test_id');
  late final _test_id = _test_idPtr.asFunction<CId Function()>();

  CId test_id_unsigned() {
    return _test_id_unsigned();
  }

  late final _test_id_unsignedPtr = _lookup<NativeFunction<CId Function()>>('test_id_unsigned');
  late final _test_id_unsigned = _test_id_unsignedPtr.asFunction<CId Function()>();

  COptionAtom test_option_atom_none() {
    return _test_option_atom_none();
  }

  late final _test_option_atom_nonePtr = _lookup<NativeFunction<COptionAtom Function()>>('test_option_atom_none');
  late final _test_option_atom_none = _test_option_atom_nonePtr.asFunction<COptionAtom Function()>();

  COptionAtom test_option_atom_some() {
    return _test_option_atom_some();
  }

  late final _test_option_atom_somePtr = _lookup<NativeFunction<COptionAtom Function()>>('test_option_atom_some');
  late final _test_option_atom_some = _test_option_atom_somePtr.asFunction<COptionAtom Function()>();

  COptionEdge test_option_edge_none() {
    return _test_option_edge_none();
  }

  late final _test_option_edge_nonePtr = _lookup<NativeFunction<COptionEdge Function()>>('test_option_edge_none');
  late final _test_option_edge_none = _test_option_edge_nonePtr.asFunction<COptionEdge Function()>();

  COptionEdge test_option_edge_some() {
    return _test_option_edge_some();
  }

  late final _test_option_edge_somePtr = _lookup<NativeFunction<COptionEdge Function()>>('test_option_edge_some');
  late final _test_option_edge_some = _test_option_edge_somePtr.asFunction<COptionEdge Function()>();
}
