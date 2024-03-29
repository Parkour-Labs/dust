import 'package:dust/dust.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:integration_test/integration_test.dart';

part 'integration_test.dust.dart';

const int kIntMin = -9223372036854775808;

@Model()
abstract class Trivial with _$Trivial {
  Trivial._();

  factory Trivial() = _Trivial;
}

@Model()
abstract class Something with _$Something {
  Something._();

  factory Something({
    required String atomOne,
    String? atomTwo,
    @Ln() required Trivial linkOne,
    @Ln() Trivial? linkTwo,
    @Ln() List<Something> linkThree,
    @Ln(backTo: 'linkThree') List<Something> backlink,
  }) = _Something;

  int someNonPersistentField = 0;
}

/// These tests must be run with native binaries bundled alongside.
/// This can be done with `flutter test integration_test`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('object_store', () {
    setUpAll(() async {
      final dir = await getTemporaryDirectory();
      Dust.open('${dir.path}/data.sqlite3', [
        const $TrivialRepository(),
        const $SomethingRepository(),
      ]);
    });

    tearDownAll(() {
      Dust.close();
    });

    test('object_store_no_barrier', () {
      final store = Dust.instance;
      final id0 = store.randomId();
      final id1 = store.randomId();
      store.setAtom(id0, (id0, 233, 666, const Int64Serializer()));
      store.setAtom(id1, (id1, 2333, 6666, const Int64Serializer()));
      store.setEdge(store.randomId(), (id0, 23333, id1));
      store.getAtomById(id0, (slv) {
        final (src, label, value) = slv!;
        assert(src == id0 &&
            label == 233 &&
            const Int64Serializer().deserialize(BytesReader(value)) == 666);
      });
      store.getAtomById(id1, (slv) {
        final (src, label, value) = slv!;
        assert(src == id1 &&
            label == 2333 &&
            const Int64Serializer().deserialize(BytesReader(value)) == 6666);
      });
      final edges = <(int, Id)>[];
      store.getEdgeLabelDstBySrc(
          id0, (id, label, dst) => edges.add((label, dst)));
      assert(edges.length == 1);
      assert(edges.single == (23333, id1));
    });

    test('object_store_wrapper', () {
      final trivial = Trivial();
      final trivialAgain = Trivial();

      final something = Something(
          atomOne: 'test', atomTwo: '2333', linkOne: trivial, linkTwo: trivial);
      final somethingElse = Something(atomOne: 'test', linkOne: trivial);
      somethingElse.linkThree$.insert(something);

      final somethingCopy =
          const $SomethingRepository().get(something.id).peek()!;
      final somethingElseCopy =
          const $SomethingRepository().get(somethingElse.id).peek()!;

      assert(somethingCopy.atomOne$.peek() == 'test');
      assert(somethingCopy.atomTwo$.peek()! == '2333');
      assert(somethingCopy.linkOne$.peek().id == trivial.id);
      assert(somethingCopy.linkTwo$.peek()!.id == trivial.id);
      assert(somethingCopy.linkThree$.peek().isEmpty);

      assert(somethingElseCopy.atomOne$.peek() == 'test');
      assert(somethingElseCopy.atomTwo$.peek() == null);
      assert(somethingElseCopy.linkOne$.peek().id == trivial.id);
      assert(somethingElseCopy.linkTwo$.peek() == null);
      assert(somethingElseCopy.linkThree$.peek().length == 1);
      assert(somethingElseCopy.linkThree$.peek().single.id == something.id);

      somethingCopy.atomTwo$.set(null);
      assert(somethingCopy.atomTwo$.peek() == null);
      somethingCopy.atomTwo$.set('gg');
      assert(somethingCopy.atomTwo$.peek()! == 'gg');
      somethingCopy.linkTwo$.set(null);
      assert(somethingCopy.linkTwo$.peek() == null);
      somethingCopy.linkTwo$.set(trivialAgain);
      assert(somethingCopy.linkTwo$.peek()!.id == trivialAgain.id);

      assert(something.backlink$.peek().length == 1);
      something.linkThree$.insert(something);
      assert(something.backlink$.peek().length == 2);
      something.linkThree$.insert(something);
      assert(something.backlink$.peek().length == 3);
      something.linkThree$.remove(something);
      assert(something.backlink$.peek().length == 2);
      somethingElse.linkThree$.remove(something);
      assert(something.backlink$.peek().length == 1);

      something.delete();
      assert(const $SomethingRepository().get(something.id).peek() == null);
      Dust.instance.setAtom(somethingElse.atomOne$.id, null);
      Dust.instance.barrier();
      assert(const $SomethingRepository().get(somethingElse.id).peek() == null);
    });

    test('object_store_perf', () {
      final something = Something(atomOne: '', linkOne: Trivial());
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < 100000; i++) {
        something.atomOne$.set('value: $i');
      }
      debugPrint('Elapsed: ${stopwatch.elapsed}');
    });
  });
}
