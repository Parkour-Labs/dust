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
    beacons_drop_array_u8(error);
    throw NativeError(message);
  }

  void beacons_add_acyclic_edge(int label) {
    return _beacons_add_acyclic_edge(label);
  }

  late final _beacons_add_acyclic_edgePtr = _lookup<NativeFunction<Void Function(Uint64)>>('beacons_add_acyclic_edge');
  late final _beacons_add_acyclic_edge = _beacons_add_acyclic_edgePtr.asFunction<void Function(int)>(isLeaf: true);

  void beacons_add_sticky_atom(int label) {
    return _beacons_add_sticky_atom(label);
  }

  late final _beacons_add_sticky_atomPtr = _lookup<NativeFunction<Void Function(Uint64)>>('beacons_add_sticky_atom');
  late final _beacons_add_sticky_atom = _beacons_add_sticky_atomPtr.asFunction<void Function(int)>(isLeaf: true);

  void beacons_add_sticky_edge(int label) {
    return _beacons_add_sticky_edge(label);
  }

  late final _beacons_add_sticky_edgePtr = _lookup<NativeFunction<Void Function(Uint64)>>('beacons_add_sticky_edge');
  late final _beacons_add_sticky_edge = _beacons_add_sticky_edgePtr.asFunction<void Function(int)>(isLeaf: true);

  void beacons_add_sticky_node(int label) {
    return _beacons_add_sticky_node(label);
  }

  late final _beacons_add_sticky_nodePtr = _lookup<NativeFunction<Void Function(Uint64)>>('beacons_add_sticky_node');
  late final _beacons_add_sticky_node = _beacons_add_sticky_nodePtr.asFunction<void Function(int)>(isLeaf: true);

  COptionAtom beacons_atom(int idh, int idl) {
    final res = _beacons_atom(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_atomPtr = _lookup<NativeFunction<CResultOptionAtom Function(Uint64, Uint64)>>('beacons_atom');
  late final _beacons_atom = _beacons_atomPtr.asFunction<CResultOptionAtom Function(int, int)>(isLeaf: true);

  CArrayTripleIdUint64ArrayUint8 beacons_atom_id_label_value_by_src(int srch, int srcl) {
    final res = _beacons_atom_id_label_value_by_src(srch, srcl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_atom_id_label_value_by_srcPtr =
      _lookup<NativeFunction<CResultArrayTripleIdUint64ArrayUint8 Function(Uint64, Uint64)>>(
          'beacons_atom_id_label_value_by_src');
  late final _beacons_atom_id_label_value_by_src = _beacons_atom_id_label_value_by_srcPtr
      .asFunction<CResultArrayTripleIdUint64ArrayUint8 Function(int, int)>(isLeaf: true);

  CArrayPairIdId beacons_atom_id_src_by_label_value(int label, int len, Pointer<Uint8> ptr) {
    final res = _beacons_atom_id_src_by_label_value(label, len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_atom_id_src_by_label_valuePtr =
      _lookup<NativeFunction<CResultArrayPairIdId Function(Uint64, Uint64, Pointer<Uint8>)>>(
          'beacons_atom_id_src_by_label_value');
  late final _beacons_atom_id_src_by_label_value = _beacons_atom_id_src_by_label_valuePtr
      .asFunction<CResultArrayPairIdId Function(int, int, Pointer<Uint8>)>(isLeaf: true);

  CArrayTripleIdIdArrayUint8 beacons_atom_id_src_value_by_label(int label) {
    final res = _beacons_atom_id_src_value_by_label(label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_atom_id_src_value_by_labelPtr =
      _lookup<NativeFunction<CResultArrayTripleIdIdArrayUint8 Function(Uint64)>>('beacons_atom_id_src_value_by_label');
  late final _beacons_atom_id_src_value_by_label =
      _beacons_atom_id_src_value_by_labelPtr.asFunction<CResultArrayTripleIdIdArrayUint8 Function(int)>(isLeaf: true);

  CArrayPairIdArrayUint8 beacons_atom_id_value_by_src_label(int srch, int srcl, int label) {
    final res = _beacons_atom_id_value_by_src_label(srch, srcl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_atom_id_value_by_src_labelPtr =
      _lookup<NativeFunction<CResultArrayPairIdArrayUint8 Function(Uint64, Uint64, Uint64)>>(
          'beacons_atom_id_value_by_src_label');
  late final _beacons_atom_id_value_by_src_label = _beacons_atom_id_value_by_src_labelPtr
      .asFunction<CResultArrayPairIdArrayUint8 Function(int, int, int)>(isLeaf: true);

  CArrayEventData beacons_barrier() {
    final res = _beacons_barrier();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_barrierPtr = _lookup<NativeFunction<CResultArrayEventData Function()>>('beacons_barrier');
  late final _beacons_barrier = _beacons_barrierPtr.asFunction<CResultArrayEventData Function()>(isLeaf: true);

  CUnit beacons_close() {
    final res = _beacons_close();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_closePtr = _lookup<NativeFunction<CResultUnit Function()>>('beacons_close');
  late final _beacons_close = _beacons_closePtr.asFunction<CResultUnit Function()>(isLeaf: true);

  CUnit beacons_commit() {
    final res = _beacons_commit();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_commitPtr = _lookup<NativeFunction<CResultUnit Function()>>('beacons_commit');
  late final _beacons_commit = _beacons_commitPtr.asFunction<CResultUnit Function()>(isLeaf: true);

  /// Drops the return value of [`barrier`].
  void beacons_drop_array_event_data(CArrayEventData value) {
    return _beacons_drop_array_event_data(value);
  }

  late final _beacons_drop_array_event_dataPtr =
      _lookup<NativeFunction<Void Function(CArrayEventData)>>('beacons_drop_array_event_data');
  late final _beacons_drop_array_event_data =
      _beacons_drop_array_event_dataPtr.asFunction<void Function(CArrayEventData)>(isLeaf: true);

  /// Drops the return value of [`node_id_by_label`].
  void beacons_drop_array_id(CArrayId value) {
    return _beacons_drop_array_id(value);
  }

  late final _beacons_drop_array_idPtr = _lookup<NativeFunction<Void Function(CArrayId)>>('beacons_drop_array_id');
  late final _beacons_drop_array_id = _beacons_drop_array_idPtr.asFunction<void Function(CArrayId)>(isLeaf: true);

  /// Drops the return value of [`atom_id_value_by_src_label`].
  void beacons_drop_array_id_array_u8(CArrayPairIdArrayUint8 value) {
    return _beacons_drop_array_id_array_u8(value);
  }

  late final _beacons_drop_array_id_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayPairIdArrayUint8)>>('beacons_drop_array_id_array_u8');
  late final _beacons_drop_array_id_array_u8 =
      _beacons_drop_array_id_array_u8Ptr.asFunction<void Function(CArrayPairIdArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`atom_id_src_by_label_value`],
  /// [`edge_id_dst_by_src_label`] and [`edge_id_src_by_dst_label`].
  void beacons_drop_array_id_id(CArrayPairIdId value) {
    return _beacons_drop_array_id_id(value);
  }

  late final _beacons_drop_array_id_idPtr =
      _lookup<NativeFunction<Void Function(CArrayPairIdId)>>('beacons_drop_array_id_id');
  late final _beacons_drop_array_id_id =
      _beacons_drop_array_id_idPtr.asFunction<void Function(CArrayPairIdId)>(isLeaf: true);

  /// Drops the return value of [`atom_id_src_value_by_label`].
  void beacons_drop_array_id_id_array_u8(CArrayTripleIdIdArrayUint8 value) {
    return _beacons_drop_array_id_id_array_u8(value);
  }

  late final _beacons_drop_array_id_id_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdArrayUint8)>>('beacons_drop_array_id_id_array_u8');
  late final _beacons_drop_array_id_id_array_u8 =
      _beacons_drop_array_id_id_array_u8Ptr.asFunction<void Function(CArrayTripleIdIdArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`edge_id_src_label_by_dst`].
  void beacons_drop_array_id_id_u64(CArrayTripleIdIdUint64 value) {
    return _beacons_drop_array_id_id_u64(value);
  }

  late final _beacons_drop_array_id_id_u64Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdUint64)>>('beacons_drop_array_id_id_u64');
  late final _beacons_drop_array_id_id_u64 =
      _beacons_drop_array_id_id_u64Ptr.asFunction<void Function(CArrayTripleIdIdUint64)>(isLeaf: true);

  /// Drops the return value of [`atom_id_label_value_by_src`].
  void beacons_drop_array_id_u64_array_u8(CArrayTripleIdUint64ArrayUint8 value) {
    return _beacons_drop_array_id_u64_array_u8(value);
  }

  late final _beacons_drop_array_id_u64_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64ArrayUint8)>>('beacons_drop_array_id_u64_array_u8');
  late final _beacons_drop_array_id_u64_array_u8 =
      _beacons_drop_array_id_u64_array_u8Ptr.asFunction<void Function(CArrayTripleIdUint64ArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`edge_id_label_dst_by_src`].
  void beacons_drop_array_id_u64_id(CArrayTripleIdUint64Id value) {
    return _beacons_drop_array_id_u64_id(value);
  }

  late final _beacons_drop_array_id_u64_idPtr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64Id)>>('beacons_drop_array_id_u64_id');
  late final _beacons_drop_array_id_u64_id =
      _beacons_drop_array_id_u64_idPtr.asFunction<void Function(CArrayTripleIdUint64Id)>(isLeaf: true);

  /// Drops the return value of [`sync_version`] and [`sync_actions`]
  /// and all error results.
  void beacons_drop_array_u8(CArrayUint8 value) {
    return _beacons_drop_array_u8(value);
  }

  late final _beacons_drop_array_u8Ptr = _lookup<NativeFunction<Void Function(CArrayUint8)>>('beacons_drop_array_u8');
  late final _beacons_drop_array_u8 = _beacons_drop_array_u8Ptr.asFunction<void Function(CArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`atom`].
  void beacons_drop_option_atom(COptionAtom value) {
    return _beacons_drop_option_atom(value);
  }

  late final _beacons_drop_option_atomPtr =
      _lookup<NativeFunction<Void Function(COptionAtom)>>('beacons_drop_option_atom');
  late final _beacons_drop_option_atom =
      _beacons_drop_option_atomPtr.asFunction<void Function(COptionAtom)>(isLeaf: true);

  COptionEdge beacons_edge(int idh, int idl) {
    final res = _beacons_edge(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_edgePtr = _lookup<NativeFunction<CResultOptionEdge Function(Uint64, Uint64)>>('beacons_edge');
  late final _beacons_edge = _beacons_edgePtr.asFunction<CResultOptionEdge Function(int, int)>(isLeaf: true);

  CArrayPairIdId beacons_edge_id_dst_by_src_label(int srch, int srcl, int label) {
    final res = _beacons_edge_id_dst_by_src_label(srch, srcl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_edge_id_dst_by_src_labelPtr =
      _lookup<NativeFunction<CResultArrayPairIdId Function(Uint64, Uint64, Uint64)>>(
          'beacons_edge_id_dst_by_src_label');
  late final _beacons_edge_id_dst_by_src_label =
      _beacons_edge_id_dst_by_src_labelPtr.asFunction<CResultArrayPairIdId Function(int, int, int)>(isLeaf: true);

  CArrayTripleIdUint64Id beacons_edge_id_label_dst_by_src(int srch, int srcl) {
    final res = _beacons_edge_id_label_dst_by_src(srch, srcl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_edge_id_label_dst_by_srcPtr =
      _lookup<NativeFunction<CResultArrayTripleIdUint64Id Function(Uint64, Uint64)>>(
          'beacons_edge_id_label_dst_by_src');
  late final _beacons_edge_id_label_dst_by_src =
      _beacons_edge_id_label_dst_by_srcPtr.asFunction<CResultArrayTripleIdUint64Id Function(int, int)>(isLeaf: true);

  CArrayPairIdId beacons_edge_id_src_by_dst_label(int dsth, int dstl, int label) {
    final res = _beacons_edge_id_src_by_dst_label(dsth, dstl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_edge_id_src_by_dst_labelPtr =
      _lookup<NativeFunction<CResultArrayPairIdId Function(Uint64, Uint64, Uint64)>>(
          'beacons_edge_id_src_by_dst_label');
  late final _beacons_edge_id_src_by_dst_label =
      _beacons_edge_id_src_by_dst_labelPtr.asFunction<CResultArrayPairIdId Function(int, int, int)>(isLeaf: true);

  CArrayTripleIdIdUint64 beacons_edge_id_src_label_by_dst(int dsth, int dstl) {
    final res = _beacons_edge_id_src_label_by_dst(dsth, dstl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_edge_id_src_label_by_dstPtr =
      _lookup<NativeFunction<CResultArrayTripleIdIdUint64 Function(Uint64, Uint64)>>(
          'beacons_edge_id_src_label_by_dst');
  late final _beacons_edge_id_src_label_by_dst =
      _beacons_edge_id_src_label_by_dstPtr.asFunction<CResultArrayTripleIdIdUint64 Function(int, int)>(isLeaf: true);

  COptionNode beacons_node(int idh, int idl) {
    final res = _beacons_node(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_nodePtr = _lookup<NativeFunction<CResultOptionNode Function(Uint64, Uint64)>>('beacons_node');
  late final _beacons_node = _beacons_nodePtr.asFunction<CResultOptionNode Function(int, int)>(isLeaf: true);

  CArrayId beacons_node_id_by_label(int label) {
    final res = _beacons_node_id_by_label(label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_node_id_by_labelPtr =
      _lookup<NativeFunction<CResultArrayId Function(Uint64)>>('beacons_node_id_by_label');
  late final _beacons_node_id_by_label =
      _beacons_node_id_by_labelPtr.asFunction<CResultArrayId Function(int)>(isLeaf: true);

  CUnit beacons_open(int len, Pointer<Uint8> ptr) {
    final res = _beacons_open(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_openPtr = _lookup<NativeFunction<CResultUnit Function(Uint64, Pointer<Uint8>)>>('beacons_open');
  late final _beacons_open = _beacons_openPtr.asFunction<CResultUnit Function(int, Pointer<Uint8>)>(isLeaf: true);

  CId beacons_random_id() {
    return _beacons_random_id();
  }

  late final _beacons_random_idPtr = _lookup<NativeFunction<CId Function()>>('beacons_random_id');
  late final _beacons_random_id = _beacons_random_idPtr.asFunction<CId Function()>(isLeaf: true);

  CUnit beacons_set_atom_none(int idh, int idl) {
    final res = _beacons_set_atom_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_set_atom_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>('beacons_set_atom_none');
  late final _beacons_set_atom_none =
      _beacons_set_atom_nonePtr.asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit beacons_set_atom_some(int idh, int idl, int srch, int srcl, int label, int len, Pointer<Uint8> ptr) {
    final res = _beacons_set_atom_some(idh, idl, srch, srcl, label, len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_set_atom_somePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64, Pointer<Uint8>)>>(
          'beacons_set_atom_some');
  late final _beacons_set_atom_some = _beacons_set_atom_somePtr
      .asFunction<CResultUnit Function(int, int, int, int, int, int, Pointer<Uint8>)>(isLeaf: true);

  CUnit beacons_set_edge_none(int idh, int idl) {
    final res = _beacons_set_edge_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_set_edge_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>('beacons_set_edge_none');
  late final _beacons_set_edge_none =
      _beacons_set_edge_nonePtr.asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit beacons_set_edge_some(int idh, int idl, int srch, int srcl, int label, int dsth, int dstl) {
    final res = _beacons_set_edge_some(idh, idl, srch, srcl, label, dsth, dstl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_set_edge_somePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64, Uint64)>>(
          'beacons_set_edge_some');
  late final _beacons_set_edge_some =
      _beacons_set_edge_somePtr.asFunction<CResultUnit Function(int, int, int, int, int, int, int)>(isLeaf: true);

  CUnit beacons_set_node_none(int idh, int idl) {
    final res = _beacons_set_node_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_set_node_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>('beacons_set_node_none');
  late final _beacons_set_node_none =
      _beacons_set_node_nonePtr.asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit beacons_set_node_some(int idh, int idl, int label) {
    final res = _beacons_set_node_some(idh, idl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_set_node_somePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64, Uint64)>>('beacons_set_node_some');
  late final _beacons_set_node_some =
      _beacons_set_node_somePtr.asFunction<CResultUnit Function(int, int, int)>(isLeaf: true);

  CArrayUint8 beacons_sync_actions(int len, Pointer<Uint8> ptr) {
    final res = _beacons_sync_actions(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_sync_actionsPtr =
      _lookup<NativeFunction<CResultArrayUint8 Function(Uint64, Pointer<Uint8>)>>('beacons_sync_actions');
  late final _beacons_sync_actions =
      _beacons_sync_actionsPtr.asFunction<CResultArrayUint8 Function(int, Pointer<Uint8>)>(isLeaf: true);

  CUnit beacons_sync_join(int len, Pointer<Uint8> ptr) {
    final res = _beacons_sync_join(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_sync_joinPtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Pointer<Uint8>)>>('beacons_sync_join');
  late final _beacons_sync_join =
      _beacons_sync_joinPtr.asFunction<CResultUnit Function(int, Pointer<Uint8>)>(isLeaf: true);

  CArrayUint8 beacons_sync_version() {
    final res = _beacons_sync_version();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_sync_versionPtr = _lookup<NativeFunction<CResultArrayUint8 Function()>>('beacons_sync_version');
  late final _beacons_sync_version = _beacons_sync_versionPtr.asFunction<CResultArrayUint8 Function()>(isLeaf: true);

  CArrayEventData beacons_test_array_event_data() {
    return _beacons_test_array_event_data();
  }

  late final _beacons_test_array_event_dataPtr =
      _lookup<NativeFunction<CArrayEventData Function()>>('beacons_test_array_event_data');
  late final _beacons_test_array_event_data =
      _beacons_test_array_event_dataPtr.asFunction<CArrayEventData Function()>(isLeaf: true);

  CArrayEventData beacons_test_array_event_data_big(int entries, int size) {
    return _beacons_test_array_event_data_big(entries, size);
  }

  late final _beacons_test_array_event_data_bigPtr =
      _lookup<NativeFunction<CArrayEventData Function(Uint64, Uint64)>>('beacons_test_array_event_data_big');
  late final _beacons_test_array_event_data_big =
      _beacons_test_array_event_data_bigPtr.asFunction<CArrayEventData Function(int, int)>(isLeaf: true);

  CArrayPairIdId beacons_test_array_id_id() {
    return _beacons_test_array_id_id();
  }

  late final _beacons_test_array_id_idPtr =
      _lookup<NativeFunction<CArrayPairIdId Function()>>('beacons_test_array_id_id');
  late final _beacons_test_array_id_id =
      _beacons_test_array_id_idPtr.asFunction<CArrayPairIdId Function()>(isLeaf: true);

  CArrayTripleIdUint64Id beacons_test_array_id_u64_id() {
    return _beacons_test_array_id_u64_id();
  }

  late final _beacons_test_array_id_u64_idPtr =
      _lookup<NativeFunction<CArrayTripleIdUint64Id Function()>>('beacons_test_array_id_u64_id');
  late final _beacons_test_array_id_u64_id =
      _beacons_test_array_id_u64_idPtr.asFunction<CArrayTripleIdUint64Id Function()>(isLeaf: true);

  CArrayUint8 beacons_test_array_u8() {
    return _beacons_test_array_u8();
  }

  late final _beacons_test_array_u8Ptr = _lookup<NativeFunction<CArrayUint8 Function()>>('beacons_test_array_u8');
  late final _beacons_test_array_u8 = _beacons_test_array_u8Ptr.asFunction<CArrayUint8 Function()>(isLeaf: true);

  CArrayUint8 beacons_test_array_u8_big(int size) {
    return _beacons_test_array_u8_big(size);
  }

  late final _beacons_test_array_u8_bigPtr =
      _lookup<NativeFunction<CArrayUint8 Function(Uint64)>>('beacons_test_array_u8_big');
  late final _beacons_test_array_u8_big =
      _beacons_test_array_u8_bigPtr.asFunction<CArrayUint8 Function(int)>(isLeaf: true);

  CId beacons_test_id() {
    return _beacons_test_id();
  }

  late final _beacons_test_idPtr = _lookup<NativeFunction<CId Function()>>('beacons_test_id');
  late final _beacons_test_id = _beacons_test_idPtr.asFunction<CId Function()>(isLeaf: true);

  CId beacons_test_id_unsigned() {
    return _beacons_test_id_unsigned();
  }

  late final _beacons_test_id_unsignedPtr = _lookup<NativeFunction<CId Function()>>('beacons_test_id_unsigned');
  late final _beacons_test_id_unsigned = _beacons_test_id_unsignedPtr.asFunction<CId Function()>(isLeaf: true);

  COptionAtom beacons_test_option_atom_none() {
    return _beacons_test_option_atom_none();
  }

  late final _beacons_test_option_atom_nonePtr =
      _lookup<NativeFunction<COptionAtom Function()>>('beacons_test_option_atom_none');
  late final _beacons_test_option_atom_none =
      _beacons_test_option_atom_nonePtr.asFunction<COptionAtom Function()>(isLeaf: true);

  COptionAtom beacons_test_option_atom_some() {
    return _beacons_test_option_atom_some();
  }

  late final _beacons_test_option_atom_somePtr =
      _lookup<NativeFunction<COptionAtom Function()>>('beacons_test_option_atom_some');
  late final _beacons_test_option_atom_some =
      _beacons_test_option_atom_somePtr.asFunction<COptionAtom Function()>(isLeaf: true);

  COptionEdge beacons_test_option_edge_none() {
    return _beacons_test_option_edge_none();
  }

  late final _beacons_test_option_edge_nonePtr =
      _lookup<NativeFunction<COptionEdge Function()>>('beacons_test_option_edge_none');
  late final _beacons_test_option_edge_none =
      _beacons_test_option_edge_nonePtr.asFunction<COptionEdge Function()>(isLeaf: true);

  COptionEdge beacons_test_option_edge_some() {
    return _beacons_test_option_edge_some();
  }

  late final _beacons_test_option_edge_somePtr =
      _lookup<NativeFunction<COptionEdge Function()>>('beacons_test_option_edge_some');
  late final _beacons_test_option_edge_some =
      _beacons_test_option_edge_somePtr.asFunction<COptionEdge Function()>(isLeaf: true);

  CUnit beacons_test_result_unit_err() {
    final res = _beacons_test_result_unit_err();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_test_result_unit_errPtr =
      _lookup<NativeFunction<CResultUnit Function()>>('beacons_test_result_unit_err');
  late final _beacons_test_result_unit_err =
      _beacons_test_result_unit_errPtr.asFunction<CResultUnit Function()>(isLeaf: true);

  CUnit beacons_test_result_unit_ok() {
    final res = _beacons_test_result_unit_ok();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _beacons_test_result_unit_okPtr =
      _lookup<NativeFunction<CResultUnit Function()>>('beacons_test_result_unit_ok');
  late final _beacons_test_result_unit_ok =
      _beacons_test_result_unit_okPtr.asFunction<CResultUnit Function()>(isLeaf: true);
}
