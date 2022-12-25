import 'dart:async';
import 'dart:math';

import 'package:isar/isar.dart';

import '../utils/rw_queue_lock.dart';
import 'operation.dart';

/// A string value associated with some node.
class Atom<A> {
  AtomOp _latest;
  A payload;

  Atom._(this._latest, this.payload);

  int get id => _latest.atomId;
  int get label => _latest.label;
  int get srcId => _latest.srcId;
  String get value => _latest.value;
  bool get removed => _latest.removed;
}

/// An edge connecting some two nodes.
class Edge<E> {
  EdgeOp _latest;
  E payload;

  Edge._(this._latest, this.payload);

  int get id => _latest.edgeId;
  int get label => _latest.label;
  int get srcId => _latest.srcId;
  int get dstId => _latest.dstId;
  bool get removed => _latest.removed;
}

/// A last-writer-win graph structure stored in database and partially cached in memory.
///
/// Can be used as singleton (monolithic graph) or create multiple instances with distinct `graphId`s (key-CRDT store).
///
/// The primitive operations are `load`, `unload` and `merge` (for [Atom]s and [Edge]s); from there, other operations
/// (`add`, `modify` and `remove`) are implemented.
class Graph<A, E> {
  final Isar isar;
  final RWQueueLock lock = RWQueueLock();
  final GraphData data;

  final Map<int, Atom<A>> atoms = {};
  final Map<int, Edge<E>> edges = {};

  /// Initialise with metadata.
  Graph(this.isar, int graphId)
      : data = isar.graphDatas.getSync(graphId) ?? GraphData.values(graphId, Identifier.random(), -1);

  /// Returns the graph name.
  int get graphId => data.graphId;

  /// Returns current time stamp. Guarantees a different value for each invocation!
  int timeStamp() => data.lastTimeStamp = max(DateTime.now().microsecondsSinceEpoch, data.lastTimeStamp + 1);

  /// Returns the replica ID.
  int get replicaId => data.replicaId;

  /// [op] must be either a placeholder or latest modification fetched from database.
  Atom<A> loadAtom(AtomOp op, A payload) {
    assert(op.graphId == graphId, 'Trying to load atoms from unrelated graphs.');
    assert(!atoms.containsKey(op.atomId), 'Make sure to handle already-loaded items before calling loadAtom().');
    final atom = Atom._(op, payload);
    atoms[atom.id] = atom;
    if (!atom.removed) registerAtom(atom, false);
    return atom;
  }

  /// [op] must be either a placeholder or latest modification fetched from database.
  Edge<E> loadEdge(EdgeOp op, E payload) {
    assert(op.graphId == graphId, 'Trying to load edges from unrelated graphs.');
    assert(!edges.containsKey(op.edgeId), 'Make sure to handle already-loaded items before calling loadEdge().');
    final edge = Edge._(op, payload);
    edges[edge.id] = edge;
    if (!edge.removed) registerEdge(edge, false);
    return edge;
  }

  /// Waits for [atom] to be saved, then disposes [atom].
  /// Returns asynchronously.
  Future<void> unloadAtom(Atom<A> atom) {
    return lock.enqueueWrite(() async {
      if (!atom.removed) unregisterAtom(atom, false);
      atoms.remove(atom.id);
      // atom.dispose();
    });
  }

  /// Waits for [edge] to be saved, then disposes [edge].
  /// Returns asynchronously.
  Future<void> unloadEdge(Edge<E> edge) {
    return lock.enqueueWrite(() async {
      if (!edge.removed) unregisterEdge(edge, false);
      edges.remove(edge.id);
      // edge.dispose();
    });
  }

  /// Merges with an atom modification.
  /// Returns synchronously. Async write operations are queued.
  void mergeAtom(AtomOp op) {
    assert(op.graphId == graphId, 'Trying to merge modifications from unrelated graphs.');
    final found = atoms[op.atomId];
    if (found != null && op.compareTo(found._latest) > 0) {
      // Memory entry found but out-of-date. Update.
      final prev = found._latest;
      found._latest = op;
      // Invoke appropriate handler.
      if (!prev.removed && !op.removed) {
        assert(prev.atomId == op.atomId);
        assert(prev.label == op.label);
        assert(prev.srcId == op.srcId);
        updateAtom(found, prev.value, op.value);
      } else if (prev.removed && !op.removed) {
        registerAtom(found, true);
      } else if (!prev.removed && op.removed) {
        unregisterAtom(found, true);
      }
    }
    lock.enqueueWrite(
      () => isar.writeTxn(() async {
        // Write lock held. Save the modification (deduplicated by `op.opId`) and the last timestamp.
        await isar.atomOps.put(op);
        if (op.replicaId == replicaId) await isar.graphDatas.put(data);
      }),
    );
  }

  /// Merges with an edge modification.
  /// Returns synchronously. Async write operations are queued.
  void mergeEdge(EdgeOp op) {
    assert(op.graphId == graphId, 'Trying to merge modifications from unrelated graphs.');
    final found = edges[op.edgeId];
    if (found != null && op.compareTo(found._latest) > 0) {
      // Memory entry found but out-of-date. Update.
      final prev = found._latest;
      found._latest = op;
      // Invoke appropriate handler.
      if (!prev.removed && !op.removed) {
        assert(prev.edgeId == op.edgeId);
        assert(prev.label == op.label);
        updateEdge(found, prev.srcId, op.srcId, prev.dstId, op.dstId);
      } else if (prev.removed && !op.removed) {
        registerEdge(found, true);
      } else if (!prev.removed && op.removed) {
        unregisterEdge(found, true);
      }
    }
    lock.enqueueWrite(
      () => isar.writeTxn(() async {
        // Write lock held. Save the modification (deduplicated by `op.opId`) and the last timestamp.
        await isar.edgeOps.put(op);
        if (op.replicaId == replicaId) await isar.graphDatas.put(data);
      }),
    );
  }

  /// Constructs a "removed atom" for use when creating new atoms without waiting for async loading.
  /// [atomId] must be new.
  AtomOp placeholderAtomOp(int atomId) => AtomOp.values(null, graphId, -1, replicaId, atomId, 0, 0, '', true);

  /// Constructs a "removed edge" for use when creating new edges without waiting for async loading.
  /// [edgeId] must be new.
  EdgeOp placeholderEdgeOp(int edgeId) => EdgeOp.values(null, graphId, -1, replicaId, edgeId, 0, 0, 0, true);

  /// Creates an atom.
  /// Returns synchronously. Async write operations are queued.
  Atom<A> addAtom(int label, int srcId, String value, A payload) {
    final atomId = Identifier.random();
    final res = loadAtom(placeholderAtomOp(atomId), payload);
    mergeAtom(AtomOp.values(null, graphId, timeStamp(), replicaId, atomId, label, srcId, value, false));
    return res;
  }

  /// Creates an edge.
  /// Returns synchronously. Async write operations are queued.
  Edge<E> addEdge(int label, int srcId, int dstId, E payload) {
    final edgeId = Identifier.random();
    final res = loadEdge(placeholderEdgeOp(edgeId), payload);
    mergeEdge(EdgeOp.values(null, graphId, timeStamp(), replicaId, edgeId, label, srcId, dstId, false));
    return res;
  }

  /// Updates an atom.
  /// Returns synchronously. Async write operations are queued.
  void modifyAtom(Atom<A> atom, String value) {
    mergeAtom(AtomOp.values(null, graphId, timeStamp(), replicaId, atom.id, atom.label, atom.srcId, value, false));
  }

  /// Updates an edge.
  /// Returns synchronously. Async write operations are queued.
  void modifyEdge(Edge<E> edge, int srcId, int dstId) {
    mergeEdge(EdgeOp.values(null, graphId, timeStamp(), replicaId, edge.id, edge.label, srcId, dstId, false));
  }

  /// Removes an atom (without unloading it).
  /// Returns synchronously. Async write operations are queued.
  void removeAtom(Atom<A> atom) {
    mergeAtom(AtomOp.values(null, graphId, timeStamp(), replicaId, atom.id, atom.label, atom.srcId, atom.value, true));
  }

  /// Removes an edge (without unloading it).
  /// Returns synchronously. Async write operations are queued.
  void removeEdge(Edge<E> edge) {
    mergeEdge(EdgeOp.values(null, graphId, timeStamp(), replicaId, edge.id, edge.label, edge.srcId, edge.dstId, true));
  }

  void registerAtom(Atom<A> atom, bool created) {}
  void unregisterAtom(Atom<A> atom, bool removed) {}
  void updateAtom(Atom<A> atom, String prev, String curr) {}

  void registerEdge(Edge<E> edge, bool created) {}
  void unregisterEdge(Edge<E> edge, bool removed) {}
  void updateEdge(Edge<E> edge, int prevSrc, int currSrc, int prevDst, int currDst) {}

  /// Used in custom queries to filter out only the lastest modification of each atom.
  static Iterable<AtomOp> latestForEachAtomId(Iterable<AtomOp> ops) {
    final Map<int, AtomOp> res = {};
    for (final op in ops) {
      final curr = res[op.atomId];
      if (curr == null || op.compareTo(curr) > 0) res[op.atomId] = op;
    }
    return res.values;
  }

  /// Used in custom queries to filter out only the lastest modification of each edge.
  static Iterable<EdgeOp> latestForEachEdgeId(Iterable<EdgeOp> ops) {
    final Map<int, EdgeOp> res = {};
    for (final op in ops) {
      final curr = res[op.edgeId];
      if (curr == null || op.compareTo(curr) > 0) res[op.edgeId] = op;
    }
    return res.values;
  }
}
