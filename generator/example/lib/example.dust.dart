// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'example.dart';

// **************************************************************************
// ModelRepositoryGenerator
// **************************************************************************

// ignore_for_file: duplicate_ignore, unused_local_variable, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types
// coverage:ignore-file

mixin _$Todo {
  Id get id;
  Atom<String> get title$;
  String get title => title$.get(null);
  set title(String value) => title$.set(value);
}

final class _Todo extends Todo {
  @override // here
  final Id id;

  _Todo._(
    this.id, {
    // here
    required this.title$,
  }) : super._();

  // here
  factory _Todo({
    required String title,
  }) {
    return $TodoRepository().create(title: title) as _Todo;
  }

  @override
  final Atom<String> title$;
}

class $TodoRepository implements Repository<Todo> {
  const $TodoRepository();

  static const int Label = 8512415165397905237;
  static const int titleLabel = -5241206623633058639;

  static const titleSerializer = StringSerializer();

  static final Map<Id, WeakReference<NodeOption<Todo>>> $entries = {};

  static bool $init = false;

  @override
  Schema init() {
    $init = true;
    return const Schema(
      stickyNodes: [$TodoRepository.Label],
      stickyAtoms: [$TodoRepository.titleLabel],
      stickyEdges: [],
      acyclicEdges: [],
    );
  }

  @override
  Id id(Todo $model) => $model.id;

  void $write(
    Id $id, {
    required String title, // here
  }) {
    assert($init, 'Repository should be registered in `Dust.open`.');
    final $store = Dust.instance;
    $store.setNode($id, $TodoRepository.Label);

    $store.barrier();
  }

  Todo create({required String title}) {
    final $id = Dust.instance.randomId();
    final $node = get($id);
    $write(
      $id,
      title: title, // here
    );
    final $res = $node.get(null)!;

    return $res;
  }

  NodeAuto<Todo> auto(
    Id $id, {
    required String title, // here
  }) {
    final $node = get($id);
    return NodeAuto(
      $node,
      () => $write(
        $id,
        title: title,
      ),
      ($res) {},
    );
  }

  @override
  NodeOption<Todo> get(Id $id) {
    final $existing = $entries[$id]?.target;
    if ($existing != null) return $existing;
    final $model = _Todo._(
      // here
      $id,
      title$: Atom<String>(
        $id ^ $TodoRepository.titleLabel,
        $id,
        $TodoRepository.titleLabel,
        $TodoRepository.titleSerializer,
      ),
    );
    final $entry = NodeOption($id, $TodoRepository.Label, $model);
    $entries[$id] = WeakReference($entry);
    return $entry;
  }

  @override
  void delete(Todo $model) {
    assert($init, 'Repository should be registered in `Dust.open`.');
    final $id = $model.id;
    final $store = Dust.instance;
    $entries.remove($id);
    $store.setNode($id, null);
    $store.barrier();
  }

  NodesByLabel<Todo> all() =>
      NodesByLabel($TodoRepository.Label, const $TodoRepository());
}
