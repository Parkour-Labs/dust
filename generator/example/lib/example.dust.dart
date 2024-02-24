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
  AtomDefault<bool> get isCompleted$;
  bool get isCompleted => isCompleted$.get(null);
  set isCompleted(bool value) => isCompleted$.set(value);

  void delete();
}

final class _Todo extends Todo {
  @override
  final Id id;

  _Todo._(this.id, {required this.title$, required this.isCompleted$})
      : super._();

  factory _Todo({
    required String title,
    bool? isCompleted,
  }) {
    return const $TodoRepository().create(
      title: title,
      isCompleted: isCompleted,
    ) as _Todo;
  }

  @override
  final Atom<String> title$;

  @override
  final AtomDefault<bool> isCompleted$;

  @override
  void delete() => const $TodoRepository().delete(this);
}

class $TodoRepository implements Repository<Todo> {
  const $TodoRepository();

  static const int Label = 8512415165397905237;
  static const int titleLabel = -5241206623633058639;
  static const int isCompletedLabel = -7402738807038578080;

  static const titleSerializer = StringSerializer();
  static const isCompletedSerializer = BoolSerializer();

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
    required String title,
    bool? isCompleted,
  }) {
    assert($init, 'Repository should be registered in `Dust.open`.');
    final $store = Dust.instance;
    $store.setNode($id, $TodoRepository.Label);
    $store.setAtom(
      $id ^ $TodoRepository.titleLabel,
      (
        $id,
        $TodoRepository.titleLabel,
        title,
        $TodoRepository.titleSerializer,
      ),
    );

    if (isCompleted != null) {
      $store.setAtom(
        $id ^ $TodoRepository.isCompletedLabel,
        (
          $id,
          $TodoRepository.isCompletedLabel,
          isCompleted,
          $TodoRepository.isCompletedSerializer,
        ),
      );
    }

    $store.barrier();
  }

  Todo create({
    required String title,
    bool? isCompleted,
  }) {
    final $id = Dust.instance.randomId();
    final $node = get($id);
    $write(
      $id,
      title: title,
      isCompleted: isCompleted,
    );
    final $res = $node.get(null)!;

    return $res;
  }

  NodeAuto<Todo> auto(
    Id $id, {
    required String title,
    bool? isCompleted,
  }) {
    final $node = get($id);
    return NodeAuto(
      $node,
      () => $write(
        $id,
        title: title,
        isCompleted: isCompleted,
      ),
      ($res) {},
    );
  }

  @override
  NodeOption<Todo> get(Id $id) {
    final $existing = $entries[$id]?.target;
    if ($existing != null) return $existing;
    final $model = _Todo._(
      $id,
      title$: Atom<String>(
        $id ^ $TodoRepository.titleLabel,
        $id,
        $TodoRepository.titleLabel,
        $TodoRepository.titleSerializer,
      ),
      isCompleted$: AtomDefault<bool>(
        $id ^ $TodoRepository.isCompletedLabel,
        $id,
        $TodoRepository.isCompletedLabel,
        $TodoRepository.isCompletedSerializer,
        false,
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
