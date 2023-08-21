import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import '../ffi/ffi_bindings.dart';
import '../ffi/ffi_structs.dart';
import '../serializer/serializer.dart';
import '../reactive/reactive.dart';

part 'repository.dart';
part 'atom.dart';
part 'link.dart';
part 'multilinks.dart';
part 'backlinks.dart';

class Store {
  final FfiBindings bindings;
  int _ports = 0;
  final Map<int, (CId, Serializer, void Function(Object?))> _atomSubscriptions = {};
  final Map<int, (CId, void Function(int?))> _nodeSubscriptions = {};
  final Map<int, (CId, void Function((CId, int, CId)?))> _edgeSubscriptions = {};
  final Map<int, (CId, int, void Function(CId, CId), void Function(CId, CId))> _multiedgeSubscriptions = {};
  final Map<int, (CId, int, void Function(CId, CId), void Function(CId, CId))> _backedgeSubscriptions = {};

  /// These will not get dropped since [Store] is a global singleton.
  late final Finalizer _nodeSubscriptionFinalizer = Finalizer<int>(_unsubscribeNode);
  late final Finalizer _atomSubscriptionFinalizer = Finalizer<int>(_unsubscribeAtom);
  late final Finalizer _edgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeEdge);
  late final Finalizer _multiedgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeMultiedge);
  late final Finalizer _backedgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeBackedge);

  /// The global [Store] instance.
  static late final Store _instance;

  /// Initialises the global [Store] instance.
  static void initialize(DynamicLibrary library) {
    _instance = Store._(FfiBindings(library));
  }

  /// Obtains the global [Store] instance.
  static Store get instance => _instance;

  /// Private constructor.
  Store._(this.bindings);

  /// Generates a new name for subscription.
  int newPort() {
    final res = _ports;
    _ports++;
    return res;
  }

  /*
  int hash(String name) {
    final ptr = name.toNativeUtf8(allocator: malloc);
    final res = bindings.hash(ptr);
    malloc.free(ptr);
    return res;
  }

  int? getNode(CId id) {
    final data = bindings.get_node(id);
    return data.tag == 0 ? null : data.some;
  }

  T? getAtom<T extends Object>(CId id, Serializer<T> serializer) {
    final data = bindings.get_atom(id);
    if (data.tag == 0) {
      return null;
    } else {
      final bytes = data.some.ptr.asTypedList(data.some.len).buffer.asByteData();
      final obj = serializer.deserialize(BytesReader(bytes));
      bindings.drop_option_array_u8(data);
      return obj;
    }
  }

  (CId, int, CId)? getEdge(CId id) {
    final data = bindings.get_edge(id);
    return data.tag == 0 ? null : (data.some.src, data.some.label, data.some.dst);
  }
  */

  List<(CId, (CId, int, CId))> getEdgesBySrc(CId src) {
    final data = bindings.get_edges_by_src(src);
    final list = <(CId, (CId, int, CId))>[];
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      list.add((item.first, (item.second.src, item.second.label, item.second.dst)));
    }
    bindings.drop_array_id_edge(data);
    return list;
  }

  /*
  List<(CId, CId)> getIdDstBySrcLabel(CId src, int label) {
    final data = bindings.get_id_dst_by_src_label(src, label);
    final list = <(CId, CId)>[];
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      list.add((item.first, item.second));
    }
    bindings.drop_array_id_id(data);
    return list;
  }

  List<(CId, CId)> getIdSrcByDstLabel(CId dst, int label) {
    final data = bindings.get_id_src_by_dst_label(dst, label);
    final list = <(CId, CId)>[];
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      list.add((item.first, item.second));
    }
    bindings.drop_array_id_id(data);
    return list;
  }
  */

  void setNode(CId id, int? value) {
    if (value == null) {
      bindings.set_node_none(id);
    } else {
      bindings.set_node_some(id, value);
    }
    _pollEvents();
  }

  void setAtom<T extends Object>(Serializer<T> serializer, CId id, T? value) {
    if (value == null) {
      bindings.set_atom_none(id);
    } else {
      final builder = BytesBuilder();
      serializer.serialize(value, builder);
      final bytes = builder.takeBytes();
      // See: https://github.com/dart-lang/sdk/issues/44589
      final len = bytes.length;
      final ptr = malloc.allocate<Uint8>(len);
      for (var i = 0; i < len; i++) {
        ptr.elementAt(i).value = bytes[i];
      }
      bindings.set_atom_some(id, len, ptr);
      malloc.free(ptr);
    }
    _pollEvents();
  }

  void setEdge(CId id, (CId, int, CId)? value) {
    if (value == null) {
      bindings.set_edge_none(id);
    } else {
      final (src, label, dst) = value;
      bindings.set_edge_some(id, src, label, dst);
    }
    _pollEvents();
  }

  void setEdgeDst(CId id, CId? dst) {
    if (dst == null) {
      bindings.set_edge_dst(id, bindings.random_id());
    } else {
      bindings.set_edge_dst(id, dst);
    }
    _pollEvents();
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
    for (var i = 0; i < len; i++) {
      ptr.elementAt(i).value = version[i];
    }
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
    for (var i = 0; i < len; i++) {
      ptr.elementAt(i).value = actions[i];
    }
    final data = bindings.sync_join(len, ptr);
    malloc.free(ptr);
    final res = data.tag == 0 ? null : Uint8List.fromList(data.some.ptr.asTypedList(data.some.len)); // Makes copy.
    bindings.drop_option_array_u8(data);
    _pollEvents();
    return res;
  }

  void subscribeNode(CId id, int port, void Function(int? label) change, Object owner) {
    assert(!_nodeSubscriptions.containsKey(port));
    _nodeSubscriptions[port] = (id, change);
    bindings.subscribe_node(id, port);
    _nodeSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeNode(int port) {
    final subscription = _nodeSubscriptions.remove(port);
    if (subscription != null) bindings.unsubscribe_node(subscription.$1, port);
  }

  void subscribeAtom(CId id, int port, Serializer serializer, void Function(Object? data) change, Object owner) {
    assert(!_atomSubscriptions.containsKey(port));
    _atomSubscriptions[port] = (id, serializer, change);
    bindings.subscribe_atom(id, port);
    _atomSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeAtom(int port) {
    final subscription = _atomSubscriptions.remove(port);
    if (subscription != null) bindings.unsubscribe_atom(subscription.$1, port);
  }

  void subscribeEdge(CId id, int port, void Function((CId, int, CId)? value) change, Object owner) {
    assert(!_edgeSubscriptions.containsKey(port));
    _edgeSubscriptions[port] = (id, change);
    bindings.subscribe_edge(id, port);
    _edgeSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeEdge(int port) {
    final subscription = _edgeSubscriptions.remove(port);
    if (subscription != null) bindings.unsubscribe_edge(subscription.$1, port);
  }

  void subscribeMultiedge(CId src, int label, int port, void Function(CId id, CId dst) insert,
      void Function(CId id, CId dst) remove, Object owner) {
    assert(!_multiedgeSubscriptions.containsKey(port));
    _multiedgeSubscriptions[port] = (src, label, insert, remove);
    bindings.subscribe_multiedge(src, label, port);
    _multiedgeSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeMultiedge(int port) {
    final subscription = _multiedgeSubscriptions.remove(port);
    if (subscription != null) bindings.unsubscribe_multiedge(subscription.$1, subscription.$2, port);
  }

  void subscribeBackedge(CId dst, int label, int port, void Function(CId id, CId src) insert,
      void Function(CId id, CId src) remove, Object owner) {
    assert(!_backedgeSubscriptions.containsKey(port));
    _backedgeSubscriptions[port] = (dst, label, insert, remove);
    bindings.subscribe_backedge(dst, label, port);
    _backedgeSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeBackedge(int port) {
    final subscription = _backedgeSubscriptions.remove(port);
    if (subscription != null) bindings.unsubscribe_backedge(subscription.$1, subscription.$2, port);
  }

  void _pollEvents() {
    final data = bindings.poll_events();
    for (var i = 0; i < data.len; i++) {
      final CPairUint64EventData(first: port, second: item) = data.ptr.elementAt(i).ref;
      switch (item.tag) {
        case 0:
          final node = item.union.node;
          final message = node.tag == 0 ? null : node.some;
          _nodeSubscriptions[port]?.$2(message);
        case 1:
          final atom = item.union.atom;
          final subscription = _atomSubscriptions[port];
          if (subscription != null) {
            if (atom.tag == 0) {
              subscription.$3(null);
            } else {
              final bytes = atom.some.ptr.asTypedList(atom.some.len).buffer.asByteData();
              final obj = subscription.$2.deserialize(BytesReader(bytes));
              subscription.$3(obj);
            }
          }
        case 2:
          final edge = item.union.edge;
          final message = edge.tag == 0 ? null : (edge.some.src, edge.some.label, edge.some.dst);
          _edgeSubscriptions[port]?.$2(message);
        case 3:
          final CPairIdId(first: id, second: dst) = item.union.multiedgeInsert;
          _multiedgeSubscriptions[port]?.$3(id, dst);
        case 4:
          final CPairIdId(first: id, second: dst) = item.union.multiedgeRemove;
          _multiedgeSubscriptions[port]?.$4(id, dst);
        case 5:
          final CPairIdId(first: id, second: src) = item.union.backedgeInsert;
          _backedgeSubscriptions[port]?.$3(id, src);
        case 6:
          final CPairIdId(first: id, second: src) = item.union.backedgeRemove;
          _backedgeSubscriptions[port]?.$4(id, src);
        default:
          throw UnimplementedError();
      }
    }
    bindings.drop_array_u64_event_data(data);
  }

  Atom<T> getAtom<T extends Object>(Serializer<T> serializer, CId id) {
    final res = Atom<T>.fromRaw(serializer, id);
    final weak = WeakReference(res);
    subscribeAtom(id, newPort(), serializer, (data) => weak.target?._update(data as T?), res);
    return res;
  }

  AtomOption<T> getAtomOption<T extends Object>(Serializer<T> serializer, CId id) {
    final res = AtomOption<T>.fromRaw(serializer, id);
    final weak = WeakReference(res);
    subscribeAtom(id, newPort(), serializer, (data) => weak.target?._update(data as T?), res);
    return res;
  }

  Link<T> getLink<T extends Model>(Repository<T> repository, CId id) {
    final res = Link<T>.fromRaw(repository, id);
    final weak = WeakReference(res);
    subscribeEdge(id, newPort(), (data) => weak.target?._update(data), res);
    return res;
  }

  LinkOption<T> getLinkOption<T extends Model>(Repository<T> repository, CId id) {
    final res = LinkOption<T>.fromRaw(repository, id);
    final weak = WeakReference(res);
    subscribeEdge(id, newPort(), (data) => weak.target?._update(data), res);
    return res;
  }

  Multilinks<T> getMultilinks<T extends Model>(Repository<T> repository, CId src, int label) {
    final res = Multilinks<T>.fromRaw(repository, src, label);
    final weak = WeakReference(res);
    subscribeMultiedge(
      src,
      label,
      newPort(),
      (id, dst) => weak.target?._insert(id, dst),
      (id, dst) => weak.target?._remove(id, dst),
      res,
    );
    return res;
  }

  Backlinks<T> getBacklinks<T extends Model>(Repository<T> repository, CId dst, int label) {
    final res = Backlinks<T>.fromRaw(repository, dst, label);
    final weak = WeakReference(res);
    subscribeBackedge(
      dst,
      label,
      newPort(),
      (id, src) => weak.target?._insert(id, src),
      (id, src) => weak.target?._remove(id, src),
      res,
    );
    return res;
  }
}
