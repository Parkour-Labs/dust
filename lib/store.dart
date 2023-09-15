// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'ffi/native_bindings.dart';
import 'ffi/native_structs.dart';
import 'multimap.dart';
import 'serializer.dart';
import 'store/id.dart';

export 'store/id.dart';
export 'store/repository.dart';
export 'store/atom.dart';
export 'store/link.dart';
export 'store/multilinks.dart';
export 'store/backlinks.dart';
export 'store/all_atoms.dart';
export 'store/all_links.dart';

typedef AtomByIdSubscription = void Function((Id, int, ByteData)? slv);
typedef AtomBySrcSubscription = (void Function(Id id, int label, ByteData value), void Function(Id id));
typedef AtomBySrcLabelSubscription = (void Function(Id id, ByteData value), void Function(Id id));
typedef AtomByLabelSubscription = (void Function(Id id, Id src, ByteData value), void Function(Id id));
typedef AtomByLabelValueSubscription = (void Function(Id id, Id src), void Function(Id id));

typedef EdgeByIdSubscription = void Function((Id, int, Id)? sld);
typedef EdgeBySrcSubscription = (void Function(Id id, int label, Id dst), void Function(Id id));
typedef EdgeBySrcLabelSubscription = (void Function(Id id, Id dst), void Function(Id id));
typedef EdgeByLabelSubscription = (void Function(Id id, Id src, Id dst), void Function(Id id));
typedef EdgeByLabelDstSubscription = (void Function(Id id, Id src), void Function(Id id));

/// The main wrapper class around FFI functions.
///
/// Also responsible for subscriptions and reactivity.
class Store {
  final NativeBindings bindings;

  final atomById = MultiMap<Id, AtomByIdSubscription>();
  final atomBySrc = MultiMap<Id, AtomBySrcSubscription>();
  final atomBySrcLabel = MultiMap<(Id, int), AtomBySrcLabelSubscription>();
  final atomByLabel = MultiMap<int, AtomByLabelSubscription>();
  // final atomByLabelValue = MultiMap<(int, Object), AtomByLabelValueSubscription>();

  final edgeById = MultiMap<Id, EdgeByIdSubscription>();
  final edgeBySrc = MultiMap<Id, EdgeBySrcSubscription>();
  final edgeBySrcLabel = MultiMap<(Id, int), EdgeBySrcLabelSubscription>();
  final edgeByLabel = MultiMap<int, EdgeByLabelSubscription>();
  final edgeByLabelDst = MultiMap<(int, Id), EdgeByLabelDstSubscription>();

  late final _atomByIdFinalizer = Finalizer<(Id, AtomByIdSubscription)>(_unsubscribeAtomById);
  late final _atomBySrcFinalizer = Finalizer<(Id, AtomBySrcSubscription)>(_unsubscribeAtomBySrc);
  late final _atomBySrcLabelFinalizer = Finalizer<((Id, int), AtomBySrcLabelSubscription)>(_unsubscribeAtomBySrcLabel);
  late final _atomByLabelFinalizer = Finalizer<(int, AtomByLabelSubscription)>(_unsubscribeAtomByLabel);
  // late final _atomByLabelValueFinalizer = Finalizer<((int, Object), AtomByLabelValueSubscription)>(_unsubscribeAtomByLabelValue);

  late final _edgeByIdFinalizer = Finalizer<(Id, EdgeByIdSubscription)>(_unsubscribeEdgeById);
  late final _edgeBySrcFinalizer = Finalizer<(Id, EdgeBySrcSubscription)>(_unsubscribeEdgeBySrc);
  late final _edgeBySrcLabelFinalizer = Finalizer<((Id, int), EdgeBySrcLabelSubscription)>(_unsubscribeEdgeBySrcLabel);
  late final _edgeByLabelFinalizer = Finalizer<(int, EdgeByLabelSubscription)>(_unsubscribeEdgeByLabel);
  late final _edgeByLabelDstFinalizer = Finalizer<((int, Id), EdgeByLabelDstSubscription)>(_unsubscribeEdgeByLabelDst);

  /// The global [Store] instance.
  static late final Store _instance;

  /// Initialises the global [Store] instance.
  static void initialize(String databasePath) {
    _instance = Store._(getNativeBindings(), databasePath);
  }

  /// Obtains the global [Store] instance. Must be called after [initialize] has been called once.
  static Store get instance => _instance;

  /// Private constructor.
  Store._(this.bindings, String databasePath) {
    final ptr = databasePath.toNativeUtf8(allocator: malloc);
    bindings.init(ptr);
    malloc.free(ptr);
  }

  /// Makes a label from name.
  int makeLabel(String name) {
    final ptr = name.toNativeUtf8(allocator: malloc);
    final res = bindings.make_label(ptr);
    malloc.free(ptr);
    return res;
  }

  /// Makes an 128-bit ID from name.
  Id makeId(String name) {
    final ptr = name.toNativeUtf8(allocator: malloc);
    final res = Id.fromNative(bindings.make_id(ptr));
    malloc.free(ptr);
    return res;
  }

  /// Makes a random 128-bit ID.
  Id randomId() {
    return Id.fromNative(bindings.random_id());
  }

  /// A helper function for creating a [ByteData] view.
  ByteData _view(CArrayUint8 array) => array.ptr.asTypedList(array.len).buffer.asByteData();

  /// Obtains atom value.
  void getAtomById(Id id, void Function((Id, int, ByteData)?) fn) {
    final data = bindings.get_atom(id.high, id.low);
    fn(data.tag == 0 ? null : (Id.fromNative(data.some.src), data.some.label, _view(data.some.value)));
    bindings.drop_option_atom(data);
  }

  /// Queries the forward index.
  void getAtomLabelValueBySrc(Id src, void Function(Id, int, ByteData) fn) {
    final data = bindings.get_atom_label_value_by_src(src.high, src.low);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem.first), elem.second, _view(elem.third));
    }
    bindings.drop_array_id_u64_array_u8(data);
  }

  /// Queries the forward index.
  void getAtomValueBySrcLabel(Id src, int label, void Function(Id, ByteData) fn) {
    final data = bindings.get_atom_value_by_src_label(src.high, src.low, label);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem.first), _view(elem.second));
    }
    bindings.drop_array_id_array_u8(data);
  }

  /// Queries the reverse index.
  void getAtomSrcValueByLabel(int label, void Function(Id, Id, ByteData) fn) {
    final data = bindings.get_atom_src_value_by_label(label);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem.first), Id.fromNative(elem.second), _view(elem.third));
    }
    bindings.drop_array_id_id_array_u8(data);
  }

  /*
  /// Queries the reverse index.
  void getAtomSrcByLabelValue(int label, Uint8List value, void Function(Id, Id) fn) {
    throw UnimplementedError();
  }
  */

  /// Obtains edge value.
  void getEdgeById(Id id, void Function((Id, int, Id)?) fn) {
    final data = bindings.get_edge(id.high, id.low);
    fn(data.tag == 0 ? null : (Id.fromNative(data.some.src), data.some.label, Id.fromNative(data.some.dst)));
  }

  /// Queries the forward index.
  void getEdgeLabelDstBySrc(Id src, void Function(Id, int, Id) fn) {
    final data = bindings.get_edge_label_dst_by_src(src.high, src.low);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem.first), elem.second, Id.fromNative(elem.third));
    }
    bindings.drop_array_id_u64_id(data);
  }

  /// Queries the forward index.
  void getEdgeDstBySrcLabel(Id src, int label, void Function(Id, Id) fn) {
    final data = bindings.get_edge_dst_by_src_label(src.high, src.low, label);
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(item.first), Id.fromNative(item.second));
    }
    bindings.drop_array_id_id(data);
  }

  /// Queries the reverse index.
  void getEdgeSrcDstByLabel(int label, void Function(Id, Id, Id) fn) {
    final data = bindings.get_edge_src_dst_by_label(label);
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(item.first), Id.fromNative(item.second), Id.fromNative(item.third));
    }
    bindings.drop_array_id_id_id(data);
  }

  /// Queries the reverse index.
  void getEdgeSrcByLabelDst(int label, Id dst, void Function(Id, Id) fn) {
    final data = bindings.get_edge_src_by_label_dst(label, dst.high, dst.low);
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(item.first), Id.fromNative(item.second));
    }
    bindings.drop_array_id_id(data);
  }

  /// Modifies atom value.
  /// TODO: move to atom
  void setAtom<T>(Id id, (Id, int, T, Serializer<T>)? slv) {
    if (slv == null) {
      bindings.set_atom_none(id.high, id.low);
    } else {
      final (src, label, value, serializer) = slv;
      final builder = BytesBuilder();
      serializer.serialize(value, builder);
      final bytes = builder.takeBytes();
      // See: https://github.com/dart-lang/sdk/issues/44589
      final len = bytes.length;
      final ptr = malloc.allocate<Uint8>(len);
      for (var i = 0; i < len; i++) ptr.elementAt(i).value = bytes[i];
      bindings.set_atom_some(id.high, id.low, src.high, src.low, label, len, ptr);
      malloc.free(ptr);
    }
    pollEvents();
  }

  /// Modifies edge value.
  void setEdge(Id id, (Id, int, Id)? sld) {
    if (sld == null) {
      bindings.set_edge_none(id.high, id.low);
    } else {
      final (src, label, dst) = sld;
      bindings.set_edge_some(id.high, id.low, src.high, src.low, label, dst.high, dst.low);
    }
    pollEvents();
  }

  Uint8List syncVersion() {
    final data = bindings.sync_version();
    final res = Uint8List.fromList(data.ptr.asTypedList(data.len)); // Makes copy.
    bindings.drop_array_u8(data);
    return res;
  }

  Uint8List syncActions(Uint8List version) {
    // See: https://github.com/dart-lang/sdk/issues/44589
    final len = version.length;
    final ptr = malloc.allocate<Uint8>(len);
    for (var i = 0; i < len; i++) ptr.elementAt(i).value = version[i];
    final data = bindings.sync_actions(len, ptr);
    malloc.free(ptr);
    final res = Uint8List.fromList(data.ptr.asTypedList(data.len)); // Makes copy.
    bindings.drop_array_u8(data);
    return res;
  }

  Uint8List? syncJoin(Uint8List actions) {
    // See: https://github.com/dart-lang/sdk/issues/44589
    final len = actions.length;
    final ptr = malloc.allocate<Uint8>(len);
    for (var i = 0; i < len; i++) ptr.elementAt(i).value = actions[i];
    final data = bindings.sync_join(len, ptr);
    malloc.free(ptr);
    final res = data.tag == 0 ? null : Uint8List.fromList(data.some.ptr.asTypedList(data.some.len)); // Makes copy.
    bindings.drop_option_array_u8(data);
    pollEvents();
    return res;
  }

  /// Subscribes to atom value changes.
  void subscribeAtomById(Id id, void Function((Id, int, ByteData)? slv) update, Object owner) {
    final key = id;
    final value = update;
    atomById.add(key, value);
    _atomByIdFinalizer.attach(owner, (key, value));
    getAtomById(id, update);
  }

  /// Subscribes to queries on the forward index.
  void subscribeAtomBySrc(
      Id src, void Function(Id id, int label, ByteData value) insert, void Function(Id id) remove, Object owner) {
    final key = src;
    final value = (insert, remove);
    atomBySrc.add(key, value);
    _atomBySrcFinalizer.attach(owner, (key, value));
    getAtomLabelValueBySrc(src, insert);
  }

  /// Subscribes to queries on the forward index.
  void subscribeAtomBySrcLabel(
      Id src, int label, void Function(Id id, ByteData value) insert, void Function(Id id) remove, Object owner) {
    final key = (src, label);
    final value = (insert, remove);
    atomBySrcLabel.add(key, value);
    _atomBySrcLabelFinalizer.attach(owner, (key, value));
    getAtomValueBySrcLabel(src, label, insert);
  }

  /// Subscribes to queries on the reverse index.
  void subscribeAtomByLabel(
      int label, void Function(Id id, Id src, ByteData value) insert, void Function(Id id) remove, Object owner) {
    final key = label;
    final value = (insert, remove);
    atomByLabel.add(key, value);
    _atomByLabelFinalizer.attach(owner, (key, value));
    getAtomSrcValueByLabel(label, insert);
  }

  /*
  /// Subscribes to queries on the reverse index.
  void subscribeAtomByLabelValue(int label, ByteData value, void Function(Id id, Id src) insert,
      void Function(Id id) remove, Object owner) {
    throw UnimplementedError();
  }
  */

  /// Subscribes to edge value changes.
  void subscribeEdgeById(Id id, void Function((Id, int, Id)? sld) update, Object owner) {
    final key = id;
    final value = update;
    edgeById.add(key, value);
    _edgeByIdFinalizer.attach(owner, (key, value));
    getEdgeById(id, update);
  }

  /// Subscribes to queries on the forward index.
  void subscribeEdgeBySrc(
      Id src, void Function(Id id, int label, Id dst) insert, void Function(Id id) remove, Object owner) {
    final key = src;
    final value = (insert, remove);
    edgeBySrc.add(key, value);
    _edgeBySrcFinalizer.attach(owner, (key, value));
    getEdgeLabelDstBySrc(src, insert);
  }

  /// Subscribes to queries on the forward index.
  void subscribeEdgeBySrcLabel(
      Id src, int label, void Function(Id id, Id dst) insert, void Function(Id id) remove, Object owner) {
    final key = (src, label);
    final value = (insert, remove);
    edgeBySrcLabel.add(key, value);
    _edgeBySrcLabelFinalizer.attach(owner, (key, value));
    getEdgeDstBySrcLabel(src, label, insert);
  }

  /// Subscribes to queries on the reverse index.
  void subscribeEdgeByLabel(
      int label, void Function(Id id, Id src, Id dst) insert, void Function(Id id) remove, Object owner) {
    final key = label;
    final value = (insert, remove);
    edgeByLabel.add(key, value);
    _edgeByLabelFinalizer.attach(owner, (key, value));
    getEdgeSrcDstByLabel(label, insert);
  }

  /// Subscribes to queries on the reverse index.
  void subscribeEdgeByLabelDst(
      int label, Id dst, void Function(Id id, Id src) insert, void Function(Id id) remove, Object owner) {
    final key = (label, dst);
    final value = (insert, remove);
    edgeByLabelDst.add(key, value);
    _edgeByLabelDstFinalizer.attach(owner, (key, value));
    getEdgeSrcByLabelDst(label, dst, insert);
  }

  void _unsubscribeAtomById((Id, AtomByIdSubscription) kv) => atomById.remove(kv.$1, kv.$2);
  void _unsubscribeAtomBySrc((Id, AtomBySrcSubscription) kv) => atomBySrc.remove(kv.$1, kv.$2);
  void _unsubscribeAtomBySrcLabel(((Id, int), AtomBySrcLabelSubscription) kv) => atomBySrcLabel.remove(kv.$1, kv.$2);
  void _unsubscribeAtomByLabel((int, AtomByLabelSubscription) kv) => atomByLabel.remove(kv.$1, kv.$2);
  // void _unsubscribeAtomByLabelValue(((int, Object), AtomByLabelValueSubscription) kv) => atomByLabelValue.remove(kv.$1, kv.$2);

  void _unsubscribeEdgeById((Id, EdgeByIdSubscription) kv) => edgeById.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeBySrc((Id, EdgeBySrcSubscription) kv) => edgeBySrc.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeBySrcLabel(((Id, int), EdgeBySrcLabelSubscription) kv) => edgeBySrcLabel.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeByLabel((int, EdgeByLabelSubscription) kv) => edgeByLabel.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeByLabelDst(((int, Id), EdgeByLabelDstSubscription) kv) => edgeByLabelDst.remove(kv.$1, kv.$2);

  /// Processes all events and invoke relevant observers.
  void pollEvents() {
    final data = bindings.poll_events();
    for (var i = 0; i < data.len; i++) {
      final event = data.ptr.elementAt(i).ref;
      switch (event.tag) {
        case 0:
          final id = Id.fromNative(event.union.atom.id);
          final prev = event.union.atom.prev;
          final curr = event.union.atom.curr;
          if (prev.tag != 0) {
            final src = Id.fromNative(prev.some.src);
            final label = prev.some.label;
            final _ = _view(prev.some.value);
            for (final (_, remove) in atomBySrc[src]) remove(id);
            for (final (_, remove) in atomBySrcLabel[(src, label)]) remove(id);
            for (final (_, remove) in atomByLabel[label]) remove(id);
          }
          if (curr.tag != 0) {
            final src = Id.fromNative(curr.some.src);
            final label = curr.some.label;
            final value = _view(curr.some.value);
            for (final update in atomById[id]) update((id, label, value));
            for (final (insert, _) in atomBySrc[src]) insert(id, label, value);
            for (final (insert, _) in atomBySrcLabel[(src, label)]) insert(id, value);
            for (final (insert, _) in atomByLabel[label]) insert(id, src, value);
          } else {
            for (final update in atomById[id]) update(null);
          }
        case 1:
          final id = Id.fromNative(event.union.edge.id);
          final prev = event.union.edge.prev;
          final curr = event.union.edge.curr;
          if (prev.tag != 0) {
            final src = Id.fromNative(prev.some.src);
            final label = prev.some.label;
            final dst = Id.fromNative(prev.some.dst);
            for (final (_, remove) in edgeBySrc[src]) remove(id);
            for (final (_, remove) in edgeBySrcLabel[(src, label)]) remove(id);
            for (final (_, remove) in edgeByLabel[label]) remove(id);
            for (final (_, remove) in edgeByLabelDst[(label, dst)]) remove(id);
          }
          if (curr.tag != 0) {
            final src = Id.fromNative(curr.some.src);
            final label = curr.some.label;
            final dst = Id.fromNative(curr.some.dst);
            for (final update in edgeById[id]) update((src, label, dst));
            for (final (insert, _) in edgeBySrc[src]) insert(id, label, dst);
            for (final (insert, _) in edgeBySrcLabel[(src, label)]) insert(id, dst);
            for (final (insert, _) in edgeByLabel[label]) insert(id, src, dst);
            for (final (insert, _) in edgeByLabelDst[(label, dst)]) insert(id, src);
          } else {
            for (final update in edgeById[id]) update(null);
          }
        default:
          throw UnimplementedError();
      }
    }
    bindings.drop_array_event_data(data);
  }
}
