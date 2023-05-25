import 'package:isar/isar.dart';

import '../basic/multi_map.dart';
import '../reactive/reactive.dart';
import 'operation.dart';
import 'graph.dart';

class Backlink {
  final int id;
  final int label;
  final Source payload;
  Set<Edge<Source?>>? edges;

  Backlink(this.id, this.label, this.payload);

  Iterable<int>? get srcIds => edges?.map((e) => e.srcId);

  void load(Set<Edge<Source?>> edges) {
    this.edges = edges;
    payload.notify();
  }

  void unload() {
    edges = null;
    payload.notify();
  }

  void add(Edge<Source?> e) {
    edges?.add(e);
    if (edges != null) payload.notify();
  }
  
  void remove(Edge<Source?> e) {
    edges?.remove(e);
    if (edges != null) payload.notify();
  }
}

/// Extended [Graph] that tracks more information (to support reactivity, links and backlinks).
///
/// Any notifiable sources pointed to by [Atom.payload] and [Edge.payload] will be notified on change
/// of respective atoms and edges.
class ModelGraph extends Graph<Source?, Source?> {
  final MultiMap<int, Atom<Source?>> atomsOf = MultiMap();
  final MultiMap<int, Edge<Source?>> edgesFrom = MultiMap();
  final MultiMap<int, Edge<Source?>> edgesTo = MultiMap();
  final Map<(int, int), Backlink> edgesToWithLabel = {};

  ModelGraph(super.isar, super.graphId);

  /// Loads all atoms and edges from a node with given [id].
  /// Returns asynchronously.
  Future<(List<Atom<Source?>>, List<Edge<Source?>>)> loadAtomsAndEdgesFrom(int id) {
    return lock.enqueueRead(() async {
      // Read lock held. Load latest modifications from database.
      final atomOps = await isar.atomOps.where().graphIdSrcIdEqualToAnyLabel(graphId, id).findAll();
      final edgeOps = await isar.edgeOps.where().graphIdSrcIdEqualToAnyLabel(graphId, id).findAll();
      // Check if already loaded (in which case memory data is newer than database).
      return (
        atomOps.map((e) => atoms[e.atomId] ?? loadAtom(e, null)).toList(),
        edgeOps.map((e) => edges[e.edgeId] ?? loadEdge(e, null)).toList(),
      );
    });
  }

  /// Loads all edges ending at a node with given [id] and with label [label].
  /// Returns asynchronously.
  Future<Set<Edge<Source?>>> loadEdgesToWithLabel(int id, int label) {
    return lock.enqueueRead(() async {
      // Read lock held. Load latest modifications from database.
      final ops = await isar.edgeOps.where().graphIdDstIdLabelEqualTo(graphId, id, label).findAll();
      // Check if already loaded (in which case memory data is newer than database).
      Set<Edge<Source?>> res = {};
      for (final op in ops) {
        if (!edges.containsKey(op.edgeId)) res.add(loadEdge(op, null));
      }
      for (final edge in edgesTo.findAll(id)) {
        if (edge.label == label) res.add(edge);
      }
      // Establish exhaustive backlink.
      edgesToWithLabel[(id, label)]?.load(res);
      return res;
    });
  }

  /// Starts tracking backlink. Note that this does not actually load the link.
  Backlink startTrackingBacklink(int id, int label, Source source) {
    final key = (id, label);
    assert(!edgesToWithLabel.containsKey(key));
    return edgesToWithLabel[key] = Backlink(id, label, source);
  }

  /// Stops tracking backlink.
  void stopTrackingBacklink(Backlink backlink) {
    final key = (backlink.id, backlink.label);
    assert(edgesToWithLabel.containsKey(key));
    edgesToWithLabel.remove(key);
  }

  @override
  void registerAtom(Atom<Source?> atom, bool created) {
    atomsOf.add(atom.srcId, atom);
    if (created) atom.payload?.notify();
  }

  @override
  void unregisterAtom(Atom<Source?> atom, bool removed) {
    atomsOf.remove(atom.srcId, atom);
    if (removed) atom.payload?.notify();
  }

  @override
  void updateAtom(Atom<Source?> atom, String prev, String curr) {
    atom.payload?.notify();
  }

  @override
  void registerEdge(Edge<Source?> edge, bool created) {
    edgesFrom.add(edge.srcId, edge);
    edgesTo.add(edge.dstId, edge);
    edgesToWithLabel[(edge.dstId, edge.label)]?.add(edge);
    if (created) edge.payload?.notify();
  }

  @override
  void unregisterEdge(Edge<Source?> edge, bool removed) {
    edgesFrom.remove(edge.srcId, edge);
    edgesTo.remove(edge.dstId, edge);
    edgesToWithLabel[(edge.dstId, edge.label)]?.remove(edge);
    // Unloading an edge causes backlink to be no longer exhaustive.
    if (!removed) edgesToWithLabel[(edge.dstId, edge.label)]?.unload();
    if (removed) edge.payload?.notify();
  }

  @override
  void updateEdge(Edge<Source?> edge, int prevSrc, int currSrc, int prevDst, int currDst) {
    if (prevSrc != currSrc) {
      edgesFrom.remove(prevSrc, edge);
      edgesFrom.add(currSrc, edge);
    }
    if (prevDst != currDst) {
      edgesTo.remove(prevDst, edge);
      edgesTo.add(currDst, edge);
      edgesToWithLabel[(prevDst, edge.label)]?.remove(edge);
      edgesToWithLabel[(currDst, edge.label)]?.add(edge);
    }
    edge.payload?.notify();
  }
}
