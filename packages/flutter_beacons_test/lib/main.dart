import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_beacons/store.dart';
import 'package:flutter_beacons/serializer.dart';
import 'package:flutter_beacons/annotations.dart';
import 'package:path_provider/path_provider.dart';

import 'ffi.dart';

part 'main.g.dart';

const int kIntMin = -9223372036854775808;

int testHash(String name) {
  final ptr = name.toNativeUtf8(allocator: malloc);
  final res = Ffi.instance.beaconsBindings.make_label(ptr);
  malloc.free(ptr);
  return res;
}

List<int> testList() {
  return Ffi.instance.beaconsTestBindings.test_array_u8().ptr.asTypedList(5).toList();
}

void testFfiParamPassing() {
  final bindings = Ffi.instance.beaconsBindings;
  final testBindings = Ffi.instance.beaconsTestBindings;

  final id = Id.fromNative(testBindings.test_id());
  assert(id == const Id(233, 666));

  final uid = Id.fromNative(testBindings.test_id_unsigned());
  assert(uid == const Id(kIntMin + 233, kIntMin + 666));

  final arrayUint8 = testBindings.test_array_u8();
  assert(arrayUint8.len == 5 && listEquals(arrayUint8.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
  bindings.drop_array_u8(arrayUint8);

  final arrayIdId = testBindings.test_array_id_id();
  assert(arrayIdId.len == 2);
  {
    final first = arrayIdId.ptr.elementAt(0).ref;
    final second = arrayIdId.ptr.elementAt(1).ref;
    assert(Id.fromNative(first.first) == id && Id.fromNative(first.second) == uid);
    assert(Id.fromNative(second.first) == const Id(0, 1));
    assert(Id.fromNative(second.second) == const Id(1, 0));
  }
  bindings.drop_array_id_id(arrayIdId);

  final arrayIdUint64Id = testBindings.test_array_id_u64_id();
  assert(arrayIdUint64Id.len == 2);
  {
    final first = arrayIdUint64Id.ptr.elementAt(0).ref;
    final second = arrayIdUint64Id.ptr.elementAt(1).ref;
    assert(Id.fromNative(first.first) == id && first.second == 233 && Id.fromNative(first.third) == const Id(0, 1));
    assert(Id.fromNative(second.first) == const Id(1, 1) &&
        second.second == 234 &&
        Id.fromNative(second.third) == const Id(1, 0));
  }
  bindings.drop_array_id_u64_id(arrayIdUint64Id);

  final atomSome = testBindings.test_option_atom_some();
  assert(atomSome.tag == 1 &&
      Id.fromNative(atomSome.some.src) == id &&
      atomSome.some.label == kIntMin + 1 &&
      listEquals(atomSome.some.value.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
  bindings.drop_option_atom(atomSome);

  final atomNone = testBindings.test_option_atom_none();
  assert(atomNone.tag == 0);
  bindings.drop_option_atom(atomSome);

  final edgeSome = testBindings.test_option_edge_some();
  assert(edgeSome.tag == 1 &&
      Id.fromNative(edgeSome.some.src) == id &&
      edgeSome.some.label == kIntMin + 2 &&
      Id.fromNative(edgeSome.some.dst) == uid);

  final edgeNone = testBindings.test_option_edge_none();
  assert(edgeNone.tag == 0);

  final arrayEventData = testBindings.test_array_event_data();
  assert(arrayEventData.len == 2);
  final first = arrayEventData.ptr.elementAt(0).ref;
  assert(first.tag == 0);
  {
    final atom = first.union.atom;
    assert(Id.fromNative(atom.id) == const Id(0, 1));
    assert(atom.prev.tag == 1 && atom.curr.tag == 1);
    final prev = atom.prev.some, curr = atom.curr.some;
    assert(Id.fromNative(prev.src) == id &&
        prev.label == 5 &&
        prev.value.len == 2 &&
        listEquals(prev.value.ptr.asTypedList(2), [1, 13]));
    assert(Id.fromNative(curr.src) == uid &&
        curr.label == 6 &&
        curr.value.len == 2 &&
        listEquals(curr.value.ptr.asTypedList(2), [4, 34]));
  }
  final second = arrayEventData.ptr.elementAt(1).ref;
  assert(second.tag == 1);
  {
    final edge = second.union.edge;
    assert(Id.fromNative(edge.id) == const Id(1, 0));
    assert(edge.prev.tag == 1 && edge.curr.tag == 1);
    final prev = edge.prev.some, curr = edge.curr.some;
    assert(Id.fromNative(prev.src) == id && prev.label == 7 && Id.fromNative(prev.dst) == uid);
    assert(Id.fromNative(curr.src) == uid && curr.label == 8 && Id.fromNative(curr.dst) == id);
  }
  bindings.drop_array_event_data(arrayEventData);
}

void stressTestFfiDropping(int count) {
  final bindings = Ffi.instance.beaconsBindings;
  final testBindings = Ffi.instance.beaconsTestBindings;

  for (var i = 0; i < count; i++) {
    final arrayUint8 = testBindings.test_array_u8_big(256000000);
    bindings.drop_array_u8(arrayUint8);
    final arrayEventData = testBindings.test_array_event_data_big(10, 25600000);
    bindings.drop_array_event_data(arrayEventData);
  }
}

void testObjectStore() async {
  final store = Store.instance;
  final id0 = store.randomId();
  final id1 = store.randomId();
  store.setAtom(id0, (id0, 233, 666, const Int64Serializer()));
  store.setAtom(id1, (id1, 2333, 6666, const Int64Serializer()));
  store.setEdge(store.randomId(), (id0, 23333, id1));
  assert(store.getAtomById(id0, const Int64Serializer()) == (id0, 233, 666));
  assert(store.getAtomById(id1, const Int64Serializer()) == (id1, 2333, 6666));
  final edges = store.getEdgeLabelDstBySrc(id0);
  assert(edges.length == 1);
  assert(edges.single.$2 == (23333, id1));
}

const kStringSerializer = StringSerializer();

@Model()
class Trivial {
  final Id id;

  Trivial._(this.id);

  factory Trivial.create() => const $TrivialRepository().create();

  void delete() => const $TrivialRepository().delete(this);
}

@Model()
class Something {
  final Id id;

  @Serializable(kStringSerializer)
  final Atom<String> atomOne;

  @Serializable(kStringSerializer)
  final AtomOption<String> atomTwo;

  final Link<Trivial> linkOne;

  final LinkOption<Trivial> linkTwo;

  final Multilinks<Something> linkThree;

  @Backlink('linkThree')
  final Backlinks<Something> backlink;

  @Transient()
  int someNonPersistentField = 233;

  Something._(this.id, this.atomOne, this.atomTwo, this.linkOne, this.linkTwo, this.linkThree, this.backlink);

  factory Something.create({required String atomOne, String? atomTwo, required Trivial linkOne, Trivial? linkTwo}) =>
      const $SomethingRepository().create(atomOne, atomTwo, linkOne, linkTwo);

  void delete() => const $SomethingRepository().delete(this);
}

void testObjectStoreWrapper() async {
  final trivial = Trivial.create();
  final trivialAgain = Trivial.create();

  final something = Something.create(atomOne: "test", atomTwo: "2333", linkOne: trivial, linkTwo: trivial);
  final somethingElse = Something.create(atomOne: "test", linkOne: trivial);
  somethingElse.linkThree.insert(something);

  final somethingCopy = const $SomethingRepository().get(something.id)!;
  final somethingElseCopy = const $SomethingRepository().get(somethingElse.id)!;

  assert(somethingCopy.atomOne.get(null) == "test");
  assert(somethingCopy.atomTwo.get(null)! == "2333");
  assert(somethingCopy.linkOne.get(null).id == trivial.id);
  assert(somethingCopy.linkTwo.get(null)!.id == trivial.id);
  assert(somethingCopy.linkThree.get(null).isEmpty);

  assert(somethingElseCopy.atomOne.get(null) == "test");
  assert(somethingElseCopy.atomTwo.get(null) == null);
  assert(somethingElseCopy.linkOne.get(null).id == trivial.id);
  assert(somethingElseCopy.linkTwo.get(null) == null);
  assert(somethingElseCopy.linkThree.get(null).length == 1);
  assert(somethingElseCopy.linkThree.get(null).single.id == something.id);

  somethingCopy.atomTwo.set(null);
  assert(somethingCopy.atomTwo.get(null) == null);
  somethingCopy.atomTwo.set("gg");
  assert(somethingCopy.atomTwo.get(null)! == "gg");
  somethingCopy.linkTwo.set(null);
  assert(somethingCopy.linkTwo.get(null) == null);
  somethingCopy.linkTwo.set(trivialAgain);
  assert(somethingCopy.linkTwo.get(null)!.id == trivialAgain.id);

  assert(something.backlink.get(null).length == 1);
  something.linkThree.insert(something);
  assert(something.backlink.get(null).length == 2);
  something.linkThree.insert(something);
  assert(something.backlink.get(null).length == 3);
  something.linkThree.remove(something);
  assert(something.backlink.get(null).length == 2);
  somethingElse.linkThree.remove(something);
  assert(something.backlink.get(null).length == 1);
}

Future<bool> allTests() async {
  // Initialisation.
  final dir = await getApplicationDocumentsDirectory();
  Store.initialize(Ffi.instance.library, '${dir.path}/data.sqlite3');

  // Do tests.
  testFfiParamPassing();
  testObjectStore();
  testObjectStoreWrapper();
  return true;
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Tests'),
        ),
        body: Center(
          child: FutureBuilder(
            future: allTests(),
            builder: (context, snapshot) => snapshot.hasData && snapshot.data!
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      // Text('${fnv64Hash("hello")}'),
                      Text('${testHash("hello")}'),
                      Text('${testList()}'),
                      const Text('All tests passed!'),
                    ],
                  )
                : const CircularProgressIndicator.adaptive(),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MyApp());
}
