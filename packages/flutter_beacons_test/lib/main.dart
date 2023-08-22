import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_beacons/serializer/serializer.dart';
import 'package:flutter_beacons/store/store.dart';
import 'package:path_provider/path_provider.dart';

import 'ffi.dart';

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

class Trivial implements Model {
  @override
  final Id id;

  Trivial._(this.id);

  static const int kLabel = 0 /* Calculated from fnv64Hash("Trivial") */;

  factory Trivial.create() => TrivialRepository.create();
}

class TrivialRepository implements Repository<Trivial> {
  const TrivialRepository._();

  static Trivial create() {
    final store = Store.instance;
    final id = store.randomId();

    // Create `Trivial`.
    store.setNode(id, Trivial.kLabel);

    /* (No code generated here) */

    // Return.
    return TrivialRepository.instance.get(id)!;
  }

  @override
  Trivial? get(Id? id) {
    if (id == null) return null;
    final store = Store.instance;

    // Variables for existing data.
    /* (No code generated here) */

    // Load existing data.
    if (store.getNode(id) == null) return null;
    /* (No code generated here) */

    // Pack together. Fail if a field is not found.
    return Trivial._(id /* (No code generated here) */);
  }

  static const instance = TrivialRepository._();
}

class Something implements Model {
  @override
  final Id id;
  final Atom<String> atomOne;
  final AtomOption<String> atomTwo;
  final Link<Trivial> linkOne;
  final LinkOption<Trivial> linkTwo;
  final Multilinks<Something> linkThree;
  final Backlinks<Something> backlink;

  Something._(this.id, this.atomOne, this.atomTwo, this.linkOne, this.linkTwo, this.linkThree, this.backlink);

  /*
  Serializers for more complex types can be generated, e.g:
  ```
  static const Serializer<Map<String, List<int>?>> serializer =
      MapSerializer(StringSerializer(), OptionSerializer(ListSerializer(IntSerializer())));
  ```
  */
  static const Serializer<String> kAtomOneSerializer = StringSerializer();
  static const Serializer<String> kAtomTwoSerializer = StringSerializer();

  static const int kLabel = 1 /* Calculated from fnv64Hash("Something") */;
  static const int kAtomOneLabel = 2 /* Calculated from fnv64Hash("Something.atomOne") */;
  static const int kAtomTwoLabel = 3 /* Calculated from fnv64Hash("Something.atomTwo") */;
  static const int kLinkOneLabel = 4 /* Calculated from fnv64Hash("Something.linkOne") */;
  static const int kLinkTwoLabel = 5 /* Calculated from fnv64Hash("Something.linkTwo") */;
  static const int kLinkThreeLabel = 6 /* Calculated from fnv64Hash("Something.linkThree") */;

  factory Something.create(String atomOne, String? atomTwo, Trivial linkOne, Trivial? linkTwo) =>
      SomethingRepository.instance.create(atomOne, atomTwo, linkOne, linkTwo);
}

class SomethingRepository implements Repository<Something> {
  const SomethingRepository._();

  Something create(String atomOne, String? atomTwo, Trivial linkOne, Trivial? linkTwo) {
    final store = Store.instance;
    final id = store.randomId();

    // Create `Something`.
    store.setNode(id, Something.kLabel);

    // Create `Something.atomOne`.
    final atomOneId = store.randomId();
    store.setEdge(store.randomId(), (id, Something.kAtomOneLabel, atomOneId));
    store.setAtom(Something.kAtomOneSerializer, atomOneId, atomOne);

    // Create `Something.atomTwo`.
    if (atomTwo == null) {
      store.setEdge(store.randomId(), (id, Something.kAtomTwoLabel, store.randomId()));
    } else {
      final atomTwoId = store.randomId();
      store.setEdge(store.randomId(), (id, Something.kAtomTwoLabel, atomTwoId));
      store.setAtom(Something.kAtomTwoSerializer, atomTwoId, atomTwo);
    }

    // Create `Something.linkOne`.
    store.setEdge(store.randomId(), (id, Something.kLinkOneLabel, linkOne.id));

    // Create `Something.linkTwo`.
    if (linkTwo == null) {
      store.setEdge(store.randomId(), (id, Something.kLinkTwoLabel, store.randomId()));
    } else {
      store.setEdge(store.randomId(), (id, Something.kLinkTwoLabel, linkTwo.id));
    }

    // Return.
    return SomethingRepository.instance.get(id)!;
  }

  @override
  Something? get(Id? id) {
    if (id == null) return null;
    final store = Store.instance;

    // Variables for existing data.
    Atom<String>? atomOne;
    AtomOption<String>? atomTwo;
    Link<Trivial>? linkOne;
    LinkOption<Trivial>? linkTwo;

    // Load existing data.
    if (store.getNode(id) == null) return null;
    for (final (edge, (_, label, dst)) in store.getEdgesBySrc(id)) {
      switch (label) {
        case Something.kAtomOneLabel:
          atomOne = store.getAtom(Something.kAtomOneSerializer, dst);
        case Something.kAtomTwoLabel:
          atomTwo = store.getAtomOption(Something.kAtomTwoSerializer, dst);
        case Something.kLinkOneLabel:
          linkOne = store.getLink(TrivialRepository.instance, edge);
        case Something.kLinkTwoLabel:
          linkTwo = store.getLinkOption(TrivialRepository.instance, edge);
      }
    }

    // Pack together. Fail if a field is not found.
    return Something._(
      id,
      atomOne!,
      atomTwo!,
      linkOne!,
      linkTwo!,
      store.getMultilinks(SomethingRepository.instance, id, Something.kLinkThreeLabel),
      store.getBacklinks(SomethingRepository.instance, id, Something.kLinkThreeLabel),
    );
  }

  static const instance = SomethingRepository._();
}

void testObjectStoreWrapper() async {
  final trivial = Trivial.create();
  final trivialAgain = Trivial.create();

  final something = Something.create("test", "2333", trivial, trivial);
  final somethingElse = Something.create("test", null, trivial, null);
  somethingElse.linkThree.insert(something);

  final somethingCopy = SomethingRepository.instance.get(something.id)!;
  final somethingElseCopy = SomethingRepository.instance.get(somethingElse.id)!;

  assert(somethingCopy.atomOne.peek() == "test");
  assert(somethingCopy.atomTwo.peek()! == "2333");
  assert(somethingCopy.linkOne.peek().id == trivial.id);
  assert(somethingCopy.linkTwo.peek()!.id == trivial.id);
  assert(somethingCopy.linkThree.peek().isEmpty);

  assert(somethingElseCopy.atomOne.peek() == "test");
  assert(somethingElseCopy.atomTwo.peek() == null);
  assert(somethingElseCopy.linkOne.peek().id == trivial.id);
  assert(somethingElseCopy.linkTwo.peek() == null);
  assert(somethingElseCopy.linkThree.peek().length == 1);
  assert(somethingElseCopy.linkThree.peek().single.id == something.id);

  somethingCopy.atomTwo.set(null);
  assert(somethingCopy.atomTwo.peek() == null);
  somethingCopy.atomTwo.set("gg");
  assert(somethingCopy.atomTwo.peek()! == "gg");
  somethingCopy.linkTwo.set(null);
  assert(somethingCopy.linkTwo.peek() == null);
  somethingCopy.linkTwo.set(trivialAgain);
  assert(somethingCopy.linkTwo.peek()!.id == trivialAgain.id);

  assert(something.backlink.peek().length == 1);
  something.linkThree.insert(something);
  assert(something.backlink.peek().length == 2);
  something.linkThree.insert(something);
  assert(something.backlink.peek().length == 3);
  something.linkThree.remove(something);
  assert(something.backlink.peek().length == 2);
  somethingElse.linkThree.remove(something);
  assert(something.backlink.peek().length == 1);
}

/*
Future<bool> allTests() async {
  final Completer<bool> completer = Completer();
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is bool) {
        completer.complete(data);
      } else {
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      }
    });

  // Do the tests in a separate isolate and send the results back.
  Isolate.spawn(
    (SendPort sendPort) async {
      testFfiParamPassing();
      // stressTestFfiDropping(10);
      sendPort.send(true);
    },
    receivePort.sendPort,
  );

  return completer.future;
}
*/

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
