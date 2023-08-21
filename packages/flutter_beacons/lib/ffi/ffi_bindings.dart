// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import 'structs.dart';

class FfiBindings {
  /// Holds the symbol lookup function.
  final Pointer<T> Function<T extends NativeType>(String symbol) _lookup;

  /// The symbols are looked up in [library].
  FfiBindings(DynamicLibrary library) : _lookup = library.lookup;

  late final hash =
      _lookup<NativeFunction<Uint64 Function(Pointer<Utf8>)>>('hash').asFunction<int Function(Pointer<Utf8> name)>();
  late final get_node =
      _lookup<NativeFunction<COptionUint64 Function(CId)>>('get_node').asFunction<COptionUint64 Function(CId id)>();
  late final get_atom = _lookup<NativeFunction<COptionArrayUint8 Function(CId)>>('get_atom')
      .asFunction<COptionArrayUint8 Function(CId id)>();
  late final get_edge =
      _lookup<NativeFunction<COptionEdge Function(CId)>>('get_edge').asFunction<COptionEdge Function(CId id)>();
  late final get_edges_by_src = _lookup<NativeFunction<CArrayPairIdEdge Function(CId)>>('get_edges_by_src')
      .asFunction<CArrayPairIdEdge Function(CId src)>();
  late final get_id_dst_by_src_label =
      _lookup<NativeFunction<CArrayPairIdId Function(CId, Uint64)>>('get_id_dst_by_src_label')
          .asFunction<CArrayPairIdId Function(CId src, int label)>();
  late final get_id_src_by_dst_label =
      _lookup<NativeFunction<CArrayPairIdId Function(CId, Uint64)>>('get_id_src_by_dst_label')
          .asFunction<CArrayPairIdId Function(CId dst, int label)>();

  late final set_node = _lookup<NativeFunction<Void Function(CId, Bool, Uint64)>>('set_node')
      .asFunction<void Function(CId id, bool some, int value)>();
  late final set_atom = _lookup<NativeFunction<Void Function(CId, Bool, CArrayUint8)>>('set_atom')
      .asFunction<void Function(CId id, bool some, CArrayUint8 value)>();
  late final set_edge = _lookup<NativeFunction<Void Function(CId, Bool, CEdge)>>('set_edge')
      .asFunction<void Function(CId id, bool some, CEdge value)>();
  late final set_edge_dst = _lookup<NativeFunction<Void Function(CId, Bool, CId)>>('set_edge_dst')
      .asFunction<void Function(CId id, bool some, CId dst)>();

  late final subscribe_node = _lookup<NativeFunction<Void Function(CId, Uint64)>>('subscribe_node')
      .asFunction<void Function(CId id, int port)>();
  late final unsubscribe_node = _lookup<NativeFunction<Void Function(CId, Uint64)>>('unsubscribe_node')
      .asFunction<void Function(CId id, int port)>();
  late final subscribe_atom = _lookup<NativeFunction<Void Function(CId, Uint64)>>('subscribe_atom')
      .asFunction<void Function(CId id, int port)>();
  late final unsubscribe_atom = _lookup<NativeFunction<Void Function(CId, Uint64)>>('unsubscribe_atom')
      .asFunction<void Function(CId id, int port)>();
  late final subscribe_edge = _lookup<NativeFunction<Void Function(CId, Uint64)>>('subscribe_edge')
      .asFunction<void Function(CId id, int port)>();
  late final unsubscribe_edge = _lookup<NativeFunction<Void Function(CId, Uint64)>>('unsubscribe_edge')
      .asFunction<void Function(CId id, int port)>();
  late final subscribe_multiedge = _lookup<NativeFunction<Void Function(CId, Uint64, Uint64)>>('subscribe_multiedge')
      .asFunction<void Function(CId src, int label, int port)>();
  late final unsubscribe_multiedge =
      _lookup<NativeFunction<Void Function(CId, Uint64, Uint64)>>('unsubscribe_multiedge')
          .asFunction<void Function(CId src, int label, int port)>();
  late final subscribe_backedge = _lookup<NativeFunction<Void Function(CId, Uint64, Uint64)>>('subscribe_backedge')
      .asFunction<void Function(CId dst, int label, int port)>();
  late final unsubscribe_backedge = _lookup<NativeFunction<Void Function(CId, Uint64, Uint64)>>('unsubscribe_backedge')
      .asFunction<void Function(CId dst, int label, int port)>();

  late final sync_version =
      _lookup<NativeFunction<CArrayUint8 Function()>>('sync_version').asFunction<CArrayUint8 Function()>();
  late final sync_actions = _lookup<NativeFunction<CArrayUint8 Function(CArrayUint8)>>('sync_actions')
      .asFunction<CArrayUint8 Function(CArrayUint8 version)>();
  late final sync_join =
      _lookup<NativeFunction<Void Function(CArrayUint8)>>('sync_join').asFunction<void Function(CArrayUint8 version)>();
  late final poll_events = _lookup<NativeFunction<CArrayPairUint64EventData Function()>>('poll_events')
      .asFunction<CArrayPairUint64EventData Function()>();

  late final drop_option_array_u8 = _lookup<NativeFunction<Void Function(COptionArrayUint8)>>('drop_option_array_u8')
      .asFunction<void Function(COptionArrayUint8 value)>();
  late final drop_array_u8 = _lookup<NativeFunction<Void Function(CArrayUint8)>>('drop_array_u8')
      .asFunction<void Function(CArrayUint8 value)>();
  late final drop_array_id_edge = _lookup<NativeFunction<Void Function(CArrayPairIdEdge)>>('drop_array_id_edge')
      .asFunction<void Function(CArrayPairIdEdge value)>();
  late final drop_array_id_id = _lookup<NativeFunction<Void Function(CArrayPairIdId)>>('drop_array_id_id')
      .asFunction<void Function(CArrayPairIdId value)>();
  late final drop_array_u64_event_data =
      _lookup<NativeFunction<Void Function(CArrayPairUint64EventData)>>('drop_array_u64_event_data')
          .asFunction<void Function(CArrayPairUint64EventData value)>();

  late final test_id = _lookup<NativeFunction<CId Function()>>('test_id').asFunction<CId Function()>();
  late final test_id_unsigned =
      _lookup<NativeFunction<CId Function()>>('test_id_unsigned').asFunction<CId Function()>();
  late final test_id_input =
      _lookup<NativeFunction<Bool Function(CId)>>('test_id_input').asFunction<bool Function(CId)>();
  late final test_id_input_unsigned =
      _lookup<NativeFunction<Bool Function(CId)>>('test_id_input_unsigned').asFunction<bool Function(CId)>();
  late final test_edge = _lookup<NativeFunction<CEdge Function()>>('test_edge').asFunction<CEdge Function()>();
  late final test_edge_input =
      _lookup<NativeFunction<Bool Function(CEdge)>>('test_edge_input').asFunction<bool Function(CEdge)>();

  late final test_array_u8 =
      _lookup<NativeFunction<CArrayUint8 Function()>>('test_array_u8').asFunction<CArrayUint8 Function()>();
  late final test_array_pair_id_id = _lookup<NativeFunction<CArrayPairIdId Function()>>('test_array_pair_id_id')
      .asFunction<CArrayPairIdId Function()>();
  late final test_array_pair_id_edge = _lookup<NativeFunction<CArrayPairIdEdge Function()>>('test_array_pair_id_edge')
      .asFunction<CArrayPairIdEdge Function()>();

  late final test_option_u64_none =
      _lookup<NativeFunction<COptionUint64 Function()>>('test_option_u64_none').asFunction<COptionUint64 Function()>();
  late final test_option_u64_some =
      _lookup<NativeFunction<COptionUint64 Function()>>('test_option_u64_some').asFunction<COptionUint64 Function()>();
  late final test_option_array_u8_some =
      _lookup<NativeFunction<COptionArrayUint8 Function()>>('test_option_array_u8_some')
          .asFunction<COptionArrayUint8 Function()>();
  late final test_option_edge_some =
      _lookup<NativeFunction<COptionEdge Function()>>('test_option_edge_some').asFunction<COptionEdge Function()>();

  late final test_array_pair_u64_event_data =
      _lookup<NativeFunction<CArrayPairUint64EventData Function()>>('test_array_pair_u64_event_data')
          .asFunction<CArrayPairUint64EventData Function()>();

  late final test_array_u8_big = _lookup<NativeFunction<CArrayUint8 Function(Uint64)>>('test_array_u8_big')
      .asFunction<CArrayUint8 Function(int size)>();
  late final test_array_pair_u64_event_data_big =
      _lookup<NativeFunction<CArrayPairUint64EventData Function(Uint64, Uint64)>>('test_array_pair_u64_event_data_big')
          .asFunction<CArrayPairUint64EventData Function(int entries, int size)>();
}
