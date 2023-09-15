import 'dart:ffi';

import 'package:beacons/ffi.dart';
import 'package:beacons/store.dart';
import 'package:beacons/serializer.dart';
import 'package:beacons/annotations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:integration_test/integration_test.dart';

part 'integration_test.g.dart';

const int kIntMin = -9223372036854775808;

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

  @Serializable(StringSerializer())
  final Atom<String> atomOne;

  @Serializable(StringSerializer())
  final AtomOption<String> atomTwo;

  final Link<Trivial> linkOne;

  final LinkOption<Trivial> linkTwo;

  final Multilinks<Something> linkThree;

  @Backlink('linkThree')
  final Backlinks<Something> backlink;

  @Transient()
  int someNonPersistentField = 233;

  Something._(this.id, this.atomOne, this.atomTwo, this.linkOne, this.linkTwo, this.linkThree, this.backlink);

  factory Something.create({
    required String atomOne,
    String? atomTwo,
    required Trivial linkOne,
    Trivial? linkTwo,
  }) =>
      const $SomethingRepository().create(atomOne, atomTwo, linkOne, linkTwo);

  void delete() => const $SomethingRepository().delete(this);
}

/// These tests must be run with native binaries bundled alongside.
/// This can be done with `flutter test integration_test`.
void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialisation.
  final dir = await getTemporaryDirectory();
  Store.initialize('${dir.path}/data.sqlite3');

  test('native_param_passing', () {
    final bindings = getNativeBindings();

    final id = Id.fromNative(bindings.test_id());
    assert(id == const Id(233, 666));

    final uid = Id.fromNative(bindings.test_id_unsigned());
    assert(uid == const Id(kIntMin + 233, kIntMin + 666));

    final arrayUint8 = bindings.test_array_u8();
    assert(arrayUint8.len == 5 && listEquals(arrayUint8.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
    bindings.drop_array_u8(arrayUint8);

    final arrayIdId = bindings.test_array_id_id();
    assert(arrayIdId.len == 2);
    {
      final first = arrayIdId.ptr.elementAt(0).ref;
      final second = arrayIdId.ptr.elementAt(1).ref;
      assert(Id.fromNative(first.first) == id && Id.fromNative(first.second) == uid);
      assert(Id.fromNative(second.first) == const Id(0, 1));
      assert(Id.fromNative(second.second) == const Id(1, 0));
    }
    bindings.drop_array_id_id(arrayIdId);

    final arrayIdUint64Id = bindings.test_array_id_u64_id();
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

    final atomSome = bindings.test_option_atom_some();
    assert(atomSome.tag == 1 &&
        Id.fromNative(atomSome.some.src) == id &&
        atomSome.some.label == kIntMin + 1 &&
        listEquals(atomSome.some.value.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
    bindings.drop_option_atom(atomSome);

    final atomNone = bindings.test_option_atom_none();
    assert(atomNone.tag == 0);
    bindings.drop_option_atom(atomSome);

    final edgeSome = bindings.test_option_edge_some();
    assert(edgeSome.tag == 1 &&
        Id.fromNative(edgeSome.some.src) == id &&
        edgeSome.some.label == kIntMin + 2 &&
        Id.fromNative(edgeSome.some.dst) == uid);

    final edgeNone = bindings.test_option_edge_none();
    assert(edgeNone.tag == 0);

    final arrayEventData = bindings.test_array_event_data();
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
  });

  /*
  test('native_dropping', () {
    final bindings = getNativeBindings();

    for (var i = 0; i < 10; i++) {
      final arrayUint8 = bindings.test_array_u8_big(32000000); // 32MB
      bindings.drop_array_u8(arrayUint8);
      final arrayEventData = bindings.test_array_event_data_big(10, 1600000); // 32MB
      bindings.drop_array_event_data(arrayEventData);
    }
  });
  */

  test('object_store', () {
    final store = Store.instance;
    final id0 = store.randomId();
    final id1 = store.randomId();
    store.setAtom(id0, (id0, 233, 666, const Int64Serializer()));
    store.setAtom(id1, (id1, 2333, 6666, const Int64Serializer()));
    store.setEdge(store.randomId(), (id0, 23333, id1));
    store.getAtomById(id0, (slv) {
      final (src, label, value) = slv!;
      assert(src == id0 && label == 233 && const Int64Serializer().deserialize(BytesReader(value)) == 666);
    });
    store.getAtomById(id1, (slv) {
      final (src, label, value) = slv!;
      assert(src == id1 && label == 2333 && const Int64Serializer().deserialize(BytesReader(value)) == 6666);
    });
    final edges = <(int, Id)>[];
    store.getEdgeLabelDstBySrc(id0, (id, label, dst) => edges.add((label, dst)));
    assert(edges.length == 1);
    assert(edges.single == (23333, id1));
  });

  test('object_store_wrapper', () {
    final trivial = Trivial.create();
    final trivialAgain = Trivial.create();

    final something = Something.create(atomOne: "test", atomTwo: "2333", linkOne: trivial, linkTwo: trivial);
    final somethingElse = Something.create(atomOne: "test", linkOne: trivial);
    somethingElse.linkThree.insert(something);

    final somethingCopy = const $SomethingRepository().get(something.id).get(null)!;
    final somethingElseCopy = const $SomethingRepository().get(somethingElse.id).get(null)!;

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

    something.delete();
    assert(const $SomethingRepository().get(something.id).get(null) == null);
    Store.instance.setAtom(somethingElse.atomOne.id, null);
    assert(const $SomethingRepository().get(somethingElse.id).get(null) == null);
  });
}
