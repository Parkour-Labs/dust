// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';
import 'package:ffi/ffi.dart';

import '../ffi.dart';

/// Load and get the native function bindings.
NativeBindings getNativeBindings() => _nativeBindings ??= NativeBindings(getNativeLibrary());

NativeBindings? _nativeBindings;

class NativeBindings {
  final Pointer<T> Function<T extends NativeType>(String symbol) _lookup;

  NativeBindings(DynamicLibrary library) : _lookup = library.lookup;

  late final init = _lookup<NativeFunction<Void Function(Pointer<Utf8>)>>('init')
      .asFunction<void Function(Pointer<Utf8> name)>(isLeaf: true);
  late final make_label = _lookup<NativeFunction<Uint64 Function(Pointer<Utf8>)>>('make_label')
      .asFunction<int Function(Pointer<Utf8> name)>(isLeaf: true);
  late final make_id = _lookup<NativeFunction<CId Function(Pointer<Utf8>)>>('make_id')
      .asFunction<CId Function(Pointer<Utf8> name)>(isLeaf: true);
  late final random_id = _lookup<NativeFunction<CId Function()>>('random_id').asFunction<CId Function()>(isLeaf: true);

  late final get_atom = _lookup<NativeFunction<COptionAtom Function(Uint64, Uint64)>>('get_atom')
      .asFunction<COptionAtom Function(int idh, int idl)>(isLeaf: true);
  late final get_atom_label_value_by_src =
      _lookup<NativeFunction<CArrayTripleIdUint64ArrayUint8 Function(Uint64, Uint64)>>('get_atom_label_value_by_src')
          .asFunction<CArrayTripleIdUint64ArrayUint8 Function(int srch, int srcl)>(isLeaf: true);
  late final get_atom_value_by_src_label =
      _lookup<NativeFunction<CArrayPairIdArrayUint8 Function(Uint64, Uint64, Uint64)>>('get_atom_value_by_src_label')
          .asFunction<CArrayPairIdArrayUint8 Function(int srch, int srcl, int label)>(isLeaf: true);
  late final get_atom_src_value_by_label =
      _lookup<NativeFunction<CArrayTripleIdIdArrayUint8 Function(Uint64)>>('get_atom_src_value_by_label')
          .asFunction<CArrayTripleIdIdArrayUint8 Function(int label)>(isLeaf: true);
  late final get_atom_src_by_label_value =
      _lookup<NativeFunction<CArrayPairIdId Function(Uint64, Uint64, Pointer<Uint8>)>>('get_atom_src_by_label_value')
          .asFunction<CArrayPairIdId Function(int label, int len, Pointer<Uint8> ptr)>(isLeaf: true);

  late final get_edge = _lookup<NativeFunction<COptionEdge Function(Uint64, Uint64)>>('get_edge')
      .asFunction<COptionEdge Function(int idh, int idl)>(isLeaf: true);
  late final get_edge_label_dst_by_src =
      _lookup<NativeFunction<CArrayTripleIdUint64Id Function(Uint64, Uint64)>>('get_edge_label_dst_by_src')
          .asFunction<CArrayTripleIdUint64Id Function(int srch, int srcl)>(isLeaf: true);
  late final get_edge_dst_by_src_label =
      _lookup<NativeFunction<CArrayPairIdId Function(Uint64, Uint64, Uint64)>>('get_edge_dst_by_src_label')
          .asFunction<CArrayPairIdId Function(int srch, int srcl, int label)>(isLeaf: true);
  late final get_edge_src_dst_by_label =
      _lookup<NativeFunction<CArrayTripleIdIdId Function(Uint64)>>('get_edge_src_dst_by_label')
          .asFunction<CArrayTripleIdIdId Function(int label)>(isLeaf: true);
  late final get_edge_src_by_label_dst =
      _lookup<NativeFunction<CArrayPairIdId Function(Uint64, Uint64, Uint64)>>('get_edge_src_by_label_dst')
          .asFunction<CArrayPairIdId Function(int label, int dsth, int dstl)>(isLeaf: true);

  late final set_atom_none = _lookup<NativeFunction<Void Function(Uint64, Uint64)>>('set_atom_none')
      .asFunction<void Function(int idh, int idl)>(isLeaf: true);
  late final set_atom_some =
      _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64, Pointer<Uint8>)>>(
              'set_atom_some')
          .asFunction<void Function(int idh, int idl, int srch, int srcl, int label, int len, Pointer<Uint8> ptr)>(
              isLeaf: true);

  late final set_edge_none = _lookup<NativeFunction<Void Function(Uint64, Uint64)>>('set_edge_none')
      .asFunction<void Function(int idh, int idl)>(isLeaf: true);
  late final set_edge_some =
      _lookup<NativeFunction<Void Function(Uint64, Uint64, Uint64, Uint64, Uint64, Uint64, Uint64)>>('set_edge_some')
          .asFunction<void Function(int idh, int idl, int srch, int srcl, int label, int dsth, int dstl)>(isLeaf: true);

  late final sync_version =
      _lookup<NativeFunction<CArrayUint8 Function()>>('sync_version').asFunction<CArrayUint8 Function()>(isLeaf: true);
  late final sync_actions = _lookup<NativeFunction<CArrayUint8 Function(Uint64, Pointer<Uint8>)>>('sync_actions')
      .asFunction<CArrayUint8 Function(int len, Pointer<Uint8> ptr)>(isLeaf: true);
  late final sync_join = _lookup<NativeFunction<COptionArrayUint8 Function(Uint64, Pointer<Uint8>)>>('sync_join')
      .asFunction<COptionArrayUint8 Function(int len, Pointer<Uint8> ptr)>(isLeaf: true);
  late final poll_events = _lookup<NativeFunction<CArrayEventData Function()>>('poll_events')
      .asFunction<CArrayEventData Function()>(isLeaf: true);

  late final drop_option_atom = _lookup<NativeFunction<Void Function(COptionAtom)>>('drop_option_atom')
      .asFunction<void Function(COptionAtom value)>(isLeaf: true);
  late final drop_array_id_u64_array_u8 =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64ArrayUint8)>>('drop_array_id_u64_array_u8')
          .asFunction<void Function(CArrayTripleIdUint64ArrayUint8 value)>(isLeaf: true);
  late final drop_array_id_array_u8 =
      _lookup<NativeFunction<Void Function(CArrayPairIdArrayUint8)>>('drop_array_id_array_u8')
          .asFunction<void Function(CArrayPairIdArrayUint8 value)>(isLeaf: true);
  late final drop_array_id_id_array_u8 =
      _lookup<NativeFunction<Void Function(CArrayTripleIdIdArrayUint8)>>('drop_array_id_id_array_u8')
          .asFunction<void Function(CArrayTripleIdIdArrayUint8 value)>(isLeaf: true);
  late final drop_array_id_id = _lookup<NativeFunction<Void Function(CArrayPairIdId)>>('drop_array_id_id')
      .asFunction<void Function(CArrayPairIdId value)>(isLeaf: true);
  late final drop_array_id_u64_id =
      _lookup<NativeFunction<Void Function(CArrayTripleIdUint64Id)>>('drop_array_id_u64_id')
          .asFunction<void Function(CArrayTripleIdUint64Id value)>(isLeaf: true);
  late final drop_array_id_id_id = _lookup<NativeFunction<Void Function(CArrayTripleIdIdId)>>('drop_array_id_id_id')
      .asFunction<void Function(CArrayTripleIdIdId value)>(isLeaf: true);
  late final drop_array_u8 = _lookup<NativeFunction<Void Function(CArrayUint8)>>('drop_array_u8')
      .asFunction<void Function(CArrayUint8 value)>(isLeaf: true);
  late final drop_option_array_u8 = _lookup<NativeFunction<Void Function(COptionArrayUint8)>>('drop_option_array_u8')
      .asFunction<void Function(COptionArrayUint8 value)>(isLeaf: true);
  late final drop_array_event_data = _lookup<NativeFunction<Void Function(CArrayEventData)>>('drop_array_event_data')
      .asFunction<void Function(CArrayEventData value)>(isLeaf: true);

  late final test_id = _lookup<NativeFunction<CId Function()>>('test_id').asFunction<CId Function()>(isLeaf: true);
  late final test_id_unsigned =
      _lookup<NativeFunction<CId Function()>>('test_id_unsigned').asFunction<CId Function()>(isLeaf: true);
  late final test_array_u8 =
      _lookup<NativeFunction<CArrayUint8 Function()>>('test_array_u8').asFunction<CArrayUint8 Function()>(isLeaf: true);
  late final test_array_id_id = _lookup<NativeFunction<CArrayPairIdId Function()>>('test_array_id_id')
      .asFunction<CArrayPairIdId Function()>(isLeaf: true);
  late final test_array_id_u64_id = _lookup<NativeFunction<CArrayTripleIdUint64Id Function()>>('test_array_id_u64_id')
      .asFunction<CArrayTripleIdUint64Id Function()>(isLeaf: true);
  late final test_option_atom_some = _lookup<NativeFunction<COptionAtom Function()>>('test_option_atom_some')
      .asFunction<COptionAtom Function()>(isLeaf: true);
  late final test_option_atom_none = _lookup<NativeFunction<COptionAtom Function()>>('test_option_atom_none')
      .asFunction<COptionAtom Function()>(isLeaf: true);
  late final test_option_edge_some = _lookup<NativeFunction<COptionEdge Function()>>('test_option_edge_some')
      .asFunction<COptionEdge Function()>(isLeaf: true);
  late final test_option_edge_none = _lookup<NativeFunction<COptionEdge Function()>>('test_option_edge_none')
      .asFunction<COptionEdge Function()>(isLeaf: true);
  late final test_array_event_data = _lookup<NativeFunction<CArrayEventData Function()>>('test_array_event_data')
      .asFunction<CArrayEventData Function()>(isLeaf: true);
  late final test_array_u8_big = _lookup<NativeFunction<CArrayUint8 Function(Uint64)>>('test_array_u8_big')
      .asFunction<CArrayUint8 Function(int size)>(isLeaf: true);
  late final test_array_event_data_big =
      _lookup<NativeFunction<CArrayEventData Function(Uint64, Uint64)>>('test_array_event_data_big')
          .asFunction<CArrayEventData Function(int entries, int size)>(isLeaf: true);
}
