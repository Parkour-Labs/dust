// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// ModelRepositoryGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore, unused_local_variable, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types
// coverage:ignore-file

class $TrivialRepository implements Repository<Trivial> {
  const $TrivialRepository();

  static final Map<Id, WeakReference<Ref<Trivial>>> refs = {};

  @override
  bool isComplete(Trivial $model) {
    return true;
  }

  void overwrite(
    Id $id,
  ) {
    final $store = Store.instance;
  }

  Ref<Trivial> create() {
    final $id = Store.instance.randomId();
    final $ref = get($id);
    overwrite(
      $id,
    );
    return $ref;
  }

  Ref<Trivial> init(
    Id $id,
  ) {
    final $ref = get($id);
    if (!isComplete($ref.model)) {
      overwrite(
        $id,
      );
    }
    return $ref;
  }

  @override
  Ref<Trivial> get(Id $id) {
    final $existing = refs[$id]?.target;
    if ($existing != null) return $existing;

    final $model = Trivial._();
    final $ref = Ref($id, $model, this);

    refs[$id] = WeakReference($ref);
    return $ref;
  }

  @override
  void delete(Id $id) {
    final $store = Store.instance;
    $store.getAtomLabelValueBySrc(
        $id, ($atom, $label, $value) => $store.setAtom($atom, null));
    $store.getEdgeLabelDstBySrc(
        $id, ($atom, $label, $dst) => $store.setAtom($atom, null));
    refs.remove($id);
  }
}

// ignore_for_file: duplicate_ignore, unused_local_variable, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types
// coverage:ignore-file

class $SomethingRepository implements Repository<Something> {
  const $SomethingRepository();

  static const int atomOneLabel = 2942696526831304012;
  static const int atomTwoLabel = 2947471705831678334;
  static const int linkOneLabel = 5826924555465856377;
  static const int linkTwoLabel = 5802991485859318103;
  static const int linkThreeLabel = 520405320243803301;

  static const atomOneSerializer = kStringSerializer;
  static const atomTwoSerializer = kStringSerializer;

  static final Map<Id, WeakReference<Ref<Something>>> refs = {};

  @override
  bool isComplete(Something $model) {
    return $model.atomOne.isComplete && $model.linkOne.isComplete && true;
  }

  void overwrite(
    Id $id,
    String atomOne,
    String? atomTwo,
    Ref<Trivial> linkOne,
    Ref<Trivial>? linkTwo,
  ) {
    final $store = Store.instance;
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
  }

  Ref<Something> create(
    String atomOne,
    String? atomTwo,
    Ref<Trivial> linkOne,
    Ref<Trivial>? linkTwo,
  ) {
    final $id = Store.instance.randomId();
    final $ref = get($id);
    overwrite(
      $id,
      atomOne,
      atomTwo,
      linkOne,
      linkTwo,
    );
    return $ref;
  }

  Ref<Something> init(
    Id $id,
    String atomOne,
    String? atomTwo,
    Ref<Trivial> linkOne,
    Ref<Trivial>? linkTwo,
  ) {
    final $ref = get($id);
    if (!isComplete($ref.model)) {
      overwrite(
        $id,
        atomOne,
        atomTwo,
        linkOne,
        linkTwo,
      );
    }
    return $ref;
  }

  @override
  Ref<Something> get(Id $id) {
    final $existing = refs[$id]?.target;
    if ($existing != null) return $existing;

    final $model = Something._(
      Atom<String>(
        $id ^ $SomethingRepository.atomOneLabel,
        $id,
        $SomethingRepository.atomOneLabel,
        $SomethingRepository.atomOneSerializer,
      ),
      AtomOption<String>(
        $id ^ $SomethingRepository.atomTwoLabel,
        $id,
        $SomethingRepository.atomTwoLabel,
        $SomethingRepository.atomTwoSerializer,
      ),
      Link<Trivial>(
        $id ^ $SomethingRepository.linkOneLabel,
        $id,
        $SomethingRepository.linkOneLabel,
        const $TrivialRepository(),
      ),
      LinkOption<Trivial>(
        $id ^ $SomethingRepository.linkTwoLabel,
        $id,
        $SomethingRepository.linkTwoLabel,
        const $TrivialRepository(),
      ),
      Multilinks<Something>(
        $id,
        $SomethingRepository.linkThreeLabel,
        const $SomethingRepository(),
      ),
      Backlinks<Something>(
        $id,
        $SomethingRepository.linkThreeLabel,
        const $SomethingRepository(),
      ),
    );
    final $ref = Ref($id, $model, this);
    $model.atomOne.parent = $ref;
    $model.linkOne.parent = $ref;

    refs[$id] = WeakReference($ref);
    return $ref;
  }

  @override
  void delete(Id $id) {
    final $store = Store.instance;
    $store.getAtomLabelValueBySrc(
        $id, ($atom, $label, $value) => $store.setAtom($atom, null));
    $store.getEdgeLabelDstBySrc(
        $id, ($atom, $label, $dst) => $store.setAtom($atom, null));
    refs.remove($id);
  }
}
