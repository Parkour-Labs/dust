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

  final edge = testBindings.test_edge();
  assert(Id.fromNative(edge.src) == id && edge.label == -kIntMin + 1 && Id.fromNative(edge.dst) == uid);

  final arrayUint8 = testBindings.test_array_u8();
  assert(arrayUint8.len == 5 && listEquals(arrayUint8.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
  bindings.drop_array_u8(arrayUint8);

  final arrayPairIdId = testBindings.test_array_pair_id_id();
  assert(arrayPairIdId.len == 2);
  {
    final first = arrayPairIdId.ptr.elementAt(0).ref;
    final second = arrayPairIdId.ptr.elementAt(1).ref;
    assert(Id.fromNative(first.first) == id && Id.fromNative(first.second) == uid);
    assert(Id.fromNative(second.first) == const Id(0, 1));
    assert(Id.fromNative(second.second) == const Id(1, 0));
  }
  bindings.drop_array_id_id(arrayPairIdId);

  final arrayPairIdEdge = testBindings.test_array_pair_id_edge();
  assert(arrayPairIdEdge.len == 2);
  {
    final first = arrayPairIdEdge.ptr.elementAt(0).ref;
    final second = arrayPairIdEdge.ptr.elementAt(1).ref;
    assert(Id.fromNative(first.first) == id);
    assert(Id.fromNative(first.second.src) == Id.fromNative(edge.src) &&
        first.second.label == edge.label &&
        Id.fromNative(first.second.dst) == Id.fromNative(edge.dst));
    assert(Id.fromNative(second.first) == const Id(1, 1));
    assert(Id.fromNative(second.second.src) == const Id(0, 1) &&
        second.second.label == 1 &&
        Id.fromNative(second.second.dst) == const Id(1, 0));
  }
  bindings.drop_array_id_edge(arrayPairIdEdge);

  final optionNone = testBindings.test_option_u64_none();
  assert(optionNone.tag == 0);

  final optionUint64 = testBindings.test_option_u64_some();
  assert(optionUint64.tag == 1 && optionUint64.some == 233);

  final optionArrayUint8 = testBindings.test_option_array_u8_some();
  assert(optionArrayUint8.tag == 1 &&
      optionArrayUint8.some.len == 5 &&
      listEquals(optionArrayUint8.some.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
  bindings.drop_option_array_u8(optionArrayUint8);

  final optionEdge = testBindings.test_option_edge_some();
  assert(optionEdge.tag == 1 &&
      Id.fromNative(optionEdge.some.src) == id &&
      optionEdge.some.label == -kIntMin + 1 &&
      Id.fromNative(optionEdge.some.dst) == uid);

  final arrayPairUint64EventData = testBindings.test_array_pair_u64_event_data();
  assert(arrayPairUint64EventData.len == 7);
  {
    for (var i = 0; i < 7; i++) {
      assert(arrayPairUint64EventData.ptr.elementAt(i).ref.first == i + 1);
      assert(arrayPairUint64EventData.ptr.elementAt(i).ref.second.tag == i);
    }
    final node = arrayPairUint64EventData.ptr.elementAt(0).ref.second.union.node;
    assert(node.tag == 1 && node.some == 233);
    final atom = arrayPairUint64EventData.ptr.elementAt(1).ref.second.union.atom;
    assert(atom.tag == 1 && atom.some.len == 5 && listEquals(atom.some.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
    final edge = arrayPairUint64EventData.ptr.elementAt(2).ref.second.union.edge;
    assert(edge.tag == 1 &&
        Id.fromNative(edge.some.src) == id &&
        edge.some.label == -kIntMin + 1 &&
        Id.fromNative(edge.some.dst) == uid);
    final multiedgeInsert = arrayPairUint64EventData.ptr.elementAt(3).ref.second.union.multiedgeInsert;
    assert(Id.fromNative(multiedgeInsert.first) == id && Id.fromNative(multiedgeInsert.second) == uid);
    final multiedgeRemove = arrayPairUint64EventData.ptr.elementAt(4).ref.second.union.multiedgeRemove;
    assert(Id.fromNative(multiedgeRemove.first) == uid && Id.fromNative(multiedgeRemove.second) == id);
    final backedgeInsert = arrayPairUint64EventData.ptr.elementAt(5).ref.second.union.backedgeInsert;
    assert(Id.fromNative(backedgeInsert.first) == id && Id.fromNative(backedgeInsert.second) == uid);
    final backedgeRemove = arrayPairUint64EventData.ptr.elementAt(6).ref.second.union.backedgeRemove;
    assert(Id.fromNative(backedgeRemove.first) == uid && Id.fromNative(backedgeRemove.second) == id);
  }
  bindings.drop_array_u64_event_data(arrayPairUint64EventData);
}

void stressTestFfiDropping(int count) {
  final bindings = Ffi.instance.beaconsBindings;
  final testBindings = Ffi.instance.beaconsTestBindings;

  for (var i = 0; i < count; i++) {
    final arrayUint8 = testBindings.test_array_u8_big(256000000);
    bindings.drop_array_u8(arrayUint8);
    final arrayPairUint64EventData = testBindings.test_array_pair_u64_event_data_big(10, 25600000);
    bindings.drop_array_u64_event_data(arrayPairUint64EventData);
  }
}

void testObjectStore() async {
  final store = Store.instance;
  final id0 = store.randomId();
  final id1 = store.randomId();
  store.setNode(id0, 233);
  store.setNode(id1, 2333);
  store.setEdge(store.randomId(), (id0, 23333, id1));
  assert(store.getNode(id0) == 233);
  assert(store.getNode(id1) == 2333);
  final edges = store.getEdgesBySrc(id0);
  assert(edges.length == 1);
  assert(edges.single.$2 == (id0, 23333, id1));
}

const _kStringSerializer = StringSerializer();

@Model()
class Trivial {
  final Id id;

  Trivial._(this.id);

  factory Trivial.create() => const $TrivialRepository().create();
}

@Model()
class Something {
  final Id id;

  @Serializable(_kStringSerializer)
  final Atom<String> atomOne;

  @Serializable(_kStringSerializer)
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
