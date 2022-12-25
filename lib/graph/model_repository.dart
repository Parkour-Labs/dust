import 'dart:async';

import '../utils/pair.dart';
import '../reactive/reactive.dart';
import 'operation.dart';
import 'graph.dart';
import 'model_graph.dart';

class Model with Disposable {
  final int id;

  Model(this.id);
}

class ActiveAtom<T extends String?> with Disposable, Source {
  final ModelRepository repo;
  final int label;
  final Atom<Source?> atom;

  ActiveAtom(this.repo, this.label, this.atom) {
    assert(atom.payload == null, 'Only one source can be attached to an atom.');
    atom.payload = this;
  }

  @override
  void dispose() {
    super.dispose();
    clearDependents();
    assert(atom.payload == this);
    atom.payload = null;
  }

  T get(Ref? ref) {
    if (ref != null) addDependent(ref.sink);
    return (atom.removed ? null : atom.value) as T;
  }

  void set(T value) {
    if (value == null) {
      repo.graph.removeAtom(atom);
    } else {
      repo.graph.modifyAtom(atom, value);
    }
  }
}

class ActiveLink<T extends Model?> with Disposable, Source {
  final ModelRepository repo;
  final int dstLabel;
  final Edge<Source?> edge;

  ActiveLink(this.repo, this.dstLabel, this.edge) {
    assert(edge.payload == null, 'Only one source can be attached to an edge.');
    edge.payload = this;
  }

  @override
  void dispose() {
    super.dispose();
    clearDependents();
    assert(edge.payload == this);
    edge.payload = null;
  }

  /// Loads the target object if `absent`.
  FutureOr<T> load() {
    if (!isAbsent(null)) return get(null);
    return repo.load(edge.dstId, dstLabel).then((value) => get(null) /* value as T */);
  }

  bool isAbsent(Ref? ref) {
    if (ref != null) addDependent(ref.sink);
    return !edge.removed && !repo.models.containsKey(edge.dstId);
  }

  T get(Ref? ref) {
    assert(!isAbsent(null), 'Link must not be absent.');
    if (ref != null) addDependent(ref.sink);
    return (edge.removed ? null : repo.models[edge.dstId]) as T;
  }

  void set(T value) {
    if (value == null) {
      repo.graph.removeEdge(edge);
    } else {
      repo.graph.modifyEdge(edge, edge.srcId, value.id);
    }
  }
}

class ActiveBacklink<T extends Model?> with Disposable, Source {
  final ModelRepository repo;
  final int dstLabel;
  late final Backlink backlink;

  ActiveBacklink(this.repo, int id, int label, this.dstLabel) {
    backlink = repo.graph.startTrackingBacklink(id, label, this);
  }

  @override
  void dispose() {
    super.dispose();
    clearDependents();
    repo.graph.stopTrackingBacklink(backlink);
  }

  /// Loads the target objects if `absent`.
  FutureOr<Iterable<FutureOr<T>>> load() {
    if (!isAbsent(null)) return get(null);
    return repo.graph.loadEdgesToWithLabel(backlink.id, backlink.label).then((value) => get(null));
  }

  bool isAbsent(Ref? ref) {
    if (ref != null) addDependent(ref.sink);
    return backlink.edges == null;
  }

  Iterable<FutureOr<T>> get(Ref? ref) {
    assert(!isAbsent(null), 'Link must not be absent.');
    if (ref != null) addDependent(ref.sink);
    List<FutureOr<T>> res = [];
    for (final edge in backlink.edges!) {
      if (!edge.removed) {
        final found = repo.models[edge.srcId];
        if (found != null) {
          res.add(found as T);
        } else {
          res.add(repo.load(edge.srcId, dstLabel).then((value) => value as T));
        }
      }
    }
    return res;
  }
}

class ModelSchema {
  final Model? Function(ModelRepository repo, int id, List<Atom<Source?>> atoms, List<Edge<Source?>> edges) constructor;

  const ModelSchema(this.constructor);
}

class ModelRepository {
  final ModelGraph graph;
  final Map<int, ModelSchema> schemas;
  final Map<int, Model> models = {};

  ModelRepository(this.graph, this.schemas);

  /// Loads a model object with given [id], or `null` if object does not exist / is not well-formed.
  /// Returns asynchronously.
  Future<Model?> load(int id, int label) async {
    final res = await graph.loadAtomsAndEdgesFrom(id);
    final atoms = res.first;
    final edges = res.second;
    final model = models[id] ?? schemas[label]!.constructor(this, id, atoms, edges);
    if (model == null) {
      assert(atoms.isEmpty && edges.isEmpty, 'Data exist but are not well-formed.');
      return null;
    }
    return models[id] = model;
  }

  /// Unloads and disposes [model], then waits for all atoms and edges to be saved.
  /// Returns asynchronously.
  Future<void> unload(Model model) {
    final id = model.id;
    models.remove(id);
    model.dispose();
    List<Future<void>> futures = [];
    for (final atom in List.of(graph.atomsOf.findAll(id))) {
      futures.add(graph.unloadAtom(atom));
    }
    for (final edge in List.of(graph.edgesFrom.findAll(id))) {
      if (models.containsKey(edge.dstId)) {
        edge.payload?.notify();
      } else {
        futures.add(graph.unloadEdge(edge));
      }
    }
    for (final edge in List.of(graph.edgesTo.findAll(id))) {
      if (models.containsKey(edge.srcId)) {
        edge.payload?.notify();
      } else {
        futures.add(graph.unloadEdge(edge));
      }
    }
    return Future.wait(futures);
  }

  /// Creates a new model with given parameters, or `null` if creation failed / parameters are not well-formed.
  /// Returns synchronously. Async write operations are queued.
  Model? add(int label, List<Pair<int, String?>> labelValues, List<Pair<int, Model?>> labelDsts) {
    final id = Identifier.random();
    final atoms = labelValues.map((e) => graph.addAtom(e.first, id, e.second, null)).toList();
    final edges = labelDsts.map((e) => graph.addEdge(e.first, id, e.second?.id, null)).toList();
    final model = schemas[label]!.constructor(this, id, atoms, edges);
    if (model == null) {
      assert(false, 'Data passed in from constructor are not well-formed.');
      return null;
    }
    return models[id] = model;
  }
}
