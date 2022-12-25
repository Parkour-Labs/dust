import 'package:qinhuai/graph/operation.dart';

import '../reactive/reactive.dart';
import 'graph.dart';
import 'model_repository.dart';

Model? Function(ModelRepository repo, int id, List<Atom<Source?>> atoms, List<Edge<Source?>> edges) constructorAdapter(
        Model Function(ModelRepository repo, int id, Map<int, Atom<Source?>> atoms, Map<int, Edge<Source?>> edges)
            constructor) =>
    (repo, id, atoms, edges) {
      Map<int, Atom<Source?>> atom1 = {};
      Map<int, Edge<Source?>> edge1 = {};
      for (final atom in atoms) {
        assert(!atom1.containsKey(atom.label), 'Multiple atoms with the same label.');
        atom1[atom.label] = atom;
      }
      for (final edge in edges) {
        assert(!edge1.containsKey(edge.label), 'Multiple edges with the same label.');
        edge1[edge.label] = edge;
      }
      return constructor(repo, id, atom1, edge1);
    };
