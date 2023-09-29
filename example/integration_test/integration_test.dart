import 'dart:ffi';

import 'package:qinhuai/ffi.dart';
import 'package:qinhuai/reactive.dart';
import 'package:qinhuai/store.dart';
import 'package:qinhuai/serializer.dart';
import 'package:qinhuai/annotations.dart';
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

  Something._(
    this.id, {
    required this.atomOne,
    required this.atomTwo,
    required this.linkOne,
    required this.linkTwo,
    required this.linkThree,
    required this.backlink,
  });

  factory Something.create({
    required String atomOne,
    String? atomTwo,
    required Trivial linkOne,
    Trivial? linkTwo,
  }) =>
      const $SomethingRepository().create(
        atomOne: atomOne,
        atomTwo: atomTwo,
        linkOne: linkOne,
        linkTwo: linkTwo,
      );

  void delete() => const $SomethingRepository().delete(this);
}

/// These tests must be run with native binaries bundled alongside.
/// This can be done with `flutter test integration_test`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('native_param_passing', () {
    final bindings = getNativeBindings();

    final id = Id.fromNative(bindings.qinhuai_test_id());
    assert(id == const Id(233, 666));

    final uid = Id.fromNative(bindings.qinhuai_test_id_unsigned());
    assert(uid == const Id(kIntMin + 233, kIntMin + 666));

    final arrayUint8 = bindings.qinhuai_test_array_u8();
    assert(arrayUint8.len == 5 && listEquals(arrayUint8.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
    bindings.qinhuai_drop_array_u8(arrayUint8);

    final arrayIdId = bindings.qinhuai_test_array_id_id();
    assert(arrayIdId.len == 2);
    {
      final first = arrayIdId.ptr.elementAt(0).ref;
      final second = arrayIdId.ptr.elementAt(1).ref;
      assert(Id.fromNative(first.first) == id && Id.fromNative(first.second) == uid);
      assert(Id.fromNative(second.first) == const Id(0, 1));
      assert(Id.fromNative(second.second) == const Id(1, 0));
    }
    bindings.qinhuai_drop_array_id_id(arrayIdId);

    final arrayIdUint64Id = bindings.qinhuai_test_array_id_u64_id();
    assert(arrayIdUint64Id.len == 2);
    {
      final first = arrayIdUint64Id.ptr.elementAt(0).ref;
      final second = arrayIdUint64Id.ptr.elementAt(1).ref;
      assert(Id.fromNative(first.first) == id && first.second == 233 && Id.fromNative(first.third) == const Id(0, 1));
      assert(Id.fromNative(second.first) == const Id(1, 1) &&
          second.second == 234 &&
          Id.fromNative(second.third) == const Id(1, 0));
    }
    bindings.qinhuai_drop_array_id_u64_id(arrayIdUint64Id);

    final atomSome = bindings.qinhuai_test_option_atom_some();
    assert(atomSome.tag == 1 &&
        Id.fromNative(atomSome.some.src) == id &&
        atomSome.some.label == kIntMin + 1 &&
        listEquals(atomSome.some.value.ptr.asTypedList(5), [1, 2, 3, 233, 234]));
    bindings.qinhuai_drop_option_atom(atomSome);

    final atomNone = bindings.qinhuai_test_option_atom_none();
    assert(atomNone.tag == 0);
    bindings.qinhuai_drop_option_atom(atomSome);

    final edgeSome = bindings.qinhuai_test_option_edge_some();
    assert(edgeSome.tag == 1 &&
        Id.fromNative(edgeSome.some.src) == id &&
        edgeSome.some.label == kIntMin + 2 &&
        Id.fromNative(edgeSome.some.dst) == uid);

    final edgeNone = bindings.qinhuai_test_option_edge_none();
    assert(edgeNone.tag == 0);

    final unit = bindings.qinhuai_test_result_unit_ok();
    assert(unit.dummy == 0);
    try {
      bindings.qinhuai_test_result_unit_err();
      assert(false);
    } on NativeError catch (err) {
      assert(err.toString() == 'message');
    }

    final arrayEventData = bindings.qinhuai_test_array_event_data();
    assert(arrayEventData.len == 2);
    final first = arrayEventData.ptr.elementAt(0).ref;
    assert(first.tag == 1);
    {
      final atom = first.body.atom;
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
    assert(second.tag == 2);
    {
      final edge = second.body.edge;
      assert(Id.fromNative(edge.id) == const Id(1, 0));
      assert(edge.prev.tag == 1 && edge.curr.tag == 1);
      final prev = edge.prev.some, curr = edge.curr.some;
      assert(Id.fromNative(prev.src) == id && prev.label == 7 && Id.fromNative(prev.dst) == uid);
      assert(Id.fromNative(curr.src) == uid && curr.label == 8 && Id.fromNative(curr.dst) == id);
    }
    bindings.qinhuai_drop_array_event_data(arrayEventData);
  });

  test('native_dropping', () {
    final bindings = getNativeBindings();
    for (var i = 0; i < 10; i++) {
      final arrayUint8 = bindings.qinhuai_test_array_u8_big(32000000); // 32MB
      bindings.qinhuai_drop_array_u8(arrayUint8);
      final arrayEventData = bindings.qinhuai_test_array_event_data_big(10, 1600000); // 32MB
      bindings.qinhuai_drop_array_event_data(arrayEventData);
    }
  });

  group('object_store', () {
    setUpAll(() async {
      final dir = await getTemporaryDirectory();
      Store.open('${dir.path}/data.sqlite3', [
        const $TrivialRepository(),
        const $SomethingRepository(),
      ]);
    });

    tearDownAll(() {
      Store.close();
    });

    test('object_store_no_barrier', () {
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

      final something = Something.create(atomOne: 'test', atomTwo: '2333', linkOne: trivial, linkTwo: trivial);
      final somethingElse = Something.create(atomOne: 'test', linkOne: trivial);
      somethingElse.linkThree.insert(something);

      final somethingCopy = const $SomethingRepository().get(something.id).peek()!;
      final somethingElseCopy = const $SomethingRepository().get(somethingElse.id).peek()!;

      assert(somethingCopy.atomOne.peek() == 'test');
      assert(somethingCopy.atomTwo.peek()! == '2333');
      assert(somethingCopy.linkOne.peek().id == trivial.id);
      assert(somethingCopy.linkTwo.peek()!.id == trivial.id);
      assert(somethingCopy.linkThree.peek().isEmpty);

      assert(somethingElseCopy.atomOne.peek() == 'test');
      assert(somethingElseCopy.atomTwo.peek() == null);
      assert(somethingElseCopy.linkOne.peek().id == trivial.id);
      assert(somethingElseCopy.linkTwo.peek() == null);
      assert(somethingElseCopy.linkThree.peek().length == 1);
      assert(somethingElseCopy.linkThree.peek().single.id == something.id);

      somethingCopy.atomTwo.set(null);
      assert(somethingCopy.atomTwo.peek() == null);
      somethingCopy.atomTwo.set('gg');
      assert(somethingCopy.atomTwo.peek()! == 'gg');
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

      something.delete();
      assert(const $SomethingRepository().get(something.id).peek() == null);
      Store.instance.setAtom(somethingElse.atomOne.id, null);
      Store.instance.barrier();
      assert(const $SomethingRepository().get(somethingElse.id).peek() == null);
    });

    test('object_store_perf', () {
      final something = Something.create(atomOne: '', linkOne: Trivial.create());
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 100000; i++) {
        something.atomOne.set('value: $i');
      }
      debugPrint('Elapsed: ${stopwatch.elapsed}');
    });
  });
}
