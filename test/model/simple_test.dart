import 'package:path_provider/path_provider.dart';
import 'package:isar/isar.dart';
import 'package:test/test.dart';
import 'package:qinhuai/qinhuai.dart';

// Unique IDs for the class and its fields.
final int kNodeId = stableHash(r'Node');
final int kNodeNameId = stableHash(r'Node.name');
final int kNodeDataId = stableHash(r'Node.data');
final int kNodeParentId = stableHash(r'Node.parent');

// The model class.
class Node extends Model {
  final ActiveAtom<String> name;
  final ActiveAtom<String?> data;
  final ActiveLink<Node?> parent;
  final ActiveBacklink<Node> children;

  // Internal constructor.
  Node._(ModelRepository repo, int id, Map<int, Atom<Source?>> atoms, Map<int, Edge<Source?>> edges)
      : name = ActiveAtom(repo, atoms[kNodeNameId] ?? repo.graph.addAtom(kNodeNameId, id, '', null)),
        data = ActiveAtom(repo, atoms[kNodeDataId] ?? repo.graph.addAtom(kNodeDataId, id, null, null)),
        parent = ActiveLink(repo, kNodeId, edges[kNodeParentId] ?? repo.graph.addEdge(kNodeParentId, id, null, null)),
        children = ActiveBacklink(repo, kNodeId, id, kNodeParentId),
        super(id);

  @override
  void dispose() {
    super.dispose();
    disposes([name, data, parent, children]);
  }

  // Public constructor.
  factory Node(String name, String? data, Node? parent) =>
      models.add(kNodeId, [(kNodeNameId, name), (kNodeDataId, data)], [(kNodeParentId, parent)]) as Node;
}

// Schema for the class.
final ModelSchema kNodeSchema = ModelSchema(constructorAdapter(Node._));

// Global data store.
late Isar isar;
late ModelRepository models;

void main() {
  setUp(() async {
    // Initialise data store.
    final dir = await getApplicationDocumentsDirectory();
    await Isar.initializeIsarCore(download: true);
    isar = await Isar.open([GraphDataSchema, AtomOpSchema, EdgeOpSchema], directory: dir.path);
    models = ModelRepository(ModelGraph(isar, 0), {kNodeId: kNodeSchema});
  });

  tearDown(() async {
    await isar.close(deleteFromDisk: true);
  });

  test('Simple test', () async {
    // Test initialisation.
    final root = Node('root', 'gg', null);
    final child1 = Node('child1', null, root);
    final child2 = Node('child2', 'gggg', root);
    final child3 = Node('child3', 'ggggg', root);

    await root.children.load();
    assert(root.parent.get(null) == null);
    await child1.children.load();
    assert(child1.parent.get(null) == root);
    await child2.children.load();
    assert(child2.parent.get(null) == root);
    await child3.children.load();
    assert(child3.parent.get(null) == root);

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

    await models.unload(newChild1);
    await models.unload(newChild2);
    await models.unload(newChild3);
    await models.unload(newRoot);
    assert(models.graph.atoms.isEmpty && models.graph.edges.isEmpty);
  });
}
