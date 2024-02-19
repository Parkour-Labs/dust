// Copyright 2024 ParkourLabs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

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
    dust_drop_array_u8(error);
    throw NativeError(message);
  }

  void dust_add_acyclic_edge(int label) {
    return _dust_add_acyclic_edge(label);
  }

  late final _dust_add_acyclic_edgePtr =
      _lookup<NativeFunction<Void Function(Uint64)>>('dust_add_acyclic_edge');
  late final _dust_add_acyclic_edge =
      _dust_add_acyclic_edgePtr.asFunction<void Function(int)>(isLeaf: true);

  void dust_add_sticky_atom(int label) {
    return _dust_add_sticky_atom(label);
  }

  late final _dust_add_sticky_atomPtr =
      _lookup<NativeFunction<Void Function(Uint64)>>('dust_add_sticky_atom');
  late final _dust_add_sticky_atom =
      _dust_add_sticky_atomPtr.asFunction<void Function(int)>(isLeaf: true);

  void dust_add_sticky_edge(int label) {
    return _dust_add_sticky_edge(label);
  }

  late final _dust_add_sticky_edgePtr =
      _lookup<NativeFunction<Void Function(Uint64)>>('dust_add_sticky_edge');
  late final _dust_add_sticky_edge =
      _dust_add_sticky_edgePtr.asFunction<void Function(int)>(isLeaf: true);

  void dust_add_sticky_node(int label) {
    return _dust_add_sticky_node(label);
  }

  late final _dust_add_sticky_nodePtr =
      _lookup<NativeFunction<Void Function(Uint64)>>('dust_add_sticky_node');
  late final _dust_add_sticky_node =
      _dust_add_sticky_nodePtr.asFunction<void Function(int)>(isLeaf: true);

  COptionAtom dust_atom(int idh, int idl) {
    final res = _dust_atom(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_atomPtr =
      _lookup<NativeFunction<CResultOptionAtom Function(Uint64, Uint64)>>(
          'dust_atom');
  late final _dust_atom = _dust_atomPtr
      .asFunction<CResultOptionAtom Function(int, int)>(isLeaf: true);

  CArrayTripleIdUint64ArrayUint8 dust_atom_id_label_value_by_src(
      int srch, int srcl) {
    final res = _dust_atom_id_label_value_by_src(srch, srcl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_atom_id_label_value_by_srcPtr = _lookup<
      NativeFunction<
          CResultArrayTripleIdUint64ArrayUint8 Function(
              Uint64, Uint64)>>('dust_atom_id_label_value_by_src');
  late final _dust_atom_id_label_value_by_src =
      _dust_atom_id_label_value_by_srcPtr
          .asFunction<CResultArrayTripleIdUint64ArrayUint8 Function(int, int)>(
              isLeaf: true);

  CArrayPairIdId dust_atom_id_src_by_label_value(
      int label, int len, Pointer<Uint8> ptr) {
    final res = _dust_atom_id_src_by_label_value(label, len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_atom_id_src_by_label_valuePtr = _lookup<
      NativeFunction<
          CResultArrayPairIdId Function(Uint64, Uint64,
              Pointer<Uint8>)>>('dust_atom_id_src_by_label_value');
  late final _dust_atom_id_src_by_label_value =
      _dust_atom_id_src_by_label_valuePtr
          .asFunction<CResultArrayPairIdId Function(int, int, Pointer<Uint8>)>(
              isLeaf: true);

  CArrayTripleIdIdArrayUint8 dust_atom_id_src_value_by_label(int label) {
    final res = _dust_atom_id_src_value_by_label(label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_atom_id_src_value_by_labelPtr = _lookup<
          NativeFunction<CResultArrayTripleIdIdArrayUint8 Function(Uint64)>>(
      'dust_atom_id_src_value_by_label');
  late final _dust_atom_id_src_value_by_label =
      _dust_atom_id_src_value_by_labelPtr
          .asFunction<CResultArrayTripleIdIdArrayUint8 Function(int)>(
              isLeaf: true);

  CArrayPairIdArrayUint8 dust_atom_id_value_by_src_label(
      int srch, int srcl, int label) {
    final res = _dust_atom_id_value_by_src_label(srch, srcl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_atom_id_value_by_src_labelPtr = _lookup<
      NativeFunction<
          CResultArrayPairIdArrayUint8 Function(
              Uint64, Uint64, Uint64)>>('dust_atom_id_value_by_src_label');
  late final _dust_atom_id_value_by_src_label =
      _dust_atom_id_value_by_src_labelPtr
          .asFunction<CResultArrayPairIdArrayUint8 Function(int, int, int)>(
              isLeaf: true);

  CArrayEventData dust_barrier() {
    final res = _dust_barrier();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_barrierPtr =
      _lookup<NativeFunction<CResultArrayEventData Function()>>('dust_barrier');
  late final _dust_barrier = _dust_barrierPtr
      .asFunction<CResultArrayEventData Function()>(isLeaf: true);

  CUnit dust_close() {
    final res = _dust_close();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_closePtr =
      _lookup<NativeFunction<CResultUnit Function()>>('dust_close');
  late final _dust_close =
      _dust_closePtr.asFunction<CResultUnit Function()>(isLeaf: true);

  CUnit dust_commit() {
    final res = _dust_commit();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_commitPtr =
      _lookup<NativeFunction<CResultUnit Function()>>('dust_commit');
  late final _dust_commit =
      _dust_commitPtr.asFunction<CResultUnit Function()>(isLeaf: true);

  /// Drops the return value of [`barrier`].
  void dust_drop_array_event_data(CArrayEventData value) {
    return _dust_drop_array_event_data(value);
  }

  late final _dust_drop_array_event_dataPtr =
      _lookup<NativeFunction<Void Function(CArrayEventData)>>(
          'dust_drop_array_event_data');
  late final _dust_drop_array_event_data = _dust_drop_array_event_dataPtr
      .asFunction<void Function(CArrayEventData)>(isLeaf: true);

  /// Drops the return value of [`node_id_by_label`].
  void dust_drop_array_id(CArrayId value) {
    return _dust_drop_array_id(value);
  }

  late final _dust_drop_array_idPtr =
      _lookup<NativeFunction<Void Function(CArrayId)>>('dust_drop_array_id');
  late final _dust_drop_array_id =
      _dust_drop_array_idPtr.asFunction<void Function(CArrayId)>(isLeaf: true);

  /// Drops the return value of [`atom_id_value_by_src_label`].
  void dust_drop_array_id_array_u8(CArrayPairIdArrayUint8 value) {
    return _dust_drop_array_id_array_u8(value);
  }

  late final _dust_drop_array_id_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayPairIdArrayUint8)>>(
          'dust_drop_array_id_array_u8');
  late final _dust_drop_array_id_array_u8 = _dust_drop_array_id_array_u8Ptr
      .asFunction<void Function(CArrayPairIdArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`atom_id_src_by_label_value`],
  /// [`edge_id_dst_by_src_label`] and [`edge_id_src_by_dst_label`].
  void dust_drop_array_id_id(CArrayPairIdId value) {
    return _dust_drop_array_id_id(value);
  }

  late final _dust_drop_array_id_idPtr =
      _lookup<NativeFunction<Void Function(CArrayPairIdId)>>(
          'dust_drop_array_id_id');
  late final _dust_drop_array_id_id = _dust_drop_array_id_idPtr
      .asFunction<void Function(CArrayPairIdId)>(isLeaf: true);

  /// Drops the return value of [`atom_id_src_value_by_label`].
  void dust_drop_array_id_id_array_u8(CArrayTripleIdIdArrayUint8 value) {
    return _dust_drop_array_id_id_array_u8(value);
  }

  late final _dust_drop_array_id_id_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdArrayUint8)>>(
          'dust_drop_array_id_id_array_u8');
  late final _dust_drop_array_id_id_array_u8 =
      _dust_drop_array_id_id_array_u8Ptr
          .asFunction<void Function(CArrayTripleIdIdArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`edge_id_src_label_by_dst`].
  void dust_drop_array_id_id_u64(CArrayTripleIdIdUint64 value) {
    return _dust_drop_array_id_id_u64(value);
  }

  late final _dust_drop_array_id_id_u64Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdUint64)>>(
          'dust_drop_array_id_id_u64');
  late final _dust_drop_array_id_id_u64 = _dust_drop_array_id_id_u64Ptr
      .asFunction<void Function(CArrayTripleIdIdUint64)>(isLeaf: true);

  /// Drops the return value of [`atom_id_label_value_by_src`].
  void dust_drop_array_id_u64_array_u8(CArrayTripleIdUint64ArrayUint8 value) {
    return _dust_drop_array_id_u64_array_u8(value);
  }

  late final _dust_drop_array_id_u64_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64ArrayUint8)>>(
          'dust_drop_array_id_u64_array_u8');
  late final _dust_drop_array_id_u64_array_u8 =
      _dust_drop_array_id_u64_array_u8Ptr
          .asFunction<void Function(CArrayTripleIdUint64ArrayUint8)>(
              isLeaf: true);

  /// Drops the return value of [`edge_id_label_dst_by_src`].
  void dust_drop_array_id_u64_id(CArrayTripleIdUint64Id value) {
    return _dust_drop_array_id_u64_id(value);
  }

  late final _dust_drop_array_id_u64_idPtr =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64Id)>>(
          'dust_drop_array_id_u64_id');
  late final _dust_drop_array_id_u64_id = _dust_drop_array_id_u64_idPtr
      .asFunction<void Function(CArrayTripleIdUint64Id)>(isLeaf: true);

  /// Drops the return value of [`sync_version`] and [`sync_actions`]
  /// and all error results.
  void dust_drop_array_u8(CArrayUint8 value) {
    return _dust_drop_array_u8(value);
  }

  late final _dust_drop_array_u8Ptr =
      _lookup<NativeFunction<Void Function(CArrayUint8)>>('dust_drop_array_u8');
  late final _dust_drop_array_u8 = _dust_drop_array_u8Ptr
      .asFunction<void Function(CArrayUint8)>(isLeaf: true);

  /// Drops the return value of [`atom`].
  void dust_drop_option_atom(COptionAtom value) {
    return _dust_drop_option_atom(value);
  }

  late final _dust_drop_option_atomPtr =
      _lookup<NativeFunction<Void Function(COptionAtom)>>(
          'dust_drop_option_atom');
  late final _dust_drop_option_atom = _dust_drop_option_atomPtr
      .asFunction<void Function(COptionAtom)>(isLeaf: true);

  COptionEdge dust_edge(int idh, int idl) {
    final res = _dust_edge(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_edgePtr =
      _lookup<NativeFunction<CResultOptionEdge Function(Uint64, Uint64)>>(
          'dust_edge');
  late final _dust_edge = _dust_edgePtr
      .asFunction<CResultOptionEdge Function(int, int)>(isLeaf: true);

  CArrayPairIdId dust_edge_id_dst_by_src_label(int srch, int srcl, int label) {
    final res = _dust_edge_id_dst_by_src_label(srch, srcl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_edge_id_dst_by_src_labelPtr = _lookup<
      NativeFunction<
          CResultArrayPairIdId Function(
              Uint64, Uint64, Uint64)>>('dust_edge_id_dst_by_src_label');
  late final _dust_edge_id_dst_by_src_label = _dust_edge_id_dst_by_src_labelPtr
      .asFunction<CResultArrayPairIdId Function(int, int, int)>(isLeaf: true);

  CArrayTripleIdUint64Id dust_edge_id_label_dst_by_src(int srch, int srcl) {
    final res = _dust_edge_id_label_dst_by_src(srch, srcl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_edge_id_label_dst_by_srcPtr = _lookup<
      NativeFunction<
          CResultArrayTripleIdUint64Id Function(
              Uint64, Uint64)>>('dust_edge_id_label_dst_by_src');
  late final _dust_edge_id_label_dst_by_src = _dust_edge_id_label_dst_by_srcPtr
      .asFunction<CResultArrayTripleIdUint64Id Function(int, int)>(
          isLeaf: true);

  CArrayPairIdId dust_edge_id_src_by_dst_label(int dsth, int dstl, int label) {
    final res = _dust_edge_id_src_by_dst_label(dsth, dstl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_edge_id_src_by_dst_labelPtr = _lookup<
      NativeFunction<
          CResultArrayPairIdId Function(
              Uint64, Uint64, Uint64)>>('dust_edge_id_src_by_dst_label');
  late final _dust_edge_id_src_by_dst_label = _dust_edge_id_src_by_dst_labelPtr
      .asFunction<CResultArrayPairIdId Function(int, int, int)>(isLeaf: true);

  CArrayTripleIdIdUint64 dust_edge_id_src_label_by_dst(int dsth, int dstl) {
    final res = _dust_edge_id_src_label_by_dst(dsth, dstl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_edge_id_src_label_by_dstPtr = _lookup<
      NativeFunction<
          CResultArrayTripleIdIdUint64 Function(
              Uint64, Uint64)>>('dust_edge_id_src_label_by_dst');
  late final _dust_edge_id_src_label_by_dst = _dust_edge_id_src_label_by_dstPtr
      .asFunction<CResultArrayTripleIdIdUint64 Function(int, int)>(
          isLeaf: true);

  COptionNode dust_node(int idh, int idl) {
    final res = _dust_node(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_nodePtr =
      _lookup<NativeFunction<CResultOptionNode Function(Uint64, Uint64)>>(
          'dust_node');
  late final _dust_node = _dust_nodePtr
      .asFunction<CResultOptionNode Function(int, int)>(isLeaf: true);

  CArrayId dust_node_id_by_label(int label) {
    final res = _dust_node_id_by_label(label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_node_id_by_labelPtr =
      _lookup<NativeFunction<CResultArrayId Function(Uint64)>>(
          'dust_node_id_by_label');
  late final _dust_node_id_by_label = _dust_node_id_by_labelPtr
      .asFunction<CResultArrayId Function(int)>(isLeaf: true);

  CUnit dust_open(int len, Pointer<Uint8> ptr) {
    final res = _dust_open(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_openPtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Pointer<Uint8>)>>(
          'dust_open');
  late final _dust_open = _dust_openPtr
      .asFunction<CResultUnit Function(int, Pointer<Uint8>)>(isLeaf: true);

  CId dust_random_id() {
    return _dust_random_id();
  }

  late final _dust_random_idPtr =
      _lookup<NativeFunction<CId Function()>>('dust_random_id');
  late final _dust_random_id =
      _dust_random_idPtr.asFunction<CId Function()>(isLeaf: true);

  CUnit dust_set_atom_none(int idh, int idl) {
    final res = _dust_set_atom_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_set_atom_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>(
          'dust_set_atom_none');
  late final _dust_set_atom_none = _dust_set_atom_nonePtr
      .asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit dust_set_atom_some(int idh, int idl, int srch, int srcl, int label,
      int len, Pointer<Uint8> ptr) {
    final res = _dust_set_atom_some(idh, idl, srch, srcl, label, len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_set_atom_somePtr = _lookup<
      NativeFunction<
          CResultUnit Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64,
              Pointer<Uint8>)>>('dust_set_atom_some');
  late final _dust_set_atom_some = _dust_set_atom_somePtr.asFunction<
      CResultUnit Function(
          int, int, int, int, int, int, Pointer<Uint8>)>(isLeaf: true);

  CUnit dust_set_edge_none(int idh, int idl) {
    final res = _dust_set_edge_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_set_edge_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>(
          'dust_set_edge_none');
  late final _dust_set_edge_none = _dust_set_edge_nonePtr
      .asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit dust_set_edge_some(
      int idh, int idl, int srch, int srcl, int label, int dsth, int dstl) {
    final res = _dust_set_edge_some(idh, idl, srch, srcl, label, dsth, dstl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_set_edge_somePtr = _lookup<
      NativeFunction<
          CResultUnit Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64,
              Uint64)>>('dust_set_edge_some');
  late final _dust_set_edge_some = _dust_set_edge_somePtr
      .asFunction<CResultUnit Function(int, int, int, int, int, int, int)>(
          isLeaf: true);

  CUnit dust_set_node_none(int idh, int idl) {
    final res = _dust_set_node_none(idh, idl);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_set_node_nonePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64)>>(
          'dust_set_node_none');
  late final _dust_set_node_none = _dust_set_node_nonePtr
      .asFunction<CResultUnit Function(int, int)>(isLeaf: true);

  CUnit dust_set_node_some(int idh, int idl, int label) {
    final res = _dust_set_node_some(idh, idl, label);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_set_node_somePtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Uint64, Uint64)>>(
          'dust_set_node_some');
  late final _dust_set_node_some = _dust_set_node_somePtr
      .asFunction<CResultUnit Function(int, int, int)>(isLeaf: true);

  CArrayUint8 dust_sync_actions(int len, Pointer<Uint8> ptr) {
    final res = _dust_sync_actions(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_sync_actionsPtr = _lookup<
          NativeFunction<CResultArrayUint8 Function(Uint64, Pointer<Uint8>)>>(
      'dust_sync_actions');
  late final _dust_sync_actions = _dust_sync_actionsPtr
      .asFunction<CResultArrayUint8 Function(int, Pointer<Uint8>)>(
          isLeaf: true);

  CUnit dust_sync_join(int len, Pointer<Uint8> ptr) {
    final res = _dust_sync_join(len, ptr);
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_sync_joinPtr =
      _lookup<NativeFunction<CResultUnit Function(Uint64, Pointer<Uint8>)>>(
          'dust_sync_join');
  late final _dust_sync_join = _dust_sync_joinPtr
      .asFunction<CResultUnit Function(int, Pointer<Uint8>)>(isLeaf: true);

  CArrayUint8 dust_sync_version() {
    final res = _dust_sync_version();
    if (res.tag != 0) _err(res.body.err);
    return res.body.ok;
  }

  late final _dust_sync_versionPtr =
      _lookup<NativeFunction<CResultArrayUint8 Function()>>(
          'dust_sync_version');
  late final _dust_sync_version = _dust_sync_versionPtr
      .asFunction<CResultArrayUint8 Function()>(isLeaf: true);
}
