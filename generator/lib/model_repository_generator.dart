import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:qinhuai/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'serializable_generator.dart';
import 'utils.dart';

/// Sub-annotations.
const kBacklinkAnnotation = TypeChecker.fromRuntime(Backlink);

const kConstraintsAnnotation = TypeChecker.fromRuntime(Constraints);
const kDefaultAnnotation = TypeChecker.fromRuntime(Default);
const kGlobalAnnotation = TypeChecker.fromRuntime(Global);

const kActiveName = 'Active';
const kAtomName = 'Atom';
const kAtomDefaultName = 'AtomDefault';
const kAtomOptionName = 'AtomOption';
const kBacklinksName = 'Backlinks';
const kLinkName = 'Link';
const kLinkOptionName = 'LinkOption';
const kMultilinksName = 'Multilinks';

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
const kSerializableAnnotation = TypeChecker.fromRuntime(Serializable);
const kTransientAnnotation = TypeChecker.fromRuntime(Transient);

/// Converts [FieldElement] to [Field].
Field? convertField(ParameterElement elem) {
  final name = elem.name;
  final type = convertType(elem.type, elem);
  return Field(name, type);
}

/// Converts [ClassElement] to [Struct].
Future<Struct> convertStruct(ClassElement elem, BuildStep step) async {
  Never failUnnamedPubFactory() {
    fail(
      'Class must have a public unnamed factory redirecting to `_${elem.name}`.',
      elem,
    );
  }

  final name = elem.name;
  if (!elem.isAbstract) fail('Class must be abstract.', elem);
  if (elem.typeParameters.isNotEmpty) fail('Class must not be generic.', elem);
  if (!elem.constructors.any((e) => e.name == '_')) {
    fail(
      'Class must have a private unnamed constructor (`$name._()`).',
      elem,
    );
  }
  // check if there is an unnamed factory redirecting to _name
  final unnamedPublicFactory = elem.constructors
      .where((e) => e.name == '')
      .where((e) => e.isPublic)
      .firstOrNull;
  if (unnamedPublicFactory == null) failUnnamedPubFactory();
  final redirect = await unnamedPublicFactory.getRedirectedNameOrNull(step);
  if (redirect != '_$name') failUnnamedPubFactory();

  final cstor = unnamedPublicFactory;
  final fields = <Field>[];
  if (cstor.parameters.any((element) => element.name == 'id')) {
    fail(
      'Field `id` is reserved and cannot be used. It will be automatically '
      'generated for you.',
      cstor,
    );
  }
  for (final (i, e) in cstor.parameters.indexed) {
    if (i == 0) continue; // Skip the `id` field.
    final field = convertField(e);
    if (field != null) fields.add(field);
  }
  return Struct(name, fields);
}

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

/// Creates the function that queries all objects.
String emitAllFunction(Struct struct) {
  return '''
    NodesByLabel<${struct.name}> all() => NodesByLabel(${label(struct.name)}, 
      const ${repository(struct.name)}());
  ''';
}

String emitCreateFunctionArgs(Struct struct, {required bool includeLinks}) {
  final sb = StringBuffer();
  for (final field in struct.fields) {
    final name = field.name;
    switch (field.type) {
      case AtomType() ||
            AtomOptionType() ||
            AtomDefaultType() ||
            LinkType() ||
            LinkOptionType():
        sb.write('$name: $name,');
        break;
      case MultilinksType() || BacklinksType():
        if (includeLinks) {
          sb.write('$name: $name,');
        }
        break;
    }
  }
  return sb.toString();
}

String emitCreateFunctionBody(Struct struct) {
  var res = '';
  final sb = StringBuffer();
  for (final field in struct.fields) {
    final name = field.name;
    final lab = label(struct.name, field.name);
    switch (field.type) {
      case AtomType():
        sb.writeln(
          '''
          \$store.setAtom(\$id ^ $lab, (\$id, $lab, $name, 
          ${serializer(struct.name, field.name)},),);
          ''',
        );
        break;
      case AtomOptionType() || AtomDefaultType():
        sb.writeln(
          '''
          if ($name != null) {
            \$store.setAtom(\$id ^ $lab, (\$id, $lab, $name, 
            ${serializer(struct.name, field.name)},),);
          }
          ''',
        );
        break;
      case LinkType():
        sb.writeln(
          '''
          \$store.setEdge(\$id ^ $lab, (\$id, $lab, $name.id,),);
          ''',
        );
        break;
      case LinkOptionType():
        sb.writeln(
          '''
          if ($name != null) {
            \$store.setEdge(\$id ^ $lab, (\$id, $lab, $name.id,),);
          }
          ''',
        );
        break;
      default:
        // do nothing
        break;
    }
  }
  return res;
}

String emitCreateFunctionParams(Struct struct, {required bool includeLinks}) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    switch (field.type) {
      case AtomOptionType(type: final inner) ||
            AtomDefaultType(type: final inner) ||
            LinkOptionType(type: final inner):
        '$inner? $name,';
        break;
      case LinkType(type: final inner) || AtomType(type: final inner):
        'required $inner $name,';
        break;
      case MultilinksType(type: final inner) ||
            BacklinksType(type: final inner):
        if (includeLinks) {
          'Iterable<$inner> $name = const Iterable.empty(),';
        }
        break;
    }
  }
  if (res.isNotEmpty) res = '{$res}';
  return res;
}

String emitCreateFunctionLinksLogic(String res, Struct struct) {
  final sb = StringBuffer();
  for (final field in struct.fields) {
    switch (field.type) {
      case MultilinksType() || BacklinksType():
        final name = field.name;
        sb.writeln(
          '''
          for (final item in $name) {
            $res.$name\$.add(item);
          }
          ''',
        );
      default:
        break;
    }
  }
  return sb.toString();
}

/// Creates the functions that create new [struct]s.
String emitCreateFunctions(Struct struct) {
  final essentialParams = emitCreateFunctionParams(struct, includeLinks: false);
  final essentialArgs = emitCreateFunctionArgs(struct, includeLinks: false);
  final allParams = emitCreateFunctionParams(struct, includeLinks: true);
  final linksCreationBody = emitCreateFunctionLinksLogic('\$res', struct);
  return '''
    void \$write(Id \$id, $essentialParams) {
      assert(\$init, 'Repository should be registered in `Store.open`.');
      final \$store = Store.instance;
      \$store.setNode(\$id, ${label(struct.name)});
      ${emitCreateFunctionBody(struct)}
      \$store.barrier();
    }

    ${struct.name} create($allParams) {
      final \$id = Store.instance.randomId();
      final \$node = get(\$id);
      \$write(\$id, $essentialArgs);
      final \$res = \$node.get(null)!;
      $linksCreationBody
      return \$res;
    }

    NodeAuto<${struct.name}> auto(Id \$id, $allParams) {
      final \$node = get(\$id);
      return NodeAuto(
        \$node, 
        () => \$write(\$id, $essentialArgs),
        (\$res) {
          $linksCreationBody
        },
      );
    }
  ''';
}

/// Creates the function that deletes an existing struct.
String emitDeleteFunction(Struct struct) {
  return '''
    void delete(${struct.name} \$model) {
      assert(\$init, 'Repository should be registered in `Store.open`.');
      final \$id = \$model.id;
      final \$store = Store.instance;
      \$entries.remove(\$id);
      \$store.setNode(\$id, null);
      \$store.barrier();
    }
  ''';
}

/// Creates the function that obtains a  by ID.
String emitGetFunction(Struct struct) {
  return '''
    NodeOption<${struct.name}> get(Id \$id) {
      final \$existing = \$entries[\$id]?.target;
      if (\$existing != null) return \$existing;
      final \$model = ${struct.name}._(\$id, 
        ${emitGetFunctionCtorArgs(struct)});
      final \$entry = NodeOption(\$id, ${label(struct.name)}, \$model);
      \$entries[\$id] = WeakReference(\$entry);
      return \$entry;
    }
  ''';
}

String emitGetFunctionCtorArgs(Struct struct) {
  var res = '';
  for (final field in struct.fields) {
    final name = field.name;
    final lab = label(struct.name, name);
    res += switch (field.type) {
      AtomType(type: final inner) =>
        '$name: Atom<$inner>(\$id ^ $lab, \$id, $lab, '
            '${serializer(struct.name, name)},),',
      AtomOptionType(type: final inner) =>
        '$name: AtomOption<$inner>(\$id ^ $lab, \$id, $lab, '
            '${serializer(struct.name, name)},),',
      AtomDefaultType(type: final inner, :final defaultValue) =>
        '$name: AtomDefault<$inner>(\$id ^ $lab, \$id, $lab, '
            '${serializer(struct.name, name)}, $defaultValue,),',
      LinkType(type: final inner) =>
        '$name: Link<$inner>(\$id ^ $lab, \$id, $lab,'
            ' const ${repository(inner.element.name)}(),),',
      LinkOptionType(type: final inner) =>
        '$name: LinkOption<$inner>(\$id ^ $lab, \$id, $lab, '
            'const ${repository(inner.element.name)}(),),',
      MultilinksType(type: final inner) =>
        '$name: Multilinks<$inner>(\$id, $lab, '
            'const ${repository(inner.element.name)}(),),',
      BacklinksType(type: final inner, field: final field) =>
        '$name: Backlinks<$inner>(\$id, ${label(inner.element.name, field)},'
            ' const ${repository(inner.element.name)}(),),',
    };
  }
  return res;
}

/// Generate deterministic ID for global object constructors.
///
/// TODO: check if this fits the change of the API.
String emitGlobalIds(Struct struct, ClassElement elem) {
  var res = '';

  void generateFor(String name) {
    final high = fnv64Hash(struct.name);
    final low = fnv64Hash(name);
    res += '''
      // Type `${struct.name}`, name `$name`
      const Id \$${name}Id = Id($high, $low);
    ''';
  }

  for (final ctor in elem.constructors) {
    if (ctor.isFactory &&
        kGlobalAnnotation.annotationsOfExact(ctor).isNotEmpty) {
      generateFor(ctor.name);
    }
  }
  for (final method in elem.methods) {
    if (method.isStatic &&
        kGlobalAnnotation.annotationsOfExact(method).isNotEmpty) {
      generateFor(method.name);
    }
  }
  for (final acc in elem.accessors) {
    if (acc.isStatic && kGlobalAnnotation.annotationsOfExact(acc).isNotEmpty) {
      generateFor(acc.name);
    }
  }
  return res;
}

/// Creates the function that obtains the ID of a [struct].
String emitIdFunction(Struct struct) {
  return 'Id id(${struct.name} \$model) => \$model.id;';
}

/// Creates the function that initialises the repository and returns the schema.
String emitInitFunction(Struct struct) {
  var stickyNodes = <String>[];
  var stickyAtoms = <String>[];
  var stickyEdges = <String>[];
  var acyclicEdges = <String>[];

  stickyNodes.add(label(struct.name));
  for (final field in struct.fields) {
    final lab = label(struct.name, field.name);
    switch (field.type) {
      case AtomType():
        stickyAtoms.add(lab);
      case AtomOptionType(:final sticky):
        if (sticky) stickyAtoms.add(lab);
      case AtomDefaultType(:final sticky):
        if (sticky) stickyAtoms.add(lab);
      case LinkType(:final acyclic):
        stickyEdges.add(lab);
        if (acyclic) acyclicEdges.add(lab);
      case LinkOptionType(:final sticky, :final acyclic):
        if (sticky) stickyEdges.add(lab);
        if (acyclic) acyclicEdges.add(lab);
      case MultilinksType(:final sticky, :final acyclic):
        if (sticky) stickyEdges.add(lab);
        if (acyclic) acyclicEdges.add(lab);
      default:
        break;
    }
  }

  return '''
    Schema init() {
      \$init = true;
      return const Schema(
        stickyNodes: [${stickyNodes.join(', ')}],
        stickyAtoms: [${stickyAtoms.join(', ')}],
        stickyEdges: [${stickyEdges.join(', ')}],
        acyclicEdges: [${acyclicEdges.join(', ')}],
      );
    }
  ''';
}

/// Creates the label constants for the [struct].
String emitLabelDecls(Struct struct) {
  bool shouldEmit(FieldType type) {
    switch (type) {
      case BacklinksType():
        return false;
      default:
        return true;
    }
  }

  var res = '';
  final value = fnv64Hash(struct.name);
  res += 'static const int Label = $value;';
  for (final field in struct.fields) {
    if (shouldEmit(field.type)) {
      final value = fnv64Hash('${struct.name}.${field.name}');
      res += 'static const int ${field.name}Label = $value;';
    }
  }
  return res;
}

/// Creates the serializer constants for the [struct].
String emitSerializerDecls(Struct struct) {
  final sb = StringBuffer();
  for (final field in struct.fields) {
    switch (field.type) {
      case AtomType(serializer: final serializer) ||
            AtomOptionType(serializer: final serializer) ||
            AtomDefaultType(serializer: final serializer):
        sb.writeln('static const ${field.name}Serializer = $serializer;');
        break;
      default:
        // do nothing
        break;
    }
  }
  return sb.toString();
}

String emitChildFactory(Struct struct) {
  return '''
  factory ${child(struct.name)}(${emitCreateFunctionParams(struct, includeLinks: true)}) {
    return ${repository(struct.name)}().create(
      ${emitCreateFunctionParams(struct, includeLinks: true)}
    );
  }
  ''';
}

String emitParentDecls(Struct struct) {
  final sb = StringBuffer();

  void Function(InterfaceType, String) getWriter(
    String? containerName, [
    String Function(InterfaceType)? mapper,
    String Function(InterfaceType)? containedTypeMapper,
  ]) {
    return (type, name) {
      final rawType = mapper?.call(type) ?? type.toString();
      final contained = containedTypeMapper?.call(type) ?? type.toString();
      if (containerName == null) {
        sb.writeln('$rawType get $name;');
        sb.writeln('set $name($rawType value);');
      } else {
        sb.writeln('$containerName<$contained> get $name\$;');
        sb.writeln('$rawType get $name => $name\$.get(null);');
        sb.writeln('set $name($rawType value) => $name\$.set(value);');
      }
    };
  }

  String optMapper(InterfaceType type) => '$type?';
  String colMapper(InterfaceType type) => 'List<$type>';

  final writeAtom = getWriter(kAtomName);
  final writeAtomOption = getWriter(kAtomOptionName, optMapper);
  final writeAtomDefault = getWriter(kAtomDefaultName);
  final writeLink = getWriter(kLinkName);
  final writeLinkOption = getWriter(kLinkOptionName, optMapper);
  final writeMultilinks = getWriter(kMultilinksName, colMapper);
  final writeBacklinks = getWriter(kBacklinksName, colMapper);

  sb.writeln('Id get id;');

  for (final field in struct.fields) {
    switch (field.type) {
      case AtomType(type: final inner):
        writeAtom(inner, field.name);
        break;
      case AtomOptionType(type: final inner):
        writeAtomOption(inner, field.name);
        break;
      case AtomDefaultType(type: final inner):
        writeAtomDefault(inner, field.name);
        break;
      case LinkType(type: final inner):
        writeLink(inner, field.name);
        break;
      case LinkOptionType(type: final inner):
        writeLinkOption(inner, field.name);
        break;
      case MultilinksType(type: final inner):
        writeMultilinks(inner, field.name);
        break;
      case BacklinksType(type: final inner):
        writeBacklinks(inner, field.name);
        break;
    }
  }
  return sb.toString();
}

String emitChildCstors(Struct struct) {
  final names = struct.fields.map((e) => 'this.${e.name}\$').join(', ');
  return '''
  ${child(struct.name)}._(this.id, $names) : super._();
  ''';
}

String emitChildDecls(Struct struct) {
  final sb = StringBuffer();

  void write(String wrapperName, InterfaceType inner, String name) {
    sb.writeln(
      '''
      @override
      final $wrapperName<$inner> $name\$;
      ''',
    );
  }

  for (final field in struct.fields) {
    switch (field.type) {
      case AtomType(type: final inner):
        write(kAtomName, inner, field.name);
        break;
      case AtomOptionType(type: final inner):
        write(kAtomOptionName, inner, field.name);
        break;
      case AtomDefaultType(type: final inner):
        write(kAtomDefaultName, inner, field.name);
        break;
      case LinkType(type: final inner):
        write(kLinkName, inner, field.name);
        break;
      case LinkOptionType(type: final inner):
        write(kLinkOptionName, inner, field.name);
        break;
      case MultilinksType(type: final inner):
        write(kMultilinksName, inner, field.name);
        break;
      case BacklinksType(type: final inner):
        write(kBacklinksName, inner, field.name);
        break;
    }
  }
  return sb.toString();
}

/// Returns the corresponding label constant name.
String label(String type, [String? field]) =>
    '\$${type}Repository.${field ?? ''}Label';

/// Returns the corresponding parent class name.
String parent(String name) => '_\$$name';

/// Returns the name of the implementing child class.
String child(String name) => '_$name';

/// Returns the corresponding repository class name.
String repository(String name) => '\$${name}Repository';

/// Returns the corresponding serializer constant name.
String serializer(String type, String field) =>
    '\$${type}Repository.${field}Serializer';

/// A struct to be mapped.
final class Struct {
  final String name;
  final List<Field> fields;
  Struct(this.name, this.fields);
}

/// A field to be mapped.
final class Field {
  final String name;
  final FieldType type;
  Field(this.name, this.type);
}

/// All supported field types.
sealed class FieldType {}

final class MultilinksType extends FieldType {
  final InterfaceType type;
  final bool sticky;
  final bool acyclic;
  MultilinksType(this.type, {required this.sticky, required this.acyclic});
}

final class AtomType extends FieldType {
  final InterfaceType type;
  final String serializer;
  AtomType(this.type, this.serializer);
}

final class AtomDefaultType extends FieldType {
  final InterfaceType type;
  final String serializer;
  final String defaultValue;
  final bool sticky;
  AtomDefaultType(this.type, this.serializer, this.defaultValue,
      {required this.sticky});
}

final class AtomOptionType extends FieldType {
  final InterfaceType type;
  final String serializer;
  final bool sticky;
  AtomOptionType(this.type, this.serializer, {required this.sticky});
}

final class BacklinksType extends FieldType {
  final InterfaceType type;
  final String field;
  BacklinksType(this.type, this.field);
}

final class LinkType extends FieldType {
  final InterfaceType type;
  final bool acyclic;
  LinkType(this.type, {required this.acyclic});
}

final class LinkOptionType extends FieldType {
  final InterfaceType type;
  final bool sticky;
  final bool acyclic;
  LinkOptionType(this.type, {required this.sticky, required this.acyclic});
}

/// Procedural macro entry point.
///
/// For more details, see [https://parkourlabs.feishu.cn/docx/SGi2dLIUUo4MjVxdzsvcxseBnZc](https://parkourlabs.feishu.cn/docx/SGi2dLIUUo4MjVxdzsvcxseBnZc).
class ModelRepositoryGenerator extends GeneratorForAnnotation<Model> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement ||
        element is EnumElement ||
        element is MixinElement) {
      fail('Only classes may be annotated with @Model().', element);
    }
    final struct = await convertStruct(element, buildStep);
    return '''
      // ignore_for_file: ${kIgnoreForFile.join(', ')}
      // coverage:ignore-file

      mixin ${parent(struct.name)} {
        ${emitParentDecls(struct)}
      }

      final class ${child(struct.name)} extends ${struct.name} {
        ${child(struct.name)}._(${emitChildCstors(struct)}) : super._();

        ${emitChildFactory(struct)} 

        ${emitChildDecls(struct)}
      }

      class ${repository(struct.name)} implements Repository<${struct.name}> {
        const ${repository(struct.name)}();

        ${emitLabelDecls(struct)}

        ${emitSerializerDecls(struct)}

        static final Map<Id, WeakReference<NodeOption<${struct.name}>>> \$entries = {};

        static bool \$init = false;

        @override
        ${emitInitFunction(struct)}

        @override
        ${emitIdFunction(struct)}

        ${emitCreateFunctions(struct)}

        @override
        ${emitGetFunction(struct)}

        @override
        ${emitDeleteFunction(struct)}

        ${emitAllFunction(struct)}
      }

      ${emitGlobalIds(struct, element)}
    ''';
  }
}
