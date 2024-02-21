// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'integration_test.dart';

// **************************************************************************
// ModelRepositoryGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore, unused_local_variable, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types
// coverage:ignore-file

mixin _$Trivial {
  Id get id;
}

final class _Trivial extends Trivial {
  const _Trivial._(this.id) : super._();

  factory _Trivial() {
    final id = Dust.instance.randomId();
    return _Trivial._(id);
  }

  @override
  final Id id;
}

class $TrivialRepository implements Repository<Trivial> {
  const $TrivialRepository();

  static const int Label = 4898135217045869580;

  static final Map<Id, WeakReference<NodeOption<Trivial>>> $entries = {};

  static bool $init = false;

  @override
  Schema init() {
    $init = true;
    return const Schema(
      stickyNodes: [$TrivialRepository.Label],
      stickyAtoms: [],
      stickyEdges: [],
      acyclicEdges: [],
    );
  }

  @override
  Id id(Trivial $model) => $model.id;

  void $write(
    Id $id,
  ) {
    assert($init, 'Repository should be registered in `Store.open`.');
    final $store = Dust.instance;
    $store.setNode($id, $TrivialRepository.Label);

    $store.barrier();
  }

  Trivial create() {
    final $id = Dust.instance.randomId();
    final $node = get($id);
    $write(
      $id,
    );
    return $node.get(null)!;
  }

  NodeAuto<Trivial> auto(
    Id $id,
  ) {
    final $node = get($id);
    return NodeAuto(
      $node,
      () => $write(
        $id,
      ),
    );
  }

  @override
  NodeOption<Trivial> get(Id $id) {
    final $existing = $entries[$id]?.target;
    if ($existing != null) return $existing;
    final $model = _Trivial._($id);
    final $entry = NodeOption($id, $TrivialRepository.Label, $model);
    $entries[$id] = WeakReference($entry);
    return $entry;
  }

  @override
  void delete(Trivial $model) {
    assert($init, 'Repository should be registered in `Store.open`.');
    final $id = $model.id;
    final $store = Dust.instance;
    $entries.remove($id);
    $store.setNode($id, null);
    $store.barrier();
  }

  NodesByLabel<Trivial> all() =>
      NodesByLabel($TrivialRepository.Label, const $TrivialRepository());
}

// ignore_for_file: duplicate_ignore, unused_local_variable, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types
// coverage:ignore-file

class $SomethingRepository implements Repository<Something> {
  const $SomethingRepository();

  static const int Label = 1732646218406506219;
  static const int atomOneLabel = 2942696526831304012;
  static const int atomTwoLabel = 2947471705831678334;
  static const int linkOneLabel = 5826924555465856377;
  static const int linkTwoLabel = 5802991485859318103;
  static const int linkThreeLabel = 520405320243803301;

  static const atomOneSerializer = StringSerializer();
  static const atomTwoSerializer = StringSerializer();

  static final Map<Id, WeakReference<NodeOption<Something>>> $entries = {};

  static bool $init = false;

  @override
  Schema init() {
    $init = true;
    return const Schema(
      stickyNodes: [$SomethingRepository.Label],
      stickyAtoms: [$SomethingRepository.atomOneLabel],
      stickyEdges: [$SomethingRepository.linkOneLabel],
      acyclicEdges: [],
    );
  }

  @override
  Id id(Something $model) => $model.id;

  void $write(
    Id $id, {
    required String atomOne,
    String? atomTwo,
    required Trivial linkOne,
    Trivial? linkTwo,
  }) {
    assert($init, 'Repository should be registered in `Store.open`.');
    final $store = Dust.instance;
    $store.setNode($id, $SomethingRepository.Label);
    $store.setAtom(
      $id ^ $SomethingRepository.atomOneLabel,
      (
        $id,
        $SomethingRepository.atomOneLabel,
        atomOne,
        $SomethingRepository.atomOneSerializer,
      ),
    );
    if (atomTwo != null) {
      $store.setAtom(
        $id ^ $SomethingRepository.atomTwoLabel,
        (
          $id,
          $SomethingRepository.atomTwoLabel,
          atomTwo,
          $SomethingRepository.atomTwoSerializer,
        ),
      );
    }
    $store.setEdge(
      $id ^ $SomethingRepository.linkOneLabel,
      (
        $id,
        $SomethingRepository.linkOneLabel,
        linkOne.id,
      ),
    );
    if (linkTwo != null) {
      $store.setEdge(
        $id ^ $SomethingRepository.linkTwoLabel,
        (
          $id,
          $SomethingRepository.linkTwoLabel,
          linkTwo.id,
        ),
      );
    }

    $store.barrier();
  }

  Something create({
    required String atomOne,
    String? atomTwo,
    required Trivial linkOne,
    Trivial? linkTwo,
  }) {
    final $id = Dust.instance.randomId();
    final $node = get($id);
    $write(
      $id,
      atomOne: atomOne,
      atomTwo: atomTwo,
      linkOne: linkOne,
      linkTwo: linkTwo,
    );
    return $node.get(null)!;
  }

  NodeAuto<Something> auto(
    Id $id, {
    required String atomOne,
    String? atomTwo,
    required Trivial linkOne,
    Trivial? linkTwo,
  }) {
    final $node = get($id);
    return NodeAuto(
      $node,
      () => $write(
        $id,
        atomOne: atomOne,
        atomTwo: atomTwo,
        linkOne: linkOne,
        linkTwo: linkTwo,
      ),
    );
  }

  @override
  NodeOption<Something> get(Id $id) {
    final $existing = $entries[$id]?.target;
    if ($existing != null) return $existing;
    final $model = Something._(
      $id,
      atomOne: Atom<String>(
        $id ^ $SomethingRepository.atomOneLabel,
        $id,
        $SomethingRepository.atomOneLabel,
        $SomethingRepository.atomOneSerializer,
      ),
      atomTwo: AtomOption<String>(
        $id ^ $SomethingRepository.atomTwoLabel,
        $id,
        $SomethingRepository.atomTwoLabel,
        $SomethingRepository.atomTwoSerializer,
      ),
      linkOne: Link<Trivial>(
        $id ^ $SomethingRepository.linkOneLabel,
        $id,
        $SomethingRepository.linkOneLabel,
        const $TrivialRepository(),
      ),
      linkTwo: LinkOption<Trivial>(
        $id ^ $SomethingRepository.linkTwoLabel,
        $id,
        $SomethingRepository.linkTwoLabel,
        const $TrivialRepository(),
      ),
      linkThree: Multilinks<Something>(
        $id,
        $SomethingRepository.linkThreeLabel,
        const $SomethingRepository(),
      ),
      backlink: Backlinks<Something>(
        $id,
        $SomethingRepository.linkThreeLabel,
        const $SomethingRepository(),
      ),
    );
    final $entry = NodeOption($id, $SomethingRepository.Label, $model);
    $entries[$id] = WeakReference($entry);
    return $entry;
  }

  @override
  void delete(Something $model) {
    assert($init, 'Repository should be registered in `Store.open`.');
    final $id = $model.id;
    final $store = Dust.instance;
    $entries.remove($id);
    $store.setNode($id, null);
    $store.barrier();
  }

  NodesByLabel<Something> all() =>
      NodesByLabel($SomethingRepository.Label, const $SomethingRepository());
}
