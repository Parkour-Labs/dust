// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import 'ffi/native_bindings.dart';
import 'ffi/native_structs.dart';
import 'multimap.dart';
import 'serializer.dart';
import 'store/id.dart';
import 'store/repository.dart';

export 'store/id.dart';
export 'store/schema.dart';
export 'store/repository.dart';
export 'store/node.dart';
export 'store/atom.dart';
export 'store/link.dart';
export 'store/multilinks.dart';
export 'store/backlinks.dart';

class AlreadyDeletedException<T> implements Exception {}

ByteData _view(CArrayUint8 array) => array.ptr.asTypedList(array.len).buffer.asByteData();

typedef NodeByIdSubscription = void Function(int? l);
typedef NodeByLabelSubscription = (void Function(Id id), void Function(Id id));
typedef AtomByIdSubscription = void Function((Id, int, ByteData)? slv);
typedef AtomBySrcSubscription = (void Function(Id id, int label, ByteData value), void Function(Id id));
typedef AtomBySrcLabelSubscription = (void Function(Id id, ByteData value), void Function(Id id));
typedef AtomByLabelSubscription = (void Function(Id id, Id src, ByteData value), void Function(Id id));
typedef AtomByLabelValueSubscription = (void Function(Id id, Id src), void Function(Id id));
typedef EdgeByIdSubscription = void Function((Id, int, Id)? sld);
typedef EdgeBySrcSubscription = (void Function(Id id, int label, Id dst), void Function(Id id));
typedef EdgeBySrcLabelSubscription = (void Function(Id id, Id dst), void Function(Id id));
typedef EdgeByDstSubscription = (void Function(Id id, Id src, int label), void Function(Id id));
typedef EdgeByDstLabelSubscription = (void Function(Id id, Id src), void Function(Id id));

/// The main wrapper class around FFI functions.
///
/// Also responsible for subscriptions and reactivity.
class Store {
  final NativeBindings bindings;
  Timer? committer;

  final nodeById = MultiMap<Id, NodeByIdSubscription>();
  final nodeByLabel = MultiMap<int, NodeByLabelSubscription>();
  final atomById = MultiMap<Id, AtomByIdSubscription>();
  final atomBySrc = MultiMap<Id, AtomBySrcSubscription>();
  final atomBySrcLabel = MultiMap<(Id, int), AtomBySrcLabelSubscription>();
  final atomByLabel = MultiMap<int, AtomByLabelSubscription>();
  // final atomByLabelValue = MultiMap<(int, Object), AtomByLabelValueSubscription>();
  final edgeById = MultiMap<Id, EdgeByIdSubscription>();
  final edgeBySrc = MultiMap<Id, EdgeBySrcSubscription>();
  final edgeBySrcLabel = MultiMap<(Id, int), EdgeBySrcLabelSubscription>();
  final edgeByDst = MultiMap<Id, EdgeByDstSubscription>();
  final edgeByDstLabel = MultiMap<(Id, int), EdgeByDstLabelSubscription>();

  late final _nodeByIdFinalizer = Finalizer<(Id, NodeByIdSubscription)>(_unsubscribeNodeById);
  late final _nodeByLabelFinalizer = Finalizer<(int, NodeByLabelSubscription)>(_unsubscribeNodeByLabel);
  late final _atomByIdFinalizer = Finalizer<(Id, AtomByIdSubscription)>(_unsubscribeAtomById);
  late final _atomBySrcFinalizer = Finalizer<(Id, AtomBySrcSubscription)>(_unsubscribeAtomBySrc);
  late final _atomBySrcLabelFinalizer = Finalizer<((Id, int), AtomBySrcLabelSubscription)>(_unsubscribeAtomBySrcLabel);
  late final _atomByLabelFinalizer = Finalizer<(int, AtomByLabelSubscription)>(_unsubscribeAtomByLabel);
  // late final _atomByLabelValueFinalizer = Finalizer<((int, Object), AtomByLabelValueSubscription)>(_unsubscribeAtomByLabelValue);
  late final _edgeByIdFinalizer = Finalizer<(Id, EdgeByIdSubscription)>(_unsubscribeEdgeById);
  late final _edgeBySrcFinalizer = Finalizer<(Id, EdgeBySrcSubscription)>(_unsubscribeEdgeBySrc);
  late final _edgeBySrcLabelFinalizer = Finalizer<((Id, int), EdgeBySrcLabelSubscription)>(_unsubscribeEdgeBySrcLabel);
  late final _edgeByDstFinalizer = Finalizer<(Id, EdgeByDstSubscription)>(_unsubscribeEdgeByDst);
  late final _edgeByDstLabelFinalizer = Finalizer<((Id, int), EdgeByDstLabelSubscription)>(_unsubscribeEdgeByDstLabel);

  Store._(this.bindings);

  /// The global [Store] instance.
  static Store? _instance;

  /// Initialises the global [Store] instance.
  static void open(String databasePath, List<Repository> repositories) {
    final bindings = getNativeBindings();
    for (final repository in repositories) {
      final schema = repository.init();
      for (final label in schema.stickyNodes) bindings.qinhuai_add_sticky_node(label);
      for (final label in schema.stickyAtoms) bindings.qinhuai_add_sticky_atom(label);
      for (final label in schema.stickyEdges) bindings.qinhuai_add_sticky_edge(label);
      for (final label in schema.acyclicEdges) bindings.qinhuai_add_acyclic_edge(label);
    }
    final ptr = databasePath.toNativeUtf8(allocator: malloc);
    bindings.qinhuai_open(ptr.length, ptr.cast<Uint8>());
    malloc.free(ptr);
    _instance = Store._(bindings);
  }

  /// Disconnects the global [Store] instance.
  static void close() {
    instance.committer?.cancel();
    instance.bindings.qinhuai_close();
    _instance = null;
  }

  /// Obtains the global [Store] instance. Must be called after [open] has been called once.
  static Store get instance => _instance!;

  /// Makes a random 128-bit ID.
  Id randomId() {
    return Id.fromNative(bindings.qinhuai_random_id());
  }

  /// Obtains node value.
  void getNodeById(Id id, void Function(int?) fn) {
    final data = bindings.qinhuai_node(id.high, id.low);
    fn(data.tag == 0 ? null : data.some.label);
  }

  /// Queries the reverse index.
  void getNodeByLabel(int label, void Function(Id) fn) {
    final data = bindings.qinhuai_node_id_by_label(label);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem));
    }
    bindings.qinhuai_drop_array_id(data);
  }

  /// Obtains atom value.
  void getAtomById(Id id, void Function((Id, int, ByteData)?) fn) {
    final data = bindings.qinhuai_atom(id.high, id.low);
    fn(data.tag == 0 ? null : (Id.fromNative(data.some.src), data.some.label, _view(data.some.value)));
    bindings.qinhuai_drop_option_atom(data);
  }

  /// Queries the forward index.
  void getAtomLabelValueBySrc(Id src, void Function(Id, int, ByteData) fn) {
    final data = bindings.qinhuai_atom_id_label_value_by_src(src.high, src.low);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem.first), elem.second, _view(elem.third));
    }
    bindings.qinhuai_drop_array_id_u64_array_u8(data);
  }

  /// Queries the forward index.
  void getAtomValueBySrcLabel(Id src, int label, void Function(Id, ByteData) fn) {
    final data = bindings.qinhuai_atom_id_value_by_src_label(src.high, src.low, label);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem.first), _view(elem.second));
    }
    bindings.qinhuai_drop_array_id_array_u8(data);
  }

  /// Queries the reverse index.
  void getAtomSrcValueByLabel(int label, void Function(Id, Id, ByteData) fn) {
    final data = bindings.qinhuai_atom_id_src_value_by_label(label);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem.first), Id.fromNative(elem.second), _view(elem.third));
    }
    bindings.qinhuai_drop_array_id_id_array_u8(data);
  }

  /*
  /// Queries the reverse index.
  void getAtomSrcByLabelValue(int label, Uint8List value, void Function(Id, Id) fn) {
    throw UnimplementedError();
  }
  */

  /// Obtains edge value.
  void getEdgeById(Id id, void Function((Id, int, Id)?) fn) {
    final data = bindings.qinhuai_edge(id.high, id.low);
    fn(data.tag == 0 ? null : (Id.fromNative(data.some.src), data.some.label, Id.fromNative(data.some.dst)));
  }

  /// Queries the forward index.
  void getEdgeLabelDstBySrc(Id src, void Function(Id, int, Id) fn) {
    final data = bindings.qinhuai_edge_id_label_dst_by_src(src.high, src.low);
    for (var i = 0; i < data.len; i++) {
      final elem = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(elem.first), elem.second, Id.fromNative(elem.third));
    }
    bindings.qinhuai_drop_array_id_u64_id(data);
  }

  /// Queries the forward index.
  void getEdgeDstBySrcLabel(Id src, int label, void Function(Id, Id) fn) {
    final data = bindings.qinhuai_edge_id_dst_by_src_label(src.high, src.low, label);
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(item.first), Id.fromNative(item.second));
    }
    bindings.qinhuai_drop_array_id_id(data);
  }

  /// Queries the reverse index.
  void getEdgeSrcLabelByDst(Id dst, void Function(Id, Id, int) fn) {
    final data = bindings.qinhuai_edge_id_src_label_by_dst(dst.high, dst.low);
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(item.first), Id.fromNative(item.second), item.third);
    }
    bindings.qinhuai_drop_array_id_id_u64(data);
  }

  /// Queries the reverse index.
  void getEdgeSrcByDstLabel(Id dst, int label, void Function(Id, Id) fn) {
    final data = bindings.qinhuai_edge_id_src_by_dst_label(dst.high, dst.low, label);
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      fn(Id.fromNative(item.first), Id.fromNative(item.second));
    }
    bindings.qinhuai_drop_array_id_id(data);
  }

  /// Modifies node value. Requires a [barrier] call to come into effect.
  void setNode(Id id, int? l) {
    if (l == null) {
      bindings.qinhuai_set_node_none(id.high, id.low);
    } else {
      final label = l;
      bindings.qinhuai_set_node_some(id.high, id.low, label);
    }
  }

  /// Modifies atom value. Requires a [barrier] call to come into effect.
  void setAtom<T>(Id id, (Id, int, T, Serializer<T>)? slv) {
    if (slv == null) {
      bindings.qinhuai_set_atom_none(id.high, id.low);
    } else {
      final (src, label, value, serializer) = slv;
      final builder = BytesBuilder();
      serializer.serialize(value, builder);
      final bytes = builder.takeBytes();
      // See: https://github.com/dart-lang/sdk/issues/44589
      final len = bytes.length;
      final ptr = malloc.allocate<Uint8>(len);
      for (var i = 0; i < len; i++) ptr.elementAt(i).value = bytes[i];
      bindings.qinhuai_set_atom_some(id.high, id.low, src.high, src.low, label, len, ptr);
      malloc.free(ptr);
    }
  }

  /// Modifies edge value. Requires a [barrier] call to come into effect.
  void setEdge(Id id, (Id, int, Id)? sld) {
    if (sld == null) {
      bindings.qinhuai_set_edge_none(id.high, id.low);
    } else {
      final (src, label, dst) = sld;
      bindings.qinhuai_set_edge_some(id.high, id.low, src.high, src.low, label, dst.high, dst.low);
    }
  }

  Uint8List syncVersion() {
    final data = bindings.qinhuai_sync_version();
    final res = Uint8List.fromList(data.ptr.asTypedList(data.len)); // Makes copy.
    bindings.qinhuai_drop_array_u8(data);
    return res;
  }

  Uint8List syncActions(Uint8List version) {
    // See: https://github.com/dart-lang/sdk/issues/44589
    final len = version.length;
    final ptr = malloc.allocate<Uint8>(len);
    for (var i = 0; i < len; i++) ptr.elementAt(i).value = version[i];
    final data = bindings.qinhuai_sync_actions(len, ptr);
    malloc.free(ptr);
    final res = Uint8List.fromList(data.ptr.asTypedList(data.len)); // Makes copy.
    bindings.qinhuai_drop_array_u8(data);
    return res;
  }

  /// Requires a [barrier] call to come into effect.
  void syncJoin(Uint8List actions) {
    // See: https://github.com/dart-lang/sdk/issues/44589
    final len = actions.length;
    final ptr = malloc.allocate<Uint8>(len);
    for (var i = 0; i < len; i++) ptr.elementAt(i).value = actions[i];
    final _ = bindings.qinhuai_sync_join(len, ptr);
    malloc.free(ptr);
  }

  /// Subscribes to node value changes.
  void subscribeNodeById(Id id, void Function(int? l) update, Object owner) {
    final key = id;
    final value = update;
    nodeById.add(key, value);
    _nodeByIdFinalizer.attach(owner, (key, value));
    getNodeById(id, update);
  }

  /// Subscribes to queries on the reverse index.
  void subscribeNodeByLabel(int label, void Function(Id id) insert, void Function(Id id) remove, Object owner) {
    final key = label;
    final value = (insert, remove);
    nodeByLabel.add(key, value);
    _nodeByLabelFinalizer.attach(owner, (key, value));
    getNodeByLabel(label, insert);
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
  void subscribeEdgeByDst(
      Id dst, void Function(Id id, Id src, int label) insert, void Function(Id id) remove, Object owner) {
    final key = dst;
    final value = (insert, remove);
    edgeByDst.add(key, value);
    _edgeByDstFinalizer.attach(owner, (key, value));
    getEdgeSrcLabelByDst(dst, insert);
  }

  /// Subscribes to queries on the reverse index.
  void subscribeEdgeByDstLabel(
      Id dst, int label, void Function(Id id, Id src) insert, void Function(Id id) remove, Object owner) {
    final key = (dst, label);
    final value = (insert, remove);
    edgeByDstLabel.add(key, value);
    _edgeByDstLabelFinalizer.attach(owner, (key, value));
    getEdgeSrcByDstLabel(dst, label, insert);
  }

  void _unsubscribeNodeById((Id, NodeByIdSubscription) kv) => nodeById.remove(kv.$1, kv.$2);
  void _unsubscribeNodeByLabel((int, NodeByLabelSubscription) kv) => nodeByLabel.remove(kv.$1, kv.$2);
  void _unsubscribeAtomById((Id, AtomByIdSubscription) kv) => atomById.remove(kv.$1, kv.$2);
  void _unsubscribeAtomBySrc((Id, AtomBySrcSubscription) kv) => atomBySrc.remove(kv.$1, kv.$2);
  void _unsubscribeAtomBySrcLabel(((Id, int), AtomBySrcLabelSubscription) kv) => atomBySrcLabel.remove(kv.$1, kv.$2);
  void _unsubscribeAtomByLabel((int, AtomByLabelSubscription) kv) => atomByLabel.remove(kv.$1, kv.$2);
  // void _unsubscribeAtomByLabelValue(((int, Object), AtomByLabelValueSubscription) kv) => atomByLabelValue.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeById((Id, EdgeByIdSubscription) kv) => edgeById.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeBySrc((Id, EdgeBySrcSubscription) kv) => edgeBySrc.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeBySrcLabel(((Id, int), EdgeBySrcLabelSubscription) kv) => edgeBySrcLabel.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeByDst((Id, EdgeByDstSubscription) kv) => edgeByDst.remove(kv.$1, kv.$2);
  void _unsubscribeEdgeByDstLabel(((Id, int), EdgeByDstLabelSubscription) kv) => edgeByDstLabel.remove(kv.$1, kv.$2);

  /// Processes all events and invokes relevant observers.
  void barrier() {
    final data = bindings.qinhuai_barrier();
    for (var i = 0; i < data.len; i++) {
      final event = data.ptr.elementAt(i).ref;
      switch (event.tag) {
        case 0:
          final id = Id.fromNative(event.body.node.id);
          final prev = event.body.node.prev;
          final curr = event.body.node.curr;
          if (prev.tag != 0) {
            final label = prev.some.label;
            for (final (_, remove) in nodeByLabel[label]) remove(id);
          }
          if (curr.tag != 0) {
            final label = curr.some.label;
            for (final update in nodeById[id]) update(label);
            for (final (insert, _) in nodeByLabel[label]) insert(id);
          } else {
            for (final update in nodeById[id]) update(null);
          }
        case 1:
          final id = Id.fromNative(event.body.atom.id);
          final prev = event.body.atom.prev;
          final curr = event.body.atom.curr;
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
        case 2:
          final id = Id.fromNative(event.body.edge.id);
          final prev = event.body.edge.prev;
          final curr = event.body.edge.curr;
          if (prev.tag != 0) {
            final src = Id.fromNative(prev.some.src);
            final label = prev.some.label;
            final dst = Id.fromNative(prev.some.dst);
            for (final (_, remove) in edgeBySrc[src]) remove(id);
            for (final (_, remove) in edgeBySrcLabel[(src, label)]) remove(id);
            for (final (_, remove) in edgeByDst[dst]) remove(id);
            for (final (_, remove) in edgeByDstLabel[(dst, label)]) remove(id);
          }
          if (curr.tag != 0) {
            final src = Id.fromNative(curr.some.src);
            final label = curr.some.label;
            final dst = Id.fromNative(curr.some.dst);
            for (final update in edgeById[id]) update((src, label, dst));
            for (final (insert, _) in edgeBySrc[src]) insert(id, label, dst);
            for (final (insert, _) in edgeBySrcLabel[(src, label)]) insert(id, dst);
            for (final (insert, _) in edgeByDst[dst]) insert(id, src, label);
            for (final (insert, _) in edgeByDstLabel[(dst, label)]) insert(id, src);
          } else {
            for (final update in edgeById[id]) update(null);
          }
        default:
          throw UnimplementedError();
      }
    }
    bindings.qinhuai_drop_array_event_data(data);

    // Debounced commit after each barrier.
    committer?.cancel();
    committer = Timer(const Duration(milliseconds: 200), bindings.qinhuai_commit);
  }
}
