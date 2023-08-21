// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'ffi_structs.dart';

class FfiBindings {
  final Pointer<T> Function<T extends NativeType>(String symbol) _lookup;

  FfiBindings(DynamicLibrary library) : _lookup = library.lookup;

  late final init = _lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('init')
      .asFunction<void Function(Pointer<Utf8> name)>(isLeaf: true);
  late final make_label = _lookup<NativeFunction<Uint64 Function(Pointer<Utf8>)>>('make_label')
      .asFunction<int Function(Pointer<Utf8> name)>(isLeaf: true);
  late final make_id = _lookup<NativeFunction<CId Function(Pointer<Utf8>)>>('make_id')
      .asFunction<CId Function(Pointer<Utf8> name)>(isLeaf: true);
  late final random_id = _lookup<NativeFunction<CId Function()>>('random_id').asFunction<CId Function()>(isLeaf: true);

  late final get_node = _lookup<NativeFunction<COptionUint64 Function(Uint64, Uint64)>>('get_node')
      .asFunction<COptionUint64 Function(int idh, int idl)>(isLeaf: true);
  late final get_atom = _lookup<NativeFunction<COptionArrayUint8 Function(Uint64, Uint64)>>('get_atom')
      .asFunction<COptionArrayUint8 Function(int idh, int idl)>(isLeaf: true);
  late final get_edge = _lookup<NativeFunction<COptionEdge Function(Uint64, Uint64)>>('get_edge')
      .asFunction<COptionEdge Function(int idh, int idl)>(isLeaf: true);
  late final get_edges_by_src = _lookup<NativeFunction<CArrayPairIdEdge Function(Uint64, Uint64)>>('get_edges_by_src')
      .asFunction<CArrayPairIdEdge Function(int sh, int sl)>(isLeaf: true);
  late final get_id_dst_by_src_label =
      _lookup<NativeFunction<CArrayPairIdId Function(Uint64, Uint64, Uint64)>>('get_id_dst_by_src_label')
          .asFunction<CArrayPairIdId Function(int sh, int sl, int label)>(isLeaf: true);
  late final get_id_src_by_dst_label =
      _lookup<NativeFunction<CArrayPairIdId Function(Uint64, Uint64, Uint64)>>('get_id_src_by_dst_label')
          .asFunction<CArrayPairIdId Function(int dh, int dl, int label)>(isLeaf: true);

  late final set_node_none = _lookup<NativeFunction<Void Function(Uint64, Uint64)>>('set_node_none')
      .asFunction<void Function(int idh, int idl)>(isLeaf: true);
  late final set_node_some = _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64)>>('set_node_some')
      .asFunction<void Function(int idh, int idl, int value)>(isLeaf: true);
  late final set_atom_none = _lookup<NativeFunction<Void Function(Uint64, Uint64)>>('set_atom_none')
      .asFunction<void Function(int idh, int idl)>(isLeaf: true);
  late final set_atom_some =
      _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Pointer<Uint8>)>>('set_atom_some')
          .asFunction<void Function(int idh, int idl, int len, Pointer<Uint8> ptr)>(isLeaf: true);
  late final set_edge_none = _lookup<NativeFunction<Void Function(Uint64, Uint64)>>('set_edge_none')
      .asFunction<void Function(int idh, int idl)>(isLeaf: true);
  late final set_edge_some =
      _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64, Uint64)>>('set_edge_some')
          .asFunction<void Function(int idh, int idl, int sh, int sl, int label, int dh, int dl)>(isLeaf: true);
  late final set_edge_dst = _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Uint64)>>('set_edge_dst')
      .asFunction<void Function(int idh, int idl, int dh, int dl)>(isLeaf: true);

  late final subscribe_node = _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64)>>('subscribe_node')
      .asFunction<void Function(int idh, int idl, int port)>(isLeaf: true);
  late final unsubscribe_node = _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64)>>('unsubscribe_node')
      .asFunction<void Function(int idh, int idl, int port)>(isLeaf: true);
  late final subscribe_atom = _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64)>>('subscribe_atom')
      .asFunction<void Function(int idh, int idl, int port)>(isLeaf: true);
  late final unsubscribe_atom = _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64)>>('unsubscribe_atom')
      .asFunction<void Function(int idh, int idl, int port)>(isLeaf: true);
  late final subscribe_edge = _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64)>>('subscribe_edge')
      .asFunction<void Function(int idh, int idl, int port)>(isLeaf: true);
  late final unsubscribe_edge = _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64)>>('unsubscribe_edge')
      .asFunction<void Function(int idh, int idl, int port)>(isLeaf: true);
  late final subscribe_multiedge =
      _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Uint64)>>('subscribe_multiedge')
          .asFunction<void Function(int sh, int sl, int label, int port)>(isLeaf: true);
  late final unsubscribe_multiedge =
      _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Uint64)>>('unsubscribe_multiedge')
          .asFunction<void Function(int sh, int sl, int label, int port)>(isLeaf: true);
  late final subscribe_backedge =
      _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Uint64)>>('subscribe_backedge')
          .asFunction<void Function(int dh, int dl, int label, int port)>(isLeaf: true);
  late final unsubscribe_backedge =
      _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Uint64)>>('unsubscribe_backedge')
          .asFunction<void Function(int dh, int dl, int label, int port)>(isLeaf: true);

  late final sync_version =
      _lookup<NativeFunction<CArrayUint8 Function()>>('sync_version').asFunction<CArrayUint8 Function()>(isLeaf: true);
  late final sync_actions = _lookup<NativeFunction<CArrayUint8 Function(Uint64, Pointer<Uint8>)>>('sync_actions')
      .asFunction<CArrayUint8 Function(int len, Pointer<Uint8> ptr)>(isLeaf: true);
  late final sync_join = _lookup<NativeFunction<COptionArrayUint8 Function(Uint64, Pointer<Uint8>)>>('sync_join')
      .asFunction<COptionArrayUint8 Function(int len, Pointer<Uint8> ptr)>(isLeaf: true);
  late final poll_events = _lookup<NativeFunction<CArrayPairUint64EventData Function()>>('poll_events')
      .asFunction<CArrayPairUint64EventData Function()>(isLeaf: true);

  late final drop_option_array_u8 = _lookup<NativeFunction<Void Function(COptionArrayUint8)>>('drop_option_array_u8')
      .asFunction<void Function(COptionArrayUint8 value)>(isLeaf: true);
  late final drop_array_u8 = _lookup<NativeFunction<Void Function(CArrayUint8)>>('drop_array_u8')
      .asFunction<void Function(CArrayUint8 value)>(isLeaf: true);
  late final drop_array_id_edge = _lookup<NativeFunction<Void Function(CArrayPairIdEdge)>>('drop_array_id_edge')
      .asFunction<void Function(CArrayPairIdEdge value)>(isLeaf: true);
  late final drop_array_id_id = _lookup<NativeFunction<Void Function(CArrayPairIdId)>>('drop_array_id_id')
      .asFunction<void Function(CArrayPairIdId value)>(isLeaf: true);
  late final drop_array_u64_event_data =
      _lookup<NativeFunction<Void Function(CArrayPairUint64EventData)>>('drop_array_u64_event_data')
          .asFunction<void Function(CArrayPairUint64EventData value)>(isLeaf: true);
}

class FfiTestBindings {
  final Pointer<T> Function<T extends NativeType>(String symbol) _lookup;

  FfiTestBindings(DynamicLibrary library) : _lookup = library.lookup;

  late final test_id = _lookup<NativeFunction<CId Function()>>('test_id').asFunction<CId Function()>(isLeaf: true);
  late final test_id_unsigned =
      _lookup<NativeFunction<CId Function()>>('test_id_unsigned').asFunction<CId Function()>(isLeaf: true);
  late final test_edge =
      _lookup<NativeFunction<CEdge Function()>>('test_edge').asFunction<CEdge Function()>(isLeaf: true);

  late final test_array_u8 =
      _lookup<NativeFunction<CArrayUint8 Function()>>('test_array_u8').asFunction<CArrayUint8 Function()>(isLeaf: true);
  late final test_array_pair_id_id = _lookup<NativeFunction<CArrayPairIdId Function()>>('test_array_pair_id_id')
      .asFunction<CArrayPairIdId Function()>(isLeaf: true);
  late final test_array_pair_id_edge = _lookup<NativeFunction<CArrayPairIdEdge Function()>>('test_array_pair_id_edge')
      .asFunction<CArrayPairIdEdge Function()>(isLeaf: true);

  late final test_option_u64_none = _lookup<NativeFunction<COptionUint64 Function()>>('test_option_u64_none')
      .asFunction<COptionUint64 Function()>(isLeaf: true);
  late final test_option_u64_some = _lookup<NativeFunction<COptionUint64 Function()>>('test_option_u64_some')
      .asFunction<COptionUint64 Function()>(isLeaf: true);
  late final test_option_array_u8_some =
      _lookup<NativeFunction<COptionArrayUint8 Function()>>('test_option_array_u8_some')
          .asFunction<COptionArrayUint8 Function()>(isLeaf: true);
  late final test_option_edge_some = _lookup<NativeFunction<COptionEdge Function()>>('test_option_edge_some')
      .asFunction<COptionEdge Function()>(isLeaf: true);

  late final test_array_pair_u64_event_data =
      _lookup<NativeFunction<CArrayPairUint64EventData Function()>>('test_array_pair_u64_event_data')
          .asFunction<CArrayPairUint64EventData Function()>(isLeaf: true);

  late final test_array_u8_big = _lookup<NativeFunction<CArrayUint8 Function(Uint64)>>('test_array_u8_big')
      .asFunction<CArrayUint8 Function(int size)>(isLeaf: true);
  late final test_array_pair_u64_event_data_big =
      _lookup<NativeFunction<CArrayPairUint64EventData Function(Uint64, Uint64)>>('test_array_pair_u64_event_data_big')
          .asFunction<CArrayPairUint64EventData Function(int entries, int size)>(isLeaf: true);
}
