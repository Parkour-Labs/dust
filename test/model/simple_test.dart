import 'dart:async';

import 'package:isar/isar.dart';
import 'package:test/test.dart';
import 'package:qinhuai/qinhuai.dart';

// The model class.
class Node extends Model {
  final ActiveAtom<String> name;
  final ActiveAtom<String?> data;
  final ActiveLink<Node?> parent;
  final ActiveBacklink<Node> children;

  // Internal constructor.
  Node._(ModelRepository repo, int id, Map<int, Atom<Source?>> atoms, Map<int, Edge<Source?>> edges)
      : name = ActiveAtom(repo, 0, atoms[0] ?? repo.graph.addAtom(0, id, '', null)),
        data = ActiveAtom(repo, 1, atoms[1] ?? repo.graph.addAtom(1, id, null, null)),
        parent = ActiveLink(repo, kNodeTypeId, edges[0] ?? repo.graph.addEdge(0, id, null, null)),
        children = ActiveBacklink(repo, id, 0, kNodeTypeId),
        super(id);

  @override
  void dispose() {
    super.dispose();
    disposes([name, data, parent, children]);
  }

  // Public constructor.
  factory Node(
    String name,
    String? data,
    Node? parent,
  ) =>
      models.add(kNodeTypeId, [Pair(0, name), Pair(1, data)], [Pair(0, parent)]) as Node;
}

// Unique ID for the class.
const int kNodeTypeId = 2333;

// Schema for the class.
final ModelSchema kNodeSchema = ModelSchema(constructorAdapter(Node._));

/// The global [Isar] instance.
late final Isar isar;

/// The global [ModelRepository] instance.
late final ModelRepository models;

Future<void> main() async {
  await Isar.initializeIsarCore(download: true);

  // Initialise data store.
  isar = await Isar.open([GraphDataSchema, AtomOpSchema, EdgeOpSchema]);
  models = ModelRepository(ModelGraph(isar, 0), {kNodeTypeId: kNodeSchema});

  test('Simple test', () async {
    // Test initialisation.
    final root = Node('root', 'gg', null);
    final child1 = Node('child1', null, root);
    final child2 = Node('child2', 'gggg', root);
    final child3 = Node('child3', 'ggggg', root);
    await root.children.load();
    assert(root.parent.get(null) == null && root.children.get(null).length == 3);
    await child1.children.load();
    assert(child1.parent.get(null) == root && child1.children.get(null).isEmpty);
    await child2.children.load();
    assert(child2.parent.get(null) == root && child2.children.get(null).isEmpty);
    await child3.children.load();
    assert(child3.parent.get(null) == root && child3.children.get(null).isEmpty);

    // Test reactives.
    final reactive = Reactive((ref) => '${child2.name.get(ref)}-decorated');
    assert(child2.name.get(null) == 'child2');
    assert(reactive.get(null) == 'child2-decorated');
    child2.name.set('child2-new');
    assert(child2.name.get(null) == 'child2-new');
    assert(reactive.get(null) == 'child2-new-decorated');
    reactive.dispose();

    // Test links.
    child2.parent.set(child1);
    assert(child2.parent.get(null) == child1 && await child1.children.get(null).first == child2);
    child3.parent.set(child2);
    assert(child3.parent.get(null) == child2 && await child2.children.get(null).first == child3);
    assert(root.children.get(null).length == 1);
    assert((await root.children.load()).length == 1);

    // Test unloads.
    assert(root.parent.get(null) == null && !root.parent.isAbsent(null) && !root.children.isAbsent(null));
    assert(child1.parent.get(null) == root && !child1.parent.isAbsent(null) && !child1.children.isAbsent(null));
    assert(child2.parent.get(null) == child1 && !child2.parent.isAbsent(null) && !child2.children.isAbsent(null));
    assert(child3.parent.get(null) == child2 && !child3.parent.isAbsent(null) && !child3.children.isAbsent(null));

    await models.unload(root);
    assert(root.disposed);
    assert(child1.parent.isAbsent(null) && !child1.children.isAbsent(null));
    assert(child2.parent.get(null) == child1 && !child2.parent.isAbsent(null) && !child2.children.isAbsent(null));
    assert(child3.parent.get(null) == child2 && !child3.parent.isAbsent(null) && !child3.children.isAbsent(null));

    await models.unload(child3);
    assert(root.disposed);
    assert(child1.parent.isAbsent(null) && !child1.children.isAbsent(null));
    assert(child2.parent.get(null) == child1 && !child2.parent.isAbsent(null) && !child2.children.isAbsent(null));
    assert(child3.disposed);

    await models.unload(child2);
    assert(root.disposed);
    assert(child1.parent.isAbsent(null) && !child1.children.isAbsent(null));
    assert(child2.disposed);
    assert(child3.disposed);

    // Test loads and backlinks.
    await child1.parent.load();
    final newRoot = child1.parent.get(null)!;
    await child1.children.load();
    final newChild2 = await child1.children.get(null).single;
    assert(await child1.children.get(null).single == newChild2);
    assert(newChild2.parent.get(null) == child1 && newChild2.children.isAbsent(null));
    final newChild1 = await (await newRoot.children.load()).single;
    assert(newChild1 == child1);
    await newChild1.children.load();
    assert(await newChild1.children.get(null).single == newChild2);
    final newChild3 = await (await newChild2.children.load()).single;
    await newChild3.children.load();
    assert(newChild3.children.get(null).isEmpty);

    assert(newChild3.name.get(null) == 'child3' && newChild3.data.get(null) == 'ggggg');
    assert(newChild2.name.get(null) == 'child2-new' && newChild2.data.get(null) == 'gggg');
    assert(newChild1.name.get(null) == 'child1' && newChild1.data.get(null) == null);
    assert(newRoot.name.get(null) == 'root' && newRoot.data.get(null) == 'gg');

    assert(newChild3.parent.get(null) == newChild2 && !newChild3.parent.isAbsent(null));
    assert(newChild2.parent.get(null) == newChild1 && !newChild2.parent.isAbsent(null));
    assert(newChild1.parent.get(null) == newRoot && !newChild1.parent.isAbsent(null));
    // Expected. Empty links are never considered as "absent".
    assert(newRoot.parent.get(null) == null && !newRoot.parent.isAbsent(null));
  });
}
