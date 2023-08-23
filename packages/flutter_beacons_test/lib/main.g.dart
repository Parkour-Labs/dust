// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// ModelRepositoryGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types
// coverage:ignore-file

class $TrivialRepository implements Repository<Trivial> {
  const $TrivialRepository();

  static const int Label = 4898135217045869580;

  Trivial create() {
    final store = Store.instance;
    final id = store.randomId();

    store.setNode(id, $TrivialRepository.Label);

    return get(id)!;
  }

  @override
  Id id(Trivial object) => object.id;

  @override
  Trivial? get(Id? id) => null;
}

// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types
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

  Something create(
    String atomOne,
    String? atomTwo,
    Trivial linkOne,
    Trivial? linkTwo,
  ) {
    final store = Store.instance;
    final id = store.randomId();

    store.setNode(id, $SomethingRepository.Label);

    final atomOneDst = store.randomId();
    store.setEdge(
        store.randomId(), (id, $SomethingRepository.atomOneLabel, atomOneDst));
    store.setAtom($SomethingRepository.atomOneSerializer, atomOneDst, atomOne);
    if (atomTwo == null) {
      store.setEdge(store.randomId(),
          (id, $SomethingRepository.atomTwoLabel, store.randomId()));
    } else {
      final atomTwoDst = store.randomId();
      store.setEdge(store.randomId(),
          (id, $SomethingRepository.atomTwoLabel, atomTwoDst));
      store.setAtom(
          $SomethingRepository.atomTwoSerializer, atomTwoDst, atomTwo);
    }
    store.setEdge(
        store.randomId(), (id, $SomethingRepository.linkOneLabel, linkOne.id));
    if (linkTwo == null) {
      store.setEdge(store.randomId(),
          (id, $SomethingRepository.linkTwoLabel, store.randomId()));
    } else {
      store.setEdge(store.randomId(),
          (id, $SomethingRepository.linkTwoLabel, linkTwo.id));
    }

    return get(id)!;
  }

  @override
  Id id(Something object) => object.id;

  @override
  Something? get(Id? id) => null;
}
