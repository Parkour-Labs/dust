import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:flutter_beacons/annotations.dart';

import 'serializable_generator.dart';
import 'utils.dart';

/// Suppressed lints.
const kIgnoreForFile = [
  'duplicate_ignore',
  'unused_local_variable',
  'non_constant_identifier_names',
  'constant_identifier_names',
  'invalid_use_of_protected_member',
  'unnecessary_cast',
  'prefer_const_constructors',
  'lines_longer_than_80_chars',
  'require_trailing_commas',
  'inference_failure_on_function_invocation',
  'unnecessary_parenthesis',
  'unnecessary_raw_strings',
  'unnecessary_null_checks',
  'join_return_with_assignment',
  'prefer_final_locals',
  'avoid_js_rounded_ints',
  'avoid_positional_boolean_parameters',
  'always_specify_types',
];

/// Sub-annotations.
const kBacklinkAnnotation = TypeChecker.fromRuntime(Backlink);
const kSerializableAnnotation = TypeChecker.fromRuntime(Serializable);
const kDefaultAnnotation = TypeChecker.fromRuntime(Default);
const kTransientAnnotation = TypeChecker.fromRuntime(Transient);
const kGlobalAnnotation = TypeChecker.fromRuntime(Global);

/// All supported field types.
sealed class FieldType {}

final class Atom extends FieldType {
  final InterfaceType type;
  final String serializer;
  Atom(this.type, this.serializer);
}

final class AtomOption extends FieldType {
  final InterfaceType type;
  final String serializer;
  AtomOption(this.type, this.serializer);
}

final class AtomDefault extends FieldType {
  final InterfaceType type;
  final String serializer;
  final String defaultValue;
  AtomDefault(this.type, this.serializer, this.defaultValue);
}

final class Link extends FieldType {
  final InterfaceType type;
  Link(this.type);
}

final class LinkOption extends FieldType {
  final InterfaceType type;
  LinkOption(this.type);
}

final class Multilinks extends FieldType {
  final InterfaceType type;
  Multilinks(this.type);
}

final class Backlinks extends FieldType {
  final InterfaceType type;
  final String field;
  Backlinks(this.type, this.field);
}

/// A field to be mapped.
final class Field {
  final String name;
  final FieldType type;
  Field(this.name, this.type);
}

/// A struct to be mapped.
final class Struct {
  final String name;
  final List<Field> fields;
  Struct(this.name, this.fields);
}

/// Converts [DartType] to [FieldType].
FieldType convertType(DartType rawType, FieldElement elem) {
  final type = resolve(rawType, elem);
  if (type.element.name == 'Atom' || type.element.name == 'AtomOption' || type.element.name == 'AtomDefault') {
    if (type.typeArguments.length != 1) fail('Incorrect number of type arguments in `$type` (expected 1).', elem);
    final inner = resolve(type.typeArguments.single, elem);
    final value = kSerializableAnnotation.annotationsOfExact(elem).firstOrNull?.getField('serializer');
    final serializer = (value != null) ? construct(value, elem) : emitSerializer(inner);
    if (serializer == null) {
      fail(
        'Failed to synthesize serializer for type `$inner`. '
        'Please specify one using `@Serializable(serializerInstance)`. ',
        elem,
      );
    }
    if (type.element.name == 'Atom') {
      return Atom(inner, serializer);
    } else if (type.element.name == 'AtomOption') {
      return AtomOption(inner, serializer);
    } else {
      final value = kDefaultAnnotation.annotationsOfExact(elem).firstOrNull?.getField('defaultValue');
      final defaultValue = (value != null) ? construct(value, elem) : null;
      if (defaultValue == null) {
        fail(
          'Please specify a default value using `@Default(defaultValue)`. ',
          elem,
        );
      }
      return AtomDefault(inner, serializer, defaultValue);
    }
  }
  if (type.element.name == 'Link') {
    if (type.typeArguments.length != 1) fail('Incorrect number of type arguments in `$type` (expected 1).', elem);
    final inner = resolve(type.typeArguments.single, elem);
    return Link(inner);
  }
  if (type.element.name == 'LinkOption') {
    if (type.typeArguments.length != 1) fail('Incorrect number of type arguments in `$type` (expected 1).', elem);
    final inner = resolve(type.typeArguments.single, elem);
    return LinkOption(inner);
  }
  if (type.element.name == 'Multilinks') {
    if (type.typeArguments.length != 1) fail('Incorrect number of type arguments in `$type` (expected 1).', elem);
    final inner = resolve(type.typeArguments.single, elem);
    return Multilinks(inner);
  }
  if (type.element.name == 'Backlinks') {
    if (type.typeArguments.length != 1) fail('Incorrect number of type arguments in `$type` (expected 1).', elem);
    final inner = resolve(type.typeArguments.single, elem);
    final annots = kBacklinkAnnotation.annotationsOfExact(elem);
    final value = annots.firstOrNull?.getField('name')?.toStringValue();
    if (value == null) fail('Backlinks must be annotated with `@Backlink(\'fieldName\')`.', elem);
    return Backlinks(inner, value);
  }
  fail(
    'Unsupported field type `$type` (must be one of: `Atom`, `AtomOption`, `AtomDefault`, `Link`, `LinkOption`, `Multilinks` or `Backlinks`).',
    elem,
  );
}

/// Converts [FieldElement] to [Field].
Field? convertField(FieldElement elem) {
  if (elem.isStatic || kTransientAnnotation.annotationsOfExact(elem).isNotEmpty) return null;
  if (!elem.isFinal) fail('Field must be marked as final.', elem);
  if (elem.isLate) fail('Field must not be marked as late.', elem);
  final name = elem.name;
  final type = convertType(elem.type, elem);
  return Field(name, type);
}

/// Converts [ClassElement] to [Struct].
Struct convertStruct(ClassElement elem) {
  if (elem.isAbstract) fail('Class must not be abstract.', elem);
  if (elem.typeParameters.isNotEmpty) fail('Class must not be generic.', elem);
  final name = elem.name;
  final fields = <Field>[];
  final id = elem.fields.firstOrNull;
  if (id == null || id.name != 'id') {
    fail('The first field in a model class must be `final Id id`.', elem);
  } else {
    final type = id.type;
    if (!id.isFinal) fail('The `id` field must be marked as final.', id);
    if (id.isLate) fail('The `id` field must not be marked as late.', id);
    if (type.nullabilitySuffix != NullabilitySuffix.none) fail('The `id` field must not be marked as nullable.', id);
    if (type is! InterfaceType || type.element.name != 'Id') fail('The `id` field must have type `Id`.', id);
  }
  for (final (i, e) in elem.fields.indexed) {
    if (i == 0) continue; // Skip the `id` field.
    final field = convertField(e);
    if (field != null) fields.add(field);
  }
  return Struct(name, fields);
}

/// Returns the corresponding repository class name.
String repository(String name) {
  return '\$${name}Repository';
}

/// Returns the corresponding label constant name.
String label(String type, String field) {
  return '\$${type}Repository.${field}Label';
}

/// Returns the corresponding serializer constant name.
String serializer(String type, String field) {
  return '\$${type}Repository.${field}Serializer';
}

/// Creates the label constants for the [struct].
String emitLabelDecls(Struct struct) {
  var res = '';
  // final value = fnv64Hash(struct.name);
  // res += 'static const int Label = $value;';
  for (final field in struct.fields) {
    if (field.type is! Backlinks) {
      final value = fnv64Hash('${struct.name}.${field.name}'); // TODO: convert to snake case before hashing?
      res += 'static const int ${field.name}Label = $value;';
    }
  }
  return res;
}

/// Creates the serializer constants for the [struct].
String emitSerializerDecls(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    res += switch (field.type) {
      Atom(serializer: final serializer) ||
      AtomOption(serializer: final serializer) ||
      AtomDefault(serializer: final serializer) =>
        'static const ${field.name}Serializer = $serializer;',
      Link() => '',
      LinkOption() => '',
      Multilinks() => '',
      Backlinks() => '',
    };
  }
  return res;
}

/// Creates the function that obtains the ID of a [struct].
String emitIdFunction(Struct struct) {
  return 'Id id(${struct.name} \$model) => \$model.id;';
}

/// Creates the function that checks if a [struct] completely exists.
String emitExistsFunction(Struct struct) {
  var clauses = '';
  for (final field in struct.fields) {
    final name = field.name;
    clauses += switch (field.type) {
      Atom() => '\$model.$name.exists &&',
      AtomOption() => '',
      AtomDefault() => '',
      Link() => '\$model.$name.exists &&',
      LinkOption() => '',
      Multilinks() => '',
      Backlinks() => '',
    };
  }
  return '''
    bool exists(${struct.name} \$model) => $clauses true;
  ''';
}

String emitCreateFunctionParams(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    res += switch (field.type) {
      Atom(type: final inner) => '$inner $name,',
      AtomOption(type: final inner) || AtomDefault(type: final inner) => '$inner? $name,',
      Link(type: final inner) => '$inner $name,',
      LinkOption(type: final inner) => '$inner? $name,',
      Multilinks() => '',
      Backlinks() => '',
    };
  }
  return res;
}

String emitCreateFunctionArgs(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    res += switch (field.type) {
      Atom() => '$name,',
      AtomOption() || AtomDefault() => '$name,',
      Link() => '$name,',
      LinkOption() => '$name,',
      Multilinks() => '',
      Backlinks() => '',
    };
  }
  return res;
}

String emitCreateFunctionBody(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    final lab = label(struct.name, field.name);
    res += switch (field.type) {
      Atom() => '''
        \$store.setAtom(\$id ^ $lab, (\$id, $lab, $name, ${serializer(struct.name, field.name)},),);
      ''',
      AtomOption() || AtomDefault() => '''
        if ($name != null) {
          \$store.setAtom(\$id ^ $lab, (\$id, $lab, $name, ${serializer(struct.name, field.name)},),);
        }
      ''',
      Link() => '''
        \$store.setEdge(\$id ^ $lab, (\$id, $lab, $name.id,),);
      ''',
      LinkOption() => '''
        if ($name != null) {
          \$store.setEdge(\$id ^ $lab, (\$id, $lab, $name.id,),);
        }
      ''',
      Multilinks() => '',
      Backlinks() => '',
    };
  }
  return res;
}

/// Creates the functions that create new [struct]s.
String emitCreateFunctions(Struct struct) {
  return '''
    void overwrite(Id \$id, ${emitCreateFunctionParams(struct)}) {
      final \$store = Store.instance;
      ${emitCreateFunctionBody(struct)}
    }

    ${struct.name} create(${emitCreateFunctionParams(struct)}) {
      final \$id = Store.instance.randomId();
      final \$entry = get(\$id);
      overwrite(\$id, ${emitCreateFunctionArgs(struct)});
      return \$entry.model;
    }

    ${struct.name} init(Id \$id, ${emitCreateFunctionParams(struct)}) {
      final \$entry = get(\$id);
      if (!exists(\$entry.model)) {
        overwrite(\$id, ${emitCreateFunctionArgs(struct)});
      }
      return \$entry.model;
    }
  ''';
}

String emitGetFunctionCtorArgs(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final lab = label(struct.name, field.name);
    res += switch (field.type) {
      Atom(type: final inner) => 'Atom<$inner>(\$id ^ $lab, \$id, $lab, ${serializer(struct.name, field.name)},),',
      AtomOption(type: final inner) =>
        'AtomOption<$inner>(\$id ^ $lab, \$id, $lab, ${serializer(struct.name, field.name)},),',
      AtomDefault(type: final inner, :final defaultValue) =>
        'AtomDefault<$inner>(\$id ^ $lab, \$id, $lab, ${serializer(struct.name, field.name)}, $defaultValue,),',
      Link(type: final inner) => 'Link<$inner>(\$id ^ $lab, \$id, $lab, const ${repository(inner.element.name)}(),),',
      LinkOption(type: final inner) =>
        'LinkOption<$inner>(\$id ^ $lab, \$id, $lab, const ${repository(inner.element.name)}(),),',
      Multilinks(type: final inner) => 'Multilinks<$inner>(\$id, $lab, const ${repository(inner.element.name)}(),),',
      Backlinks(type: final inner, field: final field) =>
        'Backlinks<$inner>(\$id, ${label(inner.element.name, field)}, const ${repository(inner.element.name)}(),),',
    };
  }
  return res;
}

String emitGetFunctionParentAssignments(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    res += switch (field.type) {
      Atom() => '''
        \$model.$name.parent = \$entry;
      ''',
      Link() => '''
        \$model.$name.parent = \$entry;
      ''',
      _ => '',
    };
  }
  return res;
}

/// Creates the function that obtains a [struct] by ID.
String emitGetFunction(Struct struct) {
  return '''
    RepositoryEntry<${struct.name}> get(Id \$id) {
      final \$existing = entries[\$id]?.target;
      if (\$existing != null) return \$existing;

      final \$model = ${struct.name}._(\$id, ${emitGetFunctionCtorArgs(struct)});
      final \$entry = RepositoryEntry(this, \$model);
      ${emitGetFunctionParentAssignments(struct)}

      entries[\$id] = WeakReference(\$entry);
      return \$entry;
    }
  ''';
}

/// Creates the function that deletes an existing struct.
String emitDeleteFunction(Struct struct) {
  return '''
    void delete(${struct.name} \$model) {
      final \$id = \$model.id;
      final \$store = Store.instance;
      \$store.getAtomLabelValueBySrc(\$id, (\$atom, \$label, \$value) => \$store.setAtom(\$atom, null));
      \$store.getEdgeLabelDstBySrc(\$id, (\$atom, \$label, \$dst) => \$store.setAtom(\$atom, null));
      entries.remove(\$id);
    }
  ''';
}

/// Generate deterministic ID for global object constructors.
String emitGlobalIds(Struct struct, ClassElement elem) {
  var res = '';
  for (final ctor in elem.constructors) {
    if (ctor.isFactory) {
      if (kGlobalAnnotation.annotationsOfExact(ctor).isNotEmpty) {
        final high = fnv64Hash(struct.name);
        final low = fnv64Hash(ctor.name);
        res += '''
        // Type `${struct.name}`, name `${ctor.name}`
        const Id \$${ctor.name}Id = Id($high, $low);
      ''';
      }
    }
  }
  return res;
}

/// Procedural macro entry point.
///
/// For more details, see [https://parkourlabs.feishu.cn/docx/SGi2dLIUUo4MjVxdzsvcxseBnZc](https://parkourlabs.feishu.cn/docx/SGi2dLIUUo4MjVxdzsvcxseBnZc).
class ModelRepositoryGenerator extends GeneratorForAnnotation<Model> {
  @override
  String generateForAnnotatedElement(Element element, ConstantReader annotation, BuildStep buildStep) {
    if (element is! ClassElement || element is EnumElement || element is MixinElement) {
      fail('Only classes may be annotated with @Model().', element);
    }
    final struct = convertStruct(element);
    return '''
      // ignore_for_file: ${kIgnoreForFile.join(', ')}
      // coverage:ignore-file

      class ${repository(struct.name)} implements Repository<${struct.name}> {
        const ${repository(struct.name)}();

        ${emitLabelDecls(struct)}

        ${emitSerializerDecls(struct)}

        static final Map<Id, WeakReference<RepositoryEntry<${struct.name}>>> entries = {};

        @override
        ${emitIdFunction(struct)}

        @override
        ${emitExistsFunction(struct)}

        ${emitCreateFunctions(struct)}

        @override
        ${emitGetFunction(struct)}

        @override
        ${emitDeleteFunction(struct)}
      }

      ${emitGlobalIds(struct, element)}
    ''';
  }
}
