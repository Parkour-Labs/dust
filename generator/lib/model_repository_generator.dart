import 'dart:collection';

import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:dust/annotations.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

/// Sub-annotations.
const kLinkAnnot = TypeChecker.fromRuntime(Ln);
const kStickyAnnot = TypeChecker.fromRuntime(Sticky);
const kSerializerAnnot = TypeChecker.fromRuntime(Serializer);
const kAcyclicAnnot = TypeChecker.fromRuntime(Acyclic);
const kDefaultAnnot = TypeChecker.fromRuntime(Dft);
const kGlobalAnnot = TypeChecker.fromRuntime(Glb);

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

/// Converts [FieldElement] to [Field].
Field? convertField(ParameterElement elem) {
  final name = elem.name;
  final type = convertType(elem);
  print('Field: $name, $type');
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
  // if (!elem.isAbstract) fail('Class must be abstract.', elem);
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
  print('1. Unnamed public factory: $unnamedPublicFactory');
  if (unnamedPublicFactory == null) failUnnamedPubFactory();
  print('2. Confirmed having public unnamed factory.');
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
  for (final (_, e) in cstor.parameters.indexed) {
    final field = convertField(e);
    if (field != null) fields.add(field);
  }
  return Struct(name, fields);
}

/// Converts [DartType] to [FieldType].
FieldType convertType(ParameterElement elem) {
  if (elem.isPositional) {
    ///
    fail('Positional arguments are not supported.', elem);
  }
  final type = resolve(elem.type, elem, allowNullable: true);
  final sticky = kStickyAnnot.hasAnnotationOfExact(elem);
  final acyclic = kAcyclicAnnot.hasAnnotationOfExact(elem);
  final dft = kDefaultAnnot.checkExtractOneOrNull(elem, typeName: 'Dft');
  final ln = kLinkAnnot.checkExtractOneOrNull(elem, typeName: 'Ln');
  if (dft == null && !elem.isRequired && !type.isNullable && ln == null) {
    fail(
      'Field must have a default value if it is not required and not nullable.',
      elem,
    );
  }
  final fieldOpt = type.isNullable;
  final serializers = kSerializerAnnot.annotationsOf(elem).map((e) {
    final (element, ty) = findSerializationType(e);
    final value = computeStringValue(element, e);
    return (value, ty);
  });
  if (ln != null) {
    return convertLinkType(ln, type, elem,
        fieldOpt: fieldOpt, sticky: sticky, acyclic: acyclic);
  }
  if (acyclic) {
    fail('Acyclic annotation is only supported for links.', elem);
  }
  // TODO: add better support for list types.
  final serializer = tryConvertSerializer(serializers, type, elem);
  if (dft != null) {
    final value = dft.getField('defaultValue');
    // print out the value
    final defaultValue = (value != null) ? construct(value, elem) : null;
    if (defaultValue == null) {
      fail('Default value must be specified!', elem);
    }
    return AtomDefaultType(type, serializer, defaultValue, sticky: sticky);
  }
  if (fieldOpt) {
    return AtomOptionType(type, serializer, sticky: sticky);
  }
  return AtomType(type, serializer);
}

FieldType convertLinkType(
  DartObject ln,
  InterfaceType type,
  ParameterElement elem, {
  required bool fieldOpt,
  required bool sticky,
  required bool acyclic,
}) {
  final backTo = ln.getField('backTo');
  if (!type.isDartCoreList) {
    if (backTo?.isNull != true) {
      fail('Backlinks must be a list of objects, but found: $backTo', elem);
    }
    if (fieldOpt) {
      return LinkOptionType(type, sticky: sticky, acyclic: acyclic);
    }
    if (!elem.isRequired) {
      fail('Linked field must be nullable if it is not required.', elem);
    }
    return LinkType(type, acyclic: acyclic);
  }
  // find the inner type
  final innerOrNull = type.typeArguments.singleOrNull;
  if (innerOrNull == null) {
    fail('Linked field must have a single type argument.', elem);
  }
  // the inner type must not be nullable...
  final inner = resolve(innerOrNull, elem, allowNullable: false);
  if (backTo?.isNull != true) {
    final s = backTo?.toStringValue()?.toString();
    if (s == null) {
      fail(
          'In a @Ln annotation, when `backTo` is specified, it must be a '
          'string of the name of the field to which the backlink points.',
          elem);
    }
    return BacklinksType(inner, s);
  }
  // TODO: add support for optionality, not terrible important right now
  return MultilinksType(inner, sticky: sticky, acyclic: acyclic);
}

/// The [annots] are the list of annotations that are serializers and are
/// attached to the given constructor element.
String tryConvertSerializer(
  Iterable<(String, DartType)> annots,
  InterfaceType type,
  ParameterElement elem, {
  bool overrideNullable = false,
}) {
  for (final (value, ty) in annots) {
    if (ty == type) {
      return value;
    }
  }
  if (type.isNullable && !overrideNullable) {
    // convert type into non-nullable
    final inner =
        tryConvertSerializer(annots, type, elem, overrideNullable: true);
    return 'OptionSerializer($inner)';
  }
  if (type.isDartCoreList) {
    final innerOrNull = type.typeArguments.singleOrNull;
    if (innerOrNull == null) {
      fail('List must have a single type argument.', elem);
    }
    final inner = resolve(innerOrNull, elem, allowNullable: true);
    return 'ListSerializer(${tryConvertSerializer(annots, inner, elem)})';
  }
  if (type.isDartCoreSet) {
    final innerOrNull = type.typeArguments.singleOrNull;
    if (innerOrNull == null) {
      fail('Set must have a single type argument.', elem);
    }
    final inner = resolve(innerOrNull, elem, allowNullable: true);
    return 'SetSerializer(${tryConvertSerializer(annots, inner, elem)})';
  }
  if (type.isDartCoreMap) {
    final keyOrNull = type.typeArguments.firstOrNull;
    if (keyOrNull == null) {
      fail('Map must have a key type argument.', elem);
    }
    final key = resolve(keyOrNull, elem, allowNullable: true);
    final valueOrNull = type.typeArguments.elementAtOrNull(1);
    if (valueOrNull == null) {
      fail('Map must have a value type argument.', elem);
    }
    final value = resolve(valueOrNull, elem, allowNullable: true);
    return 'MapSerializer(${tryConvertSerializer(annots, key, elem)}, '
        '${tryConvertSerializer(annots, value, elem)})';
  }
  if (annots.isNotEmpty) {}
  if (type.isDartCoreString) {
    return 'StringSerializer()';
  }
  if (type.isDartCoreInt) {
    return 'IntSerializer()';
  }
  if (type.isDartCoreDouble) {
    return 'DoubleSerializer()';
  }
  if (type.isDartCoreBool) {
    return 'BoolSerializer()';
  }
  fail('Could not resolve serializer for element.', elem);
}

(Element, DartType) findSerializationType(DartObject obj) {
  final elem = obj.type?.element;
  if (elem == null || elem is! ClassElement) {
    fail('Serializer must be a class.', elem);
  }
  for (final superType in elem.allSupertypes) {
    if (kSerializerAnnot.isExactlyType(superType)) {
      final args = superType.typeArguments;
      if (args.length != 1) {
        fail('Serializer must have a single type argument.', superType.element);
      }
      return (elem, args.single);
    }
  }
  fail('Serializer must implement `Serializer`.', elem);
}

String computeStringValue(
  Element element,
  DartObject obj,
) {
  if (element is PropertyAccessorElement) {
    final enclosing = element.enclosingElement;

    var accessString = element.name;

    if (enclosing is ClassElement) {
      accessString = '${enclosing.name}.$accessString';
    }

    return accessString;
  }
  final reviver = ConstantReader(obj).revive();
  if (reviver.namedArguments.isNotEmpty ||
      reviver.positionalArguments.isNotEmpty) {
    fail('Serializer must not have any arguments.', element);
  }
  return reviver.accessor;
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
  return sb.toString();
}

String emitCreateFunctionParams(Struct struct, {required bool includeLinks}) {
  final sb = StringBuffer('{');
  for (final field in struct.fields) {
    final name = field.name;
    switch (field.type) {
      case AtomOptionType(type: final inner) ||
            AtomDefaultType(type: final inner) ||
            LinkOptionType(type: final inner):
        sb.write('$inner $name,');
        break;
      case LinkType(type: final inner) || AtomType(type: final inner):
        sb.write('required $inner $name,');
        break;
      case MultilinksType(type: final inner) ||
            BacklinksType(type: final inner):
        if (includeLinks) {
          sb.write('Iterable<$inner> $name = const Iterable.empty(),');
        }
        break;
    }
  }
  if (sb.length == 1) return '';
  sb.write('}');
  return sb.toString();
}

String emitCreateFunctionLinksLogic(String res, Struct struct) {
  final sb = StringBuffer();
  for (final field in struct.fields) {
    switch (field.type) {
      case MultilinksType():
        final name = field.name;
        sb.writeln(
          '''
          for (final item in $name) {
            $res.$name\$.insert(item);
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
      assert(\$init, 'Repository should be registered in `Dust.open`.');
      final \$store = Dust.instance;
      \$store.setNode(\$id, ${label(struct.name)});
      ${emitCreateFunctionBody(struct)}
      \$store.barrier();
    }

    ${struct.name} create($allParams) {
      final \$id = Dust.instance.randomId();
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
      assert(\$init, 'Repository should be registered in `Dust.open`.');
      final \$id = \$model.id;
      final \$store = Dust.instance;
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
      final \$model = ${child(struct.name)}._(\$id, 
        ${emitGetFunctionCtorArgs(struct)});
      final \$entry = NodeOption(\$id, ${label(struct.name)}, \$model);
      \$entries[\$id] = WeakReference(\$entry);
      return \$entry;
    }
  ''';
}

String emitGetFunctionCtorArgs(Struct struct) {
  final sb = StringBuffer();
  for (final field in struct.fields) {
    final name = field.name;
    final lab = label(struct.name, name);
    switch (field.type) {
      case AtomType(type: final inner):
        sb.write('$name\$: Atom<$inner>(\$id ^ $lab, \$id, $lab, '
            '${serializer(struct.name, name)},),');
      case AtomOptionType(type: final inner):
        sb.write('$name\$: AtomOption<$inner>(\$id ^ $lab, \$id, $lab, '
            '${serializer(struct.name, name)},),');
      case AtomDefaultType(type: final inner, :final defaultValue):
        sb.write('$name\$: AtomDefault<$inner>(\$id ^ $lab, \$id, $lab, '
            '${serializer(struct.name, name)}, $defaultValue,),');
      case LinkType(type: final inner):
        sb.write('$name\$: Link<$inner>(\$id ^ $lab, \$id, $lab,'
            ' const ${repository(inner.element.name)}(),),');
      case LinkOptionType(type: final inner):
        sb.write('$name\$: LinkOption<$inner>(\$id ^ $lab, \$id, $lab, '
            'const ${repository(inner.element.name)}(),),');
      case MultilinksType(type: final inner):
        sb.write('$name\$: Multilinks<$inner>(\$id, $lab, '
            'const ${repository(inner.element.name)}(),),');
      case BacklinksType(type: final inner, field: final field):
        sb.write(
            '$name\$: Backlinks<$inner>(\$id, ${label(inner.element.name, field)},'
            ' const ${repository(inner.element.name)}(),),');
    }
  }
  return sb.toString();
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
    if (ctor.isFactory && kGlobalAnnot.annotationsOfExact(ctor).isNotEmpty) {
      generateFor(ctor.name);
    }
  }
  for (final method in elem.methods) {
    if (method.isStatic && kGlobalAnnot.annotationsOfExact(method).isNotEmpty) {
      generateFor(method.name);
    }
  }
  for (final acc in elem.accessors) {
    if (acc.isStatic && kGlobalAnnot.annotationsOfExact(acc).isNotEmpty) {
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
    ${emitFactoryNoBacklinkSpecifiedChecks(struct)}
    return const ${repository(struct.name)}().create(
      ${emitCreateFunctionArgs(struct, includeLinks: true)}
    ) as ${child(struct.name)};
  }
  ''';
}

String emitFactoryNoBacklinkSpecifiedChecks(Struct struct) {
  final sb = StringBuffer();
  for (final field in struct.fields) {
    switch (field.type) {
      case BacklinksType():
        sb.writeln(
          'assert(${field.name}.isEmpty, \'Backlink ${field.name} in '
          'constructor currently does not support passing in any arguments, '
          'but only serve as a marker parameter.\',);',
        );
        break;
      default:
        // do nothing
        break;
    }
  }
  return sb.toString();
}

String emitParentDecls(Struct struct) {
  final sb = StringBuffer();

  void Function(InterfaceType, String) getWriter(
    String? containerName, [
    String Function(InterfaceType)? mapper,
    String Function(InterfaceType)? containedTypeMapper,
  ]) {
    return (type, name) {
      final contained = containedTypeMapper?.call(type) ?? type.toString();
      sb.writeln('$containerName<$contained> get $name\$;');
    };
  }

  String colMapper(InterfaceType type) => 'List<$type>';

  final writeAtom = getWriter(kAtomName);
  final writeAtomOption = getWriter(kAtomOptionName);
  final writeAtomDefault = getWriter(kAtomDefaultName);
  final writeLink = getWriter(kLinkName);
  final writeLinkOption = getWriter(kLinkOptionName);
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
  final names =
      struct.fields.map((e) => 'required this.${e.name}\$').join(', ');
  if (names.isEmpty) {
    return '''
    ${child(struct.name)}._(this.id) : super._();
    ''';
  }
  return '''
  ${child(struct.name)}._(this.id, {$names}) : super._();
  ''';
}

String emitChildDecls(Struct struct) {
  final sb = StringBuffer();

  void write(String wrapperName, InterfaceType inner, String name) {
    // remove \$ postfix of the inner type
    final String innerString;
    if (inner.toString().endsWith('\$')) {
      innerString = inner.toString().substring(0, inner.toString().length - 1);
    } else {
      innerString = inner.toString();
    }
    sb.writeln(
      '''
      @override
      final $wrapperName<$innerString> $name\$;
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

String emitDeleteFunctionApi(Struct struct) {
  return '''
  void delete();
  ''';
}

String emitDeleteFunctionApiImpl(Struct struct) {
  return '''
  @override
  void delete() => const ${repository(struct.name)}().delete(this);
  ''';
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

        ${emitDeleteFunctionApi(struct)}
      }

      final class ${child(struct.name)} extends ${struct.name} {
        @override
        final Id id;

        ${emitChildCstors(struct)} 

        ${emitChildFactory(struct)} 

        ${emitChildDecls(struct)}

        ${emitDeleteFunctionApiImpl(struct)}
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
