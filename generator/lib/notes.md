```dart
/// Converts [DartType] to [FieldType].
FieldType convertType(DartType rawType, ParameterElement elem) {
  final type = resolve(rawType, elem);
  final constraints =
      kConstraintsAnnotation.annotationsOfExact(elem).firstOrNull;
  var sticky = constraints?.getField('sticky')?.toBoolValue();
  var acyclic = constraints?.getField('acyclic')?.toBoolValue();

  if (type.element.name == 'Atom' ||
      type.element.name == 'AtomOption' ||
      type.element.name == 'AtomDefault') {
    if (type.typeArguments.length != 1) {
      fail(
        'Incorrect number of type arguments in `$type` (expected 1).',
        elem,
      );
    }
    final inner = resolve(type.typeArguments.single, elem);
    final value = kSerializableAnnotation
        .annotationsOfExact(elem)
        .firstOrNull
        ?.getField('serializer');
    final serializer =
        (value != null) ? construct(value, elem) : emitSerializer(inner);
    if (serializer == null) {
      fail(
        'Failed to synthesize serializer for type `$inner`. '
        'Please specify one using `@Serializable(serializerInstance)`. ',
        elem,
      );
    }
    if (type.element.name == 'Atom') {
      if (sticky != null) {
        fail('Sticky constraint is already implied here.', elem);
      }
      if (acyclic != null) {
        fail('Acyclic constraint cannot be applied here.', elem);
      }
      return AtomType(inner, serializer);
    } else if (type.element.name == 'AtomOption') {
      if (acyclic != null) {
        fail('Acyclic constraint cannot be applied here.', elem);
      }
      return AtomOptionType(inner, serializer, sticky: sticky == true);
    } else if (type.element.name == 'AtomDefault') {
      final value = kDefaultAnnotation
          .annotationsOfExact(elem)
          .firstOrNull
          ?.getField('defaultValue');
      final defaultValue = (value != null) ? construct(value, elem) : null;
      if (defaultValue == null) {
        fail(
          'Please specify a default value using `@Default(defaultValue)`. ',
          elem,
        );
      }
      if (acyclic != null) {
        fail('Acyclic constraint cannot be applied here.', elem);
      }
      return AtomDefaultType(inner, serializer, defaultValue,
          sticky: sticky == true);
    }
  }

  if (type.element.name == 'Link' ||
      type.element.name == 'LinkOption' ||
      type.element.name == 'Multilinks') {
    if (type.typeArguments.length != 1) {
      fail(
        'Incorrect number of type arguments in `$type` (expected 1).',
        elem,
      );
    }
    final inner = resolve(type.typeArguments.single, elem);
    if (type.element.name == 'Link') {
      if (sticky != null) {
        fail('Sticky constraint is already implied here.', elem);
      }
      return LinkType(inner, acyclic: acyclic == true);
    } else if (type.element.name == 'LinkOption') {
      return LinkOptionType(inner,
          sticky: sticky == true, acyclic: acyclic == true);
    } else if (type.element.name == 'Multilinks') {
      return MultilinksType(inner,
          sticky: sticky == true, acyclic: acyclic == true);
    }
  }

  if (type.element.name == 'Backlinks') {
    if (type.typeArguments.length != 1) {
      fail(
        'Incorrect number of type arguments in `$type` (expected 1).',
        elem,
      );
    }
    final inner = resolve(type.typeArguments.single, elem);
    final annot = kBacklinkAnnotation.annotationsOfExact(elem).firstOrNull;
    final value = annot?.getField('name')?.toStringValue();
    if (value == null) {
      fail(
        'Backlinks must be annotated with `@Backlink(\'fieldName\')`.',
        elem,
      );
    }
    return BacklinksType(inner, value);
  }

  fail(
    'Unsupported field type `$type` (must be one of: `Atom`, `AtomOption`, '
    '`AtomDefault`, `Link`, `LinkOption`, `Multilinks` or `Backlinks`).',
    elem,
  );
}
```

```dart
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
```

