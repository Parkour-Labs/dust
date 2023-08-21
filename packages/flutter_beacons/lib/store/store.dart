import 'dart:ffi';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

import '../ffi/ffi_bindings.dart';
import '../ffi/ffi_structs.dart';
import '../serializer/serializer.dart';
import '../reactive/reactive.dart';

part 'id.dart';
part 'repository.dart';
part 'atom.dart';
part 'link.dart';
part 'multilinks.dart';
part 'backlinks.dart';

class Store {
  final FfiBindings bindings;
  int _ports = 0;
  final Map<int, (Id, Serializer, void Function(Object?))> _atomSubscriptions = {};
  final Map<int, (Id, void Function(int?))> _nodeSubscriptions = {};
  final Map<int, (Id, void Function((Id, int, Id)?))> _edgeSubscriptions = {};
  final Map<int, (Id, int, void Function(Id, Id), void Function(Id, Id))> _multiedgeSubscriptions = {};
  final Map<int, (Id, int, void Function(Id, Id), void Function(Id, Id))> _backedgeSubscriptions = {};

  /// These will not get dropped since [Store] is a global singleton.
  late final Finalizer _nodeSubscriptionFinalizer = Finalizer<int>(_unsubscribeNode);
  late final Finalizer _atomSubscriptionFinalizer = Finalizer<int>(_unsubscribeAtom);
  late final Finalizer _edgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeEdge);
  late final Finalizer _multiedgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeMultiedge);
  late final Finalizer _backedgeSubscriptionFinalizer = Finalizer<int>(_unsubscribeBackedge);

  /// The global [Store] instance.
  static late final Store _instance;

  /// Initialises the global [Store] instance.
  static void initialize(DynamicLibrary library, String databasePath) {
    _instance = Store._(FfiBindings(library), databasePath);
  }

  /// Obtains the global [Store] instance. Must be called after [initialize] has been called once.
  static Store get instance => _instance;

  /// Private constructor.
  Store._(this.bindings, String databasePath) {
    final ptr = databasePath.toNativeUtf8(allocator: malloc);
    bindings.init(ptr);
    malloc.free(ptr);
  }

  /// Generates a new name for subscription.
  int newPort() {
    final res = _ports;
    _ports++;
    return res;
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

  int? getNode(Id id) {
    final data = bindings.get_node(id.high, id.low);
    return data.tag == 0 ? null : data.some;
  }

  /*
  T? getAtom<T extends Object>(Id id, Serializer<T> serializer) {
    final data = bindings.get_atom(id.high, id.low);
    if (data.tag == 0) {
      return null;
    } else {
      final bytes = data.some.ptr.asTypedList(data.some.len).buffer.asByteData();
      final obj = serializer.deserialize(BytesReader(bytes));
      bindings.drop_option_array_u8(data);
      return obj;
    }
  }

  (Id, int, Id)? getEdge(Id id) {
    final data = bindings.get_edge(id.high, id.low);
    return data.tag == 0 ? null : (Id.fromNative(data.some.src), data.some.label, Id.fromNative(data.some.dst));
  }
  */

  List<(Id, (Id, int, Id))> getEdgesBySrc(Id src) {
    final data = bindings.get_edges_by_src(src.high, src.low);
    final list = <(Id, (Id, int, Id))>[];
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      list.add((
        Id.fromNative(item.first),
        (Id.fromNative(item.second.src), item.second.label, Id.fromNative(item.second.dst))
      ));
    }
    bindings.drop_array_id_edge(data);
    return list;
  }

  /*
  List<(Id, Id)> getIdDstBySrcLabel(Id src, int label) {
    final data = bindings.get_id_dst_by_src_label(src.high, src.low, label);
    final list = <(Id, Id)>[];
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      list.add((Id.fromNative(item.first), Id.fromNative(item.second)));
    }
    bindings.drop_array_id_id(data);
    return list;
  }

  List<(Id, Id)> getIdSrcByDstLabel(Id dst, int label) {
    final data = bindings.get_id_src_by_dst_label(dst.high, dst.low, label);
    final list = <(Id, Id)>[];
    for (var i = 0; i < data.len; i++) {
      final item = data.ptr.elementAt(i).ref;
      list.add((Id.fromNative(item.first), Id.fromNative(item.second)));
    }
    bindings.drop_array_id_id(data);
    return list;
  }
  */

  void setNode(Id id, int? value) {
    if (value == null) {
      bindings.set_node_none(id.high, id.low);
    } else {
      bindings.set_node_some(id.high, id.low, value);
    }
    _pollEvents();
  }

  void setAtom<T extends Object>(Serializer<T> serializer, Id id, T? value) {
    if (value == null) {
      bindings.set_atom_none(id.high, id.low);
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
      bindings.set_atom_some(id.high, id.low, len, ptr);
      malloc.free(ptr);
    }
    _pollEvents();
  }

  void setEdge(Id id, (Id, int, Id)? value) {
    if (value == null) {
      bindings.set_edge_none(id.high, id.low);
    } else {
      final (src, label, dst) = value;
      bindings.set_edge_some(id.high, id.low, src.high, src.low, label, dst.high, dst.low);
    }
    _pollEvents();
  }

  void setEdgeDst(Id id, Id? dst) {
    if (dst == null) {
      final dst = randomId();
      bindings.set_edge_dst(id.high, id.low, dst.high, dst.low);
    } else {
      bindings.set_edge_dst(id.high, id.low, dst.high, dst.low);
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

  void subscribeNode(Id id, int port, void Function(int? label) change, Object owner) {
    assert(!_nodeSubscriptions.containsKey(port));
    _nodeSubscriptions[port] = (id, change);
    bindings.subscribe_node(id.high, id.low, port);
    _nodeSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeNode(int port) {
    final subscription = _nodeSubscriptions.remove(port);
    if (subscription != null) {
      final id = subscription.$1;
      bindings.unsubscribe_node(id.high, id.low, port);
    }
  }

  void subscribeAtom(Id id, int port, Serializer serializer, void Function(Object? data) change, Object owner) {
    assert(!_atomSubscriptions.containsKey(port));
    _atomSubscriptions[port] = (id, serializer, change);
    bindings.subscribe_atom(id.high, id.low, port);
    _atomSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeAtom(int port) {
    final subscription = _atomSubscriptions.remove(port);
    if (subscription != null) {
      final id = subscription.$1;
      bindings.unsubscribe_atom(id.high, id.low, port);
    }
  }

  void subscribeEdge(Id id, int port, void Function((Id, int, Id)? value) change, Object owner) {
    assert(!_edgeSubscriptions.containsKey(port));
    _edgeSubscriptions[port] = (id, change);
    bindings.subscribe_edge(id.high, id.low, port);
    _edgeSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeEdge(int port) {
    final subscription = _edgeSubscriptions.remove(port);
    if (subscription != null) {
      final id = subscription.$1;
      bindings.unsubscribe_edge(id.high, id.low, port);
    }
  }

  void subscribeMultiedge(Id src, int label, int port, void Function(Id id, Id dst) insert,
      void Function(Id id, Id dst) remove, Object owner) {
    assert(!_multiedgeSubscriptions.containsKey(port));
    _multiedgeSubscriptions[port] = (src, label, insert, remove);
    bindings.subscribe_multiedge(src.high, src.low, label, port);
    _multiedgeSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeMultiedge(int port) {
    final subscription = _multiedgeSubscriptions.remove(port);
    if (subscription != null) {
      final src = subscription.$1;
      final label = subscription.$2;
      bindings.unsubscribe_multiedge(src.high, src.low, label, port);
    }
  }

  void subscribeBackedge(Id dst, int label, int port, void Function(Id id, Id src) insert,
      void Function(Id id, Id src) remove, Object owner) {
    assert(!_backedgeSubscriptions.containsKey(port));
    _backedgeSubscriptions[port] = (dst, label, insert, remove);
    bindings.subscribe_backedge(dst.high, dst.low, label, port);
    _backedgeSubscriptionFinalizer.attach(owner, port);
    _pollEvents();
  }

  void _unsubscribeBackedge(int port) {
    final subscription = _backedgeSubscriptions.remove(port);
    if (subscription != null) {
      final dst = subscription.$1;
      final label = subscription.$2;
      bindings.unsubscribe_backedge(dst.high, dst.low, label, port);
    }
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
          final message =
              edge.tag == 0 ? null : (Id.fromNative(edge.some.src), edge.some.label, Id.fromNative(edge.some.dst));
          _edgeSubscriptions[port]?.$2(message);
        case 3:
          final CPairIdId(first: id, second: dst) = item.union.multiedgeInsert;
          _multiedgeSubscriptions[port]?.$3(Id.fromNative(id), Id.fromNative(dst));
        case 4:
          final CPairIdId(first: id, second: dst) = item.union.multiedgeRemove;
          _multiedgeSubscriptions[port]?.$4(Id.fromNative(id), Id.fromNative(dst));
        case 5:
          final CPairIdId(first: id, second: src) = item.union.backedgeInsert;
          _backedgeSubscriptions[port]?.$3(Id.fromNative(id), Id.fromNative(src));
        case 6:
          final CPairIdId(first: id, second: src) = item.union.backedgeRemove;
          _backedgeSubscriptions[port]?.$4(Id.fromNative(id), Id.fromNative(src));
        default:
          throw UnimplementedError();
      }
    }
    bindings.drop_array_u64_event_data(data);
  }

  Atom<T> getAtom<T extends Object>(Serializer<T> serializer, Id id) {
    final res = Atom<T>._(serializer, id);
    final weak = WeakReference(res);
    subscribeAtom(id, newPort(), serializer, (data) => weak.target?._update(data as T?), res);
    return res;
  }

  AtomOption<T> getAtomOption<T extends Object>(Serializer<T> serializer, Id id) {
    final res = AtomOption<T>._(serializer, id);
    final weak = WeakReference(res);
    subscribeAtom(id, newPort(), serializer, (data) => weak.target?._update(data as T?), res);
    return res;
  }

  Link<T> getLink<T extends Model>(Repository<T> repository, Id id) {
    final res = Link<T>._(repository, id);
    final weak = WeakReference(res);
    subscribeEdge(id, newPort(), (data) => weak.target?._update(data), res);
    return res;
  }

  LinkOption<T> getLinkOption<T extends Model>(Repository<T> repository, Id id) {
    final res = LinkOption<T>._(repository, id);
    final weak = WeakReference(res);
    subscribeEdge(id, newPort(), (data) => weak.target?._update(data), res);
    return res;
  }

  Multilinks<T> getMultilinks<T extends Model>(Repository<T> repository, Id src, int label) {
    final res = Multilinks<T>._(repository, src, label);
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

  Backlinks<T> getBacklinks<T extends Model>(Repository<T> repository, Id dst, int label) {
    final res = Backlinks<T>._(repository, dst, label);
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
