// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:ffi';
import 'dart:convert';

import 'native_structs.dart';

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
  NativeBindings(DynamicLibrary dynamicLibrary)
      : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  NativeBindings.fromLookup(
      Pointer<T> Function<T extends NativeType>(String symbolName) lookup)
      : _lookup = lookup;

  /// Handles native error.
  void _err(CArrayUint8 error) {
    final message = utf8.decode(error.ptr.asTypedList(error.len));
    qinhuai_drop_array_u8(error);
    throw NativeError(message);
  }

  void qinhuai_add_acyclic_edge(int label) {
    return _qinhuai_add_acyclic_edge(label);
  }

  late final _qinhuai_add_acyclic_edgePtr =
      _lookup<NativeFunction<Void Function(Uint64)>>(
          'qinhuai_add_acyclic_edge');
  late final _qinhuai_add_acyclic_edge =
      _qinhuai_add_acyclic_edgePtr.asFunction<void Function(int)>(isLeaf: true);

  void qinhuai_add_sticky_atom(int label) {
    return _qinhuai_add_sticky_atom(label);
  }

  late final _qinhuai_add_sticky_atomPtr =
      _lookup<NativeFunction<Void Function(Uint64)>>('qinhuai_add_sticky_atom');
  late final _qinhuai_add_sticky_atom =
      _qinhuai_add_sticky_atomPtr.asFunction<void Function(int)>(isLeaf: true);

  void qinhuai_add_sticky_edge(int label) {
    return _qinhuai_add_sticky_edge(label);
  }

  late final _qinhuai_add_sticky_edgePtr =
      _lookup<NativeFunction<Void Function(Uint64)>>('qinhuai_add_sticky_edge');
  late final _qinhuai_add_sticky_edge =
      _qinhuai_add_sticky_edgePtr.asFunction<void Function(int)>(isLeaf: true);

  void qinhuai_add_sticky_node(int label) {
    return _qinhuai_add_sticky_node(label);
  }

  late final _qinhuai_add_sticky_nodePtr =
      _lookup<NativeFunction<Void Function(Uint64)>>('qinhuai_add_sticky_node');
  late final _qinhuai_add_sticky_node =
      _qinhuai_add_sticky_nodePtr.asFunction<void Function(int)>(isLeaf: true);

  COptionAtom qinhuai_atom(int idh, int idl) {
    final res = _qinhuai_atom(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_atomPtr =
      _lookup<NativeFunction<CResultOptionAtom Function(Uint64, Uint64)>>(
          'qinhuai_atom');
  late final _qinhuai_atom = _qinhuai_atomPtr
      .asFunction<CResultOptionAtom Function(int, int)>(isLeaf: true);

  CArrayTripleIdUint64ArrayUint8 qinhuai_atom_id_label_value_by_src(
      int srch, int srcl) {
    final res = _qinhuai_atom_id_label_value_by_src(srch, srcl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_atom_id_label_value_by_srcPtr = _lookup<
      NativeFunction<
          CResultArrayTripleIdUint64ArrayUint8 Function(
              Uint64, Uint64)>>('qinhuai_atom_id_label_value_by_src');
  late final _qinhuai_atom_id_label_value_by_src =
      _qinhuai_atom_id_label_value_by_srcPtr
          .asFunction<CResultArrayTripleIdUint64ArrayUint8 Function(int, int)>(
              isLeaf: true);

  CArrayPairIdId qinhuai_atom_id_src_by_label_value(
      int label, int len, Pointer<Uint8> ptr) {
    final res = _qinhuai_atom_id_src_by_label_value(label, len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_atom_id_src_by_label_valuePtr = _lookup<
      NativeFunction<
          CResultArrayPairIdId Function(Uint64, Uint64,
              Pointer<Uint8>)>>('qinhuai_atom_id_src_by_label_value');
  late final _qinhuai_atom_id_src_by_label_value =
      _qinhuai_atom_id_src_by_label_valuePtr
          .asFunction<CResultArrayPairIdId Function(int, int, Pointer<Uint8>)>(
              isLeaf: true);

  CArrayTripleIdIdArrayUint8 qinhuai_atom_id_src_value_by_label(int label) {
    final res = _qinhuai_atom_id_src_value_by_label(label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_atom_id_src_value_by_labelPtr = _lookup<
          NativeFunction<CResultArrayTripleIdIdArrayUint8 Function(Uint64)>>(
      'qinhuai_atom_id_src_value_by_label');
  late final _qinhuai_atom_id_src_value_by_label =
      _qinhuai_atom_id_src_value_by_labelPtr
          .asFunction<CResultArrayTripleIdIdArrayUint8 Function(int)>(
              isLeaf: true);

  CArrayPairIdArrayUint8 qinhuai_atom_id_value_by_src_label(
      int srch, int srcl, int label) {
    final res = _qinhuai_atom_id_value_by_src_label(srch, srcl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_atom_id_value_by_src_labelPtr = _lookup<
      NativeFunction<
          CResultArrayPairIdArrayUint8 Function(
              Uint64, Uint64, Uint64)>>('qinhuai_atom_id_value_by_src_label');
  late final _qinhuai_atom_id_value_by_src_label =
      _qinhuai_atom_id_value_by_src_labelPtr
          .asFunction<CResultArrayPairIdArrayUint8 Function(int, int, int)>(
              isLeaf: true);

  CArrayEventData qinhuai_barrier() {
    final res = _qinhuai_barrier();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_barrierPtr =
      _lookup<NativeFunction<CResultArrayEventData Function()>>(
          'qinhuai_barrier');
  late final _qinhuai_barrier = _qinhuai_barrierPtr
      .asFunction<CResultArrayEventData Function()>(isLeaf: true);

  CUnit qinhuai_close() {
    final res = _qinhuai_close();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_closePtr =
      _lookup<NativeFunction<CResultUnit Function()>>('qinhuai_close');
  late final _qinhuai_close =
      _qinhuai_closePtr.asFunction<CResultUnit Function()>(isLeaf: true);

  CUnit qinhuai_commit() {
    final res = _qinhuai_commit();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_commitPtr =
      _lookup<NativeFunction<CResultUnit Function()>>('qinhuai_commit');
  late final _qinhuai_commit =
      _qinhuai_commitPtr.asFunction<CResultUnit Function()>(isLeaf: true);

  /// Drops the return value of [`barrier`].
  void qinhuai_drop_array_event_data(CArrayEventData value) {
    return _qinhuai_drop_array_event_data(value);
  }

  late final _qinhuai_drop_array_event_dataPtr =
      _lookup<NativeFunction<Void Function(CArrayEventData)>>(
          'qinhuai_drop_array_event_data');
  late final _qinhuai_drop_array_event_data = _qinhuai_drop_array_event_dataPtr
      .asFunction<void Function(CArrayEventData)>(isLeaf: true);

  /// Drops the return value of [`node_id_by_label`].
  void qinhuai_drop_array_id(CArrayId value) {
    return _qinhuai_drop_array_id(value);
  }

  late final _qinhuai_drop_array_idPtr =
      _lookup<NativeFunction<Void Function(CArrayId)>>('qinhuai_drop_array_id');
  late final _qinhuai_drop_array_id = _qinhuai_drop_array_idPtr
      .asFunction<void Function(CArrayId)>(isLeaf: true);

  /// Drops the return value of [`atom_id_value_by_src_label`].
  void qinhuai_drop_array_id_array_u8(CArrayPairIdArrayUint8 value) {
    return _qinhuai_drop_array_id_array_u8(value);
  }

  late final _qinhuai_drop_array_id_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayPairIdArrayUint8)>>(
          'qinhuai_drop_array_id_array_u8');
  late final _qinhuai_drop_array_id_array_u8 =
      _qinhuai_drop_array_id_array_u8Ptr
          .asFunction<void Function(CArrayPairIdArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`atom_id_src_by_label_value`],
  /// [`edge_id_dst_by_src_label`] and [`edge_id_src_by_dst_label`].
  void qinhuai_drop_array_id_id(CArrayPairIdId value) {
    return _qinhuai_drop_array_id_id(value);
  }

  late final _qinhuai_drop_array_id_idPtr =
      _lookup<NativeFunction<Void Function(CArrayPairIdId)>>(
          'qinhuai_drop_array_id_id');
  late final _qinhuai_drop_array_id_id = _qinhuai_drop_array_id_idPtr
      .asFunction<void Function(CArrayPairIdId)>(isLeaf: true);

  /// Drops the return value of [`atom_id_src_value_by_label`].
  void qinhuai_drop_array_id_id_array_u8(CArrayTripleIdIdArrayUint8 value) {
    return _qinhuai_drop_array_id_id_array_u8(value);
  }

  late final _qinhuai_drop_array_id_id_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdArrayUint8)>>(
          'qinhuai_drop_array_id_id_array_u8');
  late final _qinhuai_drop_array_id_id_array_u8 =
      _qinhuai_drop_array_id_id_array_u8Ptr
          .asFunction<void Function(CArrayTripleIdIdArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`edge_id_src_label_by_dst`].
  void qinhuai_drop_array_id_id_u64(CArrayTripleIdIdUint64 value) {
    return _qinhuai_drop_array_id_id_u64(value);
  }

  late final _qinhuai_drop_array_id_id_u64Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdUint64)>>(
          'qinhuai_drop_array_id_id_u64');
  late final _qinhuai_drop_array_id_id_u64 = _qinhuai_drop_array_id_id_u64Ptr
      .asFunction<void Function(CArrayTripleIdIdUint64)>(isLeaf: true);

  /// Drops the return value of [`atom_id_label_value_by_src`].
  void qinhuai_drop_array_id_u64_array_u8(
      CArrayTripleIdUint64ArrayUint8 value) {
    return _qinhuai_drop_array_id_u64_array_u8(value);
  }

  late final _qinhuai_drop_array_id_u64_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64ArrayUint8)>>(
          'qinhuai_drop_array_id_u64_array_u8');
  late final _qinhuai_drop_array_id_u64_array_u8 =
      _qinhuai_drop_array_id_u64_array_u8Ptr
          .asFunction<void Function(CArrayTripleIdUint64ArrayUint8)>(
              isLeaf: true);

  /// Drops the return value of [`edge_id_label_dst_by_src`].
  void qinhuai_drop_array_id_u64_id(CArrayTripleIdUint64Id value) {
    return _qinhuai_drop_array_id_u64_id(value);
  }

  late final _qinhuai_drop_array_id_u64_idPtr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64Id)>>(
          'qinhuai_drop_array_id_u64_id');
  late final _qinhuai_drop_array_id_u64_id = _qinhuai_drop_array_id_u64_idPtr
      .asFunction<void Function(CArrayTripleIdUint64Id)>(isLeaf: true);

  /// Drops the return value of [`sync_version`] and [`sync_actions`]
  /// and all error results.
  void qinhuai_drop_array_u8(CArrayUint8 value) {
    return _qinhuai_drop_array_u8(value);
  }

  late final _qinhuai_drop_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayUint8)>>(
          'qinhuai_drop_array_u8');
  late final _qinhuai_drop_array_u8 = _qinhuai_drop_array_u8Ptr
      .asFunction<void Function(CArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`atom`].
  void qinhuai_drop_option_atom(COptionAtom value) {
    return _qinhuai_drop_option_atom(value);
  }

  late final _qinhuai_drop_option_atomPtr =
      _lookup<NativeFunction<Void Function(COptionAtom)>>(
          'qinhuai_drop_option_atom');
  late final _qinhuai_drop_option_atom = _qinhuai_drop_option_atomPtr
      .asFunction<void Function(COptionAtom)>(isLeaf: true);

  COptionEdge qinhuai_edge(int idh, int idl) {
    final res = _qinhuai_edge(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_edgePtr =
      _lookup<NativeFunction<CResultOptionEdge Function(Uint64, Uint64)>>(
          'qinhuai_edge');
  late final _qinhuai_edge = _qinhuai_edgePtr
      .asFunction<CResultOptionEdge Function(int, int)>(isLeaf: true);

  CArrayPairIdId qinhuai_edge_id_dst_by_src_label(
      int srch, int srcl, int label) {
    final res = _qinhuai_edge_id_dst_by_src_label(srch, srcl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_edge_id_dst_by_src_labelPtr = _lookup<
      NativeFunction<
          CResultArrayPairIdId Function(
              Uint64, Uint64, Uint64)>>('qinhuai_edge_id_dst_by_src_label');
  late final _qinhuai_edge_id_dst_by_src_label =
      _qinhuai_edge_id_dst_by_src_labelPtr
          .asFunction<CResultArrayPairIdId Function(int, int, int)>(
              isLeaf: true);

  CArrayTripleIdUint64Id qinhuai_edge_id_label_dst_by_src(int srch, int srcl) {
    final res = _qinhuai_edge_id_label_dst_by_src(srch, srcl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_edge_id_label_dst_by_srcPtr = _lookup<
      NativeFunction<
          CResultArrayTripleIdUint64Id Function(
              Uint64, Uint64)>>('qinhuai_edge_id_label_dst_by_src');
  late final _qinhuai_edge_id_label_dst_by_src =
      _qinhuai_edge_id_label_dst_by_srcPtr
          .asFunction<CResultArrayTripleIdUint64Id Function(int, int)>(
              isLeaf: true);

  CArrayPairIdId qinhuai_edge_id_src_by_dst_label(
      int dsth, int dstl, int label) {
    final res = _qinhuai_edge_id_src_by_dst_label(dsth, dstl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_edge_id_src_by_dst_labelPtr = _lookup<
      NativeFunction<
          CResultArrayPairIdId Function(
              Uint64, Uint64, Uint64)>>('qinhuai_edge_id_src_by_dst_label');
  late final _qinhuai_edge_id_src_by_dst_label =
      _qinhuai_edge_id_src_by_dst_labelPtr
          .asFunction<CResultArrayPairIdId Function(int, int, int)>(
              isLeaf: true);

  CArrayTripleIdIdUint64 qinhuai_edge_id_src_label_by_dst(int dsth, int dstl) {
    final res = _qinhuai_edge_id_src_label_by_dst(dsth, dstl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_edge_id_src_label_by_dstPtr = _lookup<
      NativeFunction<
          CResultArrayTripleIdIdUint64 Function(
              Uint64, Uint64)>>('qinhuai_edge_id_src_label_by_dst');
  late final _qinhuai_edge_id_src_label_by_dst =
      _qinhuai_edge_id_src_label_by_dstPtr
          .asFunction<CResultArrayTripleIdIdUint64 Function(int, int)>(
              isLeaf: true);

  COptionNode qinhuai_node(int idh, int idl) {
    final res = _qinhuai_node(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_nodePtr =
      _lookup<NativeFunction<CResultOptionNode Function(Uint64, Uint64)>>(
          'qinhuai_node');
  late final _qinhuai_node = _qinhuai_nodePtr
      .asFunction<CResultOptionNode Function(int, int)>(isLeaf: true);

  CArrayId qinhuai_node_id_by_label(int label) {
    final res = _qinhuai_node_id_by_label(label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_node_id_by_labelPtr =
      _lookup<NativeFunction<CResultArrayId Function(Uint64)>>(
          'qinhuai_node_id_by_label');
  late final _qinhuai_node_id_by_label = _qinhuai_node_id_by_labelPtr
      .asFunction<CResultArrayId Function(int)>(isLeaf: true);

  CUnit qinhuai_open(int len, Pointer<Uint8> ptr) {
    final res = _qinhuai_open(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_openPtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Pointer<Uint8>)>>(
          'qinhuai_open');
  late final _qinhuai_open = _qinhuai_openPtr
      .asFunction<CResultUnit Function(int, Pointer<Uint8>)>(isLeaf: true);

  CId qinhuai_random_id() {
    return _qinhuai_random_id();
  }

  late final _qinhuai_random_idPtr =
      _lookup<NativeFunction<CId Function()>>('qinhuai_random_id');
  late final _qinhuai_random_id =
      _qinhuai_random_idPtr.asFunction<CId Function()>(isLeaf: true);

  CUnit qinhuai_set_atom_none(int idh, int idl) {
    final res = _qinhuai_set_atom_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_set_atom_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>(
          'qinhuai_set_atom_none');
  late final _qinhuai_set_atom_none = _qinhuai_set_atom_nonePtr
      .asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit qinhuai_set_atom_some(int idh, int idl, int srch, int srcl, int label,
      int len, Pointer<Uint8> ptr) {
    final res = _qinhuai_set_atom_some(idh, idl, srch, srcl, label, len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_set_atom_somePtr = _lookup<
      NativeFunction<
          CResultUnit Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64,
              Pointer<Uint8>)>>('qinhuai_set_atom_some');
  late final _qinhuai_set_atom_some = _qinhuai_set_atom_somePtr.asFunction<
      CResultUnit Function(
          int, int, int, int, int, int, Pointer<Uint8>)>(isLeaf: true);

  CUnit qinhuai_set_edge_none(int idh, int idl) {
    final res = _qinhuai_set_edge_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_set_edge_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>(
          'qinhuai_set_edge_none');
  late final _qinhuai_set_edge_none = _qinhuai_set_edge_nonePtr
      .asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit qinhuai_set_edge_some(
      int idh, int idl, int srch, int srcl, int label, int dsth, int dstl) {
    final res = _qinhuai_set_edge_some(idh, idl, srch, srcl, label, dsth, dstl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_set_edge_somePtr = _lookup<
      NativeFunction<
          CResultUnit Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64,
              Uint64)>>('qinhuai_set_edge_some');
  late final _qinhuai_set_edge_some = _qinhuai_set_edge_somePtr
      .asFunction<CResultUnit Function(int, int, int, int, int, int, int)>(
          isLeaf: true);

  CUnit qinhuai_set_node_none(int idh, int idl) {
    final res = _qinhuai_set_node_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_set_node_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>(
          'qinhuai_set_node_none');
  late final _qinhuai_set_node_none = _qinhuai_set_node_nonePtr
      .asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit qinhuai_set_node_some(int idh, int idl, int label) {
    final res = _qinhuai_set_node_some(idh, idl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_set_node_somePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64, Uint64)>>(
          'qinhuai_set_node_some');
  late final _qinhuai_set_node_some = _qinhuai_set_node_somePtr
      .asFunction<CResultUnit Function(int, int, int)>(isLeaf: true);

  CArrayUint8 qinhuai_sync_actions(int len, Pointer<Uint8> ptr) {
    final res = _qinhuai_sync_actions(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_sync_actionsPtr = _lookup<
          NativeFunction<CResultArrayUint8 Function(Uint64, Pointer<Uint8>)>>(
      'qinhuai_sync_actions');
  late final _qinhuai_sync_actions = _qinhuai_sync_actionsPtr
      .asFunction<CResultArrayUint8 Function(int, Pointer<Uint8>)>(
          isLeaf: true);

  CUnit qinhuai_sync_join(int len, Pointer<Uint8> ptr) {
    final res = _qinhuai_sync_join(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_sync_joinPtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Pointer<Uint8>)>>(
          'qinhuai_sync_join');
  late final _qinhuai_sync_join = _qinhuai_sync_joinPtr
      .asFunction<CResultUnit Function(int, Pointer<Uint8>)>(isLeaf: true);

  CArrayUint8 qinhuai_sync_version() {
    final res = _qinhuai_sync_version();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_sync_versionPtr =
      _lookup<NativeFunction<CResultArrayUint8 Function()>>(
          'qinhuai_sync_version');
  late final _qinhuai_sync_version = _qinhuai_sync_versionPtr
      .asFunction<CResultArrayUint8 Function()>(isLeaf: true);

  CArrayEventData qinhuai_test_array_event_data() {
    return _qinhuai_test_array_event_data();
  }

  late final _qinhuai_test_array_event_dataPtr =
      _lookup<NativeFunction<CArrayEventData Function()>>(
          'qinhuai_test_array_event_data');
  late final _qinhuai_test_array_event_data = _qinhuai_test_array_event_dataPtr
      .asFunction<CArrayEventData Function()>(isLeaf: true);

  CArrayEventData qinhuai_test_array_event_data_big(int entries, int size) {
    return _qinhuai_test_array_event_data_big(entries, size);
  }

  late final _qinhuai_test_array_event_data_bigPtr =
      _lookup<NativeFunction<CArrayEventData Function(Uint64, Uint64)>>(
          'qinhuai_test_array_event_data_big');
  late final _qinhuai_test_array_event_data_big =
      _qinhuai_test_array_event_data_bigPtr
          .asFunction<CArrayEventData Function(int, int)>(isLeaf: true);

  CArrayPairIdId qinhuai_test_array_id_id() {
    return _qinhuai_test_array_id_id();
  }

  late final _qinhuai_test_array_id_idPtr =
      _lookup<NativeFunction<CArrayPairIdId Function()>>(
          'qinhuai_test_array_id_id');
  late final _qinhuai_test_array_id_id = _qinhuai_test_array_id_idPtr
      .asFunction<CArrayPairIdId Function()>(isLeaf: true);

  CArrayTripleIdUint64Id qinhuai_test_array_id_u64_id() {
    return _qinhuai_test_array_id_u64_id();
  }

  late final _qinhuai_test_array_id_u64_idPtr =
      _lookup<NativeFunction<CArrayTripleIdUint64Id Function()>>(
          'qinhuai_test_array_id_u64_id');
  late final _qinhuai_test_array_id_u64_id = _qinhuai_test_array_id_u64_idPtr
      .asFunction<CArrayTripleIdUint64Id Function()>(isLeaf: true);

  CArrayUint8 qinhuai_test_array_u8() {
    return _qinhuai_test_array_u8();
  }

  late final _qinhuai_test_array_u8Ptr =
      _lookup<NativeFunction<CArrayUint8 Function()>>('qinhuai_test_array_u8');
  late final _qinhuai_test_array_u8 = _qinhuai_test_array_u8Ptr
      .asFunction<CArrayUint8 Function()>(isLeaf: true);

  CArrayUint8 qinhuai_test_array_u8_big(int size) {
    return _qinhuai_test_array_u8_big(size);
  }

  late final _qinhuai_test_array_u8_bigPtr =
      _lookup<NativeFunction<CArrayUint8 Function(Uint64)>>(
          'qinhuai_test_array_u8_big');
  late final _qinhuai_test_array_u8_big = _qinhuai_test_array_u8_bigPtr
      .asFunction<CArrayUint8 Function(int)>(isLeaf: true);

  CId qinhuai_test_id() {
    return _qinhuai_test_id();
  }

  late final _qinhuai_test_idPtr =
      _lookup<NativeFunction<CId Function()>>('qinhuai_test_id');
  late final _qinhuai_test_id =
      _qinhuai_test_idPtr.asFunction<CId Function()>(isLeaf: true);

  CId qinhuai_test_id_unsigned() {
    return _qinhuai_test_id_unsigned();
  }

  late final _qinhuai_test_id_unsignedPtr =
      _lookup<NativeFunction<CId Function()>>('qinhuai_test_id_unsigned');
  late final _qinhuai_test_id_unsigned =
      _qinhuai_test_id_unsignedPtr.asFunction<CId Function()>(isLeaf: true);

  COptionAtom qinhuai_test_option_atom_none() {
    return _qinhuai_test_option_atom_none();
  }

  late final _qinhuai_test_option_atom_nonePtr =
      _lookup<NativeFunction<COptionAtom Function()>>(
          'qinhuai_test_option_atom_none');
  late final _qinhuai_test_option_atom_none = _qinhuai_test_option_atom_nonePtr
      .asFunction<COptionAtom Function()>(isLeaf: true);

  COptionAtom qinhuai_test_option_atom_some() {
    return _qinhuai_test_option_atom_some();
  }

  late final _qinhuai_test_option_atom_somePtr =
      _lookup<NativeFunction<COptionAtom Function()>>(
          'qinhuai_test_option_atom_some');
  late final _qinhuai_test_option_atom_some = _qinhuai_test_option_atom_somePtr
      .asFunction<COptionAtom Function()>(isLeaf: true);

  COptionEdge qinhuai_test_option_edge_none() {
    return _qinhuai_test_option_edge_none();
  }

  late final _qinhuai_test_option_edge_nonePtr =
      _lookup<NativeFunction<COptionEdge Function()>>(
          'qinhuai_test_option_edge_none');
  late final _qinhuai_test_option_edge_none = _qinhuai_test_option_edge_nonePtr
      .asFunction<COptionEdge Function()>(isLeaf: true);

  COptionEdge qinhuai_test_option_edge_some() {
    return _qinhuai_test_option_edge_some();
  }

  late final _qinhuai_test_option_edge_somePtr =
      _lookup<NativeFunction<COptionEdge Function()>>(
          'qinhuai_test_option_edge_some');
  late final _qinhuai_test_option_edge_some = _qinhuai_test_option_edge_somePtr
      .asFunction<COptionEdge Function()>(isLeaf: true);

  CUnit qinhuai_test_result_unit_err() {
    final res = _qinhuai_test_result_unit_err();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_test_result_unit_errPtr =
      _lookup<NativeFunction<CResultUnit Function()>>(
          'qinhuai_test_result_unit_err');
  late final _qinhuai_test_result_unit_err = _qinhuai_test_result_unit_errPtr
      .asFunction<CResultUnit Function()>(isLeaf: true);

  CUnit qinhuai_test_result_unit_ok() {
    final res = _qinhuai_test_result_unit_ok();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _qinhuai_test_result_unit_okPtr =
      _lookup<NativeFunction<CResultUnit Function()>>(
          'qinhuai_test_result_unit_ok');
  late final _qinhuai_test_result_unit_ok = _qinhuai_test_result_unit_okPtr
      .asFunction<CResultUnit Function()>(isLeaf: true);
}
