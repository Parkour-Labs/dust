import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:flutter_beacons/annotations.dart';
import 'package:flutter_beacons_generator/serializable_generator.dart';
import 'package:flutter_beacons_generator/utils.dart';

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
  if (type.typeArguments.length != 1) fail('Incorrect number of type arguments in `$type` (expected 1).', elem);
  final inner = resolve(type.typeArguments.single, elem);
  if (type.element.name == 'Atom') {
    final annots = kSerializableAnnotation.annotationsOfExact(elem);
    final value = annots.firstOrNull?.getField('serializer');
    final serializer = value != null ? value.variable?.name : emitSerializer(inner);
    if (serializer == null) {
      fail(
        'Failed to synthesize serializer for type `$inner`. '
        'Please specify one using `@Serializable(serializerInstance)`. '
        'Instance must be a constant variable.',
        elem,
      );
    }
    return Atom(inner, serializer);
  }
  if (type.element.name == 'AtomOption') {
    final annots = kSerializableAnnotation.annotationsOfExact(elem);
    final value = annots.firstOrNull?.getField('serializer');
    final serializer = value != null ? value.variable?.name : emitSerializer(inner);
    if (serializer == null) {
      fail(
        'Failed to synthesize serializer for type `$inner`. '
        'Please specify one using `@Serializable(serializerInstance)`. '
        'Instance must be a constant variable.',
        elem,
      );
    }
    return AtomOption(inner, serializer);
  }
  if (type.element.name == 'Link') return Link(inner);
  if (type.element.name == 'LinkOption') return LinkOption(inner);
  if (type.element.name == 'Multilinks') return Multilinks(inner);
  if (type.element.name == 'Backlinks') {
    final annots = kBacklinkAnnotation.annotationsOfExact(elem);
    final value = annots.firstOrNull?.getField('name')?.toStringValue();
    if (value == null) fail('Backlinks must be annotated with `@Backlink(\'fieldName\')`.', elem);
    return Backlinks(inner, value);
  }
  fail('Unsupported field type `$type` (must be one of: ...).', elem);
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
  var hasId = false;
  for (final e in elem.fields) {
    if (e.name == 'id') {
      final type = e.type;
      if (!e.isFinal) fail('Field must be marked as final.', e);
      if (e.isLate) fail('Field must not be marked as late.', e);
      if (type.nullabilitySuffix != NullabilitySuffix.none) fail('Field must not be marked as nullable.', e);
      if (type is! InterfaceType || type.element.name != 'Id') fail('Field must have type `Id`.', e);
      hasId = true;
    } else {
      final field = convertField(e);
      if (field != null) fields.add(field);
    }
  }
  if (!hasId) fail('Class must contain a field `final Id id`.', elem);
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
  final value = fnv64Hash(struct.name);
  res += 'static const int Label = $value;';
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
      Atom(serializer: final serializer) => 'static const ${field.name}Serializer = $serializer;',
      AtomOption(serializer: final serializer) => 'static const ${field.name}Serializer = $serializer;',
      Link() => '',
      LinkOption() => '',
      Multilinks() => '',
      Backlinks() => '',
    };
  }
  return res;
}

String emitCreateFunctionParams(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    res += switch (field.type) {
      Atom(type: final inner) => '$inner $name,',
      AtomOption(type: final inner) => '$inner? $name,',
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
      AtomOption() => '$name,',
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
    res += switch (field.type) {
      Atom() => '''
        final \$${name}Dst = \$store.randomId();
        \$store.setEdge(\$store.randomId(), (id, ${label(struct.name, field.name)}, \$${name}Dst));
        \$store.setAtom(${serializer(struct.name, field.name)}, \$${name}Dst, $name);
      ''',
      AtomOption() => '''
        if ($name == null) {
          \$store.setEdge(\$store.randomId(), (id, ${label(struct.name, field.name)}, \$store.randomId()));
        } else {
          final \$${name}Dst = \$store.randomId();
          \$store.setEdge(\$store.randomId(), (id, ${label(struct.name, field.name)}, \$${name}Dst));
          \$store.setAtom(${serializer(struct.name, field.name)}, \$${name}Dst, $name);
        }
      ''',
      Link() => '''
        \$store.setEdge(\$store.randomId(), (id, ${label(struct.name, field.name)}, $name.id));
      ''',
      LinkOption() => '''
        if ($name == null) {
          \$store.setEdge(\$store.randomId(), (id, ${label(struct.name, field.name)}, \$store.randomId()));
        } else {
          \$store.setEdge(\$store.randomId(), (id, ${label(struct.name, field.name)}, $name.id));
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
    ${struct.name} createAt(Id id, ${emitCreateFunctionParams(struct)}) {
      final \$store = Store.instance;

      \$store.setNode(id, ${label(struct.name, "")});

      ${emitCreateFunctionBody(struct)}

      return get(id)!;
    }

    ${struct.name} create(${emitCreateFunctionParams(struct)}) =>
        createAt(Store.instance.randomId(), ${emitCreateFunctionArgs(struct)});

    ${struct.name} getOrCreateAt(Id id, ${emitCreateFunctionParams(struct)}) =>
        get(id) ?? createAt(id, ${emitCreateFunctionArgs(struct)});
  ''';
}

/// Creates the function that obtains the ID of a [struct].
String emitIdFunction(Struct struct) {
  return 'Id id(${struct.name} object) => object.id;';
}

String emitGetFunctionFieldDecls(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    res += switch (field.type) {
      Atom(type: final inner) => 'Atom<$inner>? $name;',
      AtomOption(type: final inner) => 'AtomOption<$inner>? $name;',
      Link(type: final inner) => 'Link<$inner>? $name;',
      LinkOption(type: final inner) => 'LinkOption<$inner>? $name;',
      Multilinks() => '',
      Backlinks() => '',
    };
  }
  return res;
}

String emitGetFunctionMatchArms(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    final lab = label(struct.name, field.name);
    res += switch (field.type) {
      Atom() => 'case $lab: $name = \$store.getAtom(${serializer(struct.name, field.name)}, \$dst);',
      AtomOption() => 'case $lab: $name = \$store.getAtomOption(${serializer(struct.name, field.name)}, \$dst);',
      Link(type: final inner) =>
        'case $lab: $name = \$store.getLink(const ${repository(inner.element.name)}(), \$edge);',
      LinkOption(type: final inner) =>
        'case $lab: $name = \$store.getLinkOption(const ${repository(inner.element.name)}(), \$edge);',
      Multilinks() => '',
      Backlinks() => '',
    };
  }
  return res;
}

String emitGetFunctionCtorArgs(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    res += switch (field.type) {
      Atom() => '$name!,',
      AtomOption() => '$name!,',
      Link() => '$name!,',
      LinkOption() => '$name!,',
      Multilinks(type: final inner) =>
        '\$store.getMultilinks(const ${repository(inner.element.name)}(), id, ${label(struct.name, field.name)}),',
      Backlinks(type: final inner, field: final field) =>
        '\$store.getBacklinks(const ${repository(inner.element.name)}(), id, ${label(inner.element.name, field)}),',
    };
  }
  return res;
}

/// Creates the function that obtains a [struct] by ID.
String emitGetFunction(Struct struct) {
  return '''
    ${struct.name}? get(Id? id) {
      if (id == null) return null;
      final \$store = Store.instance;

      ${emitGetFunctionFieldDecls(struct)}

      if (\$store.getNode(id) == null) return null;
      for (final (\$edge, (_, \$label, \$dst)) in \$store.getEdgesBySrc(id)) {
        switch (\$label) {
          ${emitGetFunctionMatchArms(struct)}
        }
      }

      return ${struct.name}._(
        id,
        ${emitGetFunctionCtorArgs(struct)}
      );
    }
  ''';
}

/// Generate deterministic ID for global object constructors.
String emitGlobalIds(Struct struct, ClassElement elem) {
  var res = '';
  for (final ctor in elem.constructors) {
    if (kGlobalAnnotation.annotationsOfExact(ctor).isNotEmpty) {
      final high = fnv64Hash(struct.name);
      final low = fnv64Hash(ctor.name);
      res += '''
        // Type `${struct.name}`, name `${ctor.name}`
        const Id \$${ctor.name}Id = Id($high, $low);
      ''';
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

        ${emitCreateFunctions(struct)}

        @override
        ${emitIdFunction(struct)}

        @override
        ${emitGetFunction(struct)}
      }

      ${emitGlobalIds(struct, element)}
    ''';
  }
}
