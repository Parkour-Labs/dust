// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// ModelRepositoryGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore, unused_local_variable, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types
// coverage:ignore-file

class $TrivialRepository implements Repository<Trivial> {
  const $TrivialRepository();

  static const int Label = 4898135217045869580;

  static final Map<Id, WeakReference<Trivial>> objects = {};

  Trivial createAt(
    Id id,
  ) {
    final $store = Store.instance;

    return get(id)!;
  }

  Trivial create() => createAt(
        Store.instance.randomId(),
      );

  Trivial getOrCreateAt(
    Id id,
  ) =>
      get(id) ??
      createAt(
        id,
      );

  void delete(Trivial object) {
    final $store = Store.instance;
    for (final ($atom, _) in $store.getAtomLabelBySrc(object.id)) {
      $store.setAtom($atom, null);
    }
    for (final ($edge, _) in $store.getEdgeLabelDstBySrc(object.id)) {
      $store.setEdge($edge, null);
    }
  }

  @override
  Id id(Trivial object) => object.id;

  @override
  Trivial? get(Id? id) {
    if (id == null) return null;
    final $object = objects[id]?.target;
    if ($object != null) return $object;
    final $store = Store.instance;

    for (final ($atom, $label) in $store.getAtomLabelBySrc(id)) {
      switch ($label) {}
    }
    for (final ($edge, ($label, _)) in $store.getEdgeLabelDstBySrc(id)) {
      switch ($label) {}
    }

    final $res = Trivial._(
      id,
    );

    objects[id] = WeakReference($res);
    return $res;
  }
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

  static const atomOneSerializer = kStringSerializer;
  static const atomTwoSerializer = kStringSerializer;

  static final Map<Id, WeakReference<Something>> objects = {};

  Something createAt(
    Id id,
    String atomOne,
    String? atomTwo,
    Trivial linkOne,
    Trivial? linkTwo,
  ) {
    final $store = Store.instance;

    $store.setAtom($store.randomId(), (
      id,
      $SomethingRepository.atomOneLabel,
      atomOne,
      $SomethingRepository.atomOneSerializer
    ));
    if (atomTwo != null) {
      $store.setAtom($store.randomId(), (
        id,
        $SomethingRepository.atomTwoLabel,
        atomTwo,
        $SomethingRepository.atomTwoSerializer
      ));
    }
    $store.setEdge(
        $store.randomId(), (id, $SomethingRepository.linkOneLabel, linkOne.id));
    if (linkTwo != null) {
      $store.setEdge($store.randomId(),
          (id, $SomethingRepository.linkTwoLabel, linkTwo.id));
    }

    return get(id)!;
  }

  Something create(
    String atomOne,
    String? atomTwo,
    Trivial linkOne,
    Trivial? linkTwo,
  ) =>
      createAt(
        Store.instance.randomId(),
        atomOne,
        atomTwo,
        linkOne,
        linkTwo,
      );

  Something getOrCreateAt(
    Id id,
    String atomOne,
    String? atomTwo,
    Trivial linkOne,
    Trivial? linkTwo,
  ) =>
      get(id) ??
      createAt(
        id,
        atomOne,
        atomTwo,
        linkOne,
        linkTwo,
      );

  void delete(Something object) {
    final $store = Store.instance;
    for (final ($atom, _) in $store.getAtomLabelBySrc(object.id)) {
      $store.setAtom($atom, null);
    }
    for (final ($edge, _) in $store.getEdgeLabelDstBySrc(object.id)) {
      $store.setEdge($edge, null);
    }
  }

  @override
  Id id(Something object) => object.id;

  @override
  Something? get(Id? id) {
    if (id == null) return null;
    final $object = objects[id]?.target;
    if ($object != null) return $object;
    final $store = Store.instance;

    Atom<String>? atomOne;
    AtomOption<String>? atomTwo;
    Link<Trivial>? linkOne;
    LinkOption<Trivial>? linkTwo;

    for (final ($atom, $label) in $store.getAtomLabelBySrc(id)) {
      switch ($label) {
        case $SomethingRepository.atomOneLabel:
          atomOne = $store.getAtom(
              $atom, id, $label, $SomethingRepository.atomOneSerializer);
        case $SomethingRepository.atomTwoLabel:
          atomTwo = $store.getAtomOption(
              $atom, id, $label, $SomethingRepository.atomTwoSerializer);
      }
    }
    for (final ($edge, ($label, _)) in $store.getEdgeLabelDstBySrc(id)) {
      switch ($label) {
        case $SomethingRepository.linkOneLabel:
          linkOne =
              $store.getLink($edge, id, $label, const $TrivialRepository());
        case $SomethingRepository.linkTwoLabel:
          linkTwo = $store.getLinkOption(
              $edge, id, $label, const $TrivialRepository());
      }
    }

    if (atomOne == null) return null;
    atomTwo ??= $store.getAtomOption(
        id ^ $SomethingRepository.atomTwoLabel,
        id,
        $SomethingRepository.atomTwoLabel,
        $SomethingRepository.atomTwoSerializer);
    if (linkOne == null) return null;
    linkTwo ??= $store.getLinkOption(id ^ $SomethingRepository.linkTwoLabel, id,
        $SomethingRepository.linkTwoLabel, const $TrivialRepository());

    final $res = Something._(
      id,
      atomOne,
      atomTwo,
      linkOne,
      linkTwo,
      $store.getMultilinks(const $SomethingRepository(), id,
          $SomethingRepository.linkThreeLabel),
      $store.getBacklinks(const $SomethingRepository(), id,
          $SomethingRepository.linkThreeLabel),
    );

    objects[id] = WeakReference($res);
    return $res;
  }
}
