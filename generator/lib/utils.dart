import 'dart:convert' show utf8;
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Never fail(String msg, Element? element) {
  throw InvalidGenerationSourceError(msg, element: element);
}

/// Hashes the string `s` to a value of desired.
int fnv64Hash(String s) {
  const int kPrime = 1099511628211;
  const int kBasis = -3750763034362895579; // 14695981039346656037 - 2^64
  var res = kBasis;
  for (final c in utf8.encode(s)) {
    res = (res * kPrime) ^ c;
  }
  return res;
}

/// Resolves any type aliases and ensures that [type] is a non-nullable object type.
InterfaceType resolve(DartType type, Element elem) {
  if (type.nullabilitySuffix != NullabilitySuffix.none) {
    fail('Type `$type` should not be nullable.', elem);
  }
  final alias = type.alias;
  if (alias != null) {
    return resolve(alias.element.aliasedType, elem);
  } else {
    if (type is! InterfaceType) {
      fail('Type `$type` should be an object type (class or interface).', elem);
    }
    return type;
  }
}

const kRecordChecker = TypeChecker.fromRuntime(Record);
const kEnumChecker = TypeChecker.fromRuntime(Enum);

/// Prints code for generating the given constant value.
String construct(DartObject? value, Element elem) {
  String recursive(DartObject? value) {
    final reader = ConstantReader(value);
    final rawType = value?.type;
    if (reader.isNull) {
      return 'null';
    } else if (reader.isBool) {
      return '${reader.boolValue}';
    } else if (reader.isDouble) {
      return '${reader.doubleValue}';
    } else if (reader.isInt) {
      return '${reader.intValue}';
    } else if (reader.isString) {
      return 'r\'${reader.stringValue}\'';
    } else if (reader.isSymbol) {
      return '${reader.symbolValue}';
    } else if (reader.isType) {
      return '${reader.typeValue}';
    } else if (reader.isList) {
      return '[${reader.listValue.map(recursive).join(', ')}]';
    } else if (reader.isSet) {
      return '{${reader.setValue.map(recursive).join(', ')}}';
    } else if (reader.isMap) {
      return '{${reader.mapValue.entries.map((e) => '${recursive(e.key)}: ${recursive(e.value)}').join(', ')}}';
    } else if (rawType != null) {
      final type = resolve(rawType, elem);
      final revivable = reader.revive();
      if (reader.instanceOf(kRecordChecker)) {
        final positional =
            revivable.positionalArguments.map(recursive).join(', ');
        return '($positional)';
      } else if (reader.instanceOf(kEnumChecker)) {
        final accessor = revivable.accessor;
        return accessor;
      } else {
        final name = type.element.name;
        final dot = (revivable.accessor != '') ? '.' : '';
        final accessor = revivable.accessor;
        final positional =
            revivable.positionalArguments.map(recursive).join(', ');
        final comma = (revivable.positionalArguments.isNotEmpty &&
                revivable.namedArguments.isNotEmpty)
            ? ', '
            : '';
        final named = revivable.namedArguments.entries
            .map((e) => '${e.key}: ${recursive(e.value)}')
            .join(', ');
        return '$name$dot$accessor($positional$comma$named)';
      }
    }
    fail('Unsupported constant value $value', elem);
  }

  return recursive(value);
}

extension ElementX on Element {
  /// Adapted from [freezed](https://github.com/rrousselGit/freezed/blob/c78465c720b6f98c6e6f2f02504b899668fea530/packages/freezed/lib/src/utils.dart#L25).
  ///
  /// Tries to read the AST node for this element. If can't be found, returns
  /// null.
  ///
  /// TODO: better error handling than null
  Future<AstNode?> getAstNodeOrNull(BuildStep buildStep) async {
    if (library == null) {
      return null;
    }
    var lib = library!;
    while (true) {
      try {
        final s = lib.session;
        final res = s.getParsedLibraryByElement(lib) as ParsedLibraryResult?;
        return res?.getElementDeclaration(this)?.node;
      } on InconsistentAnalysisException {
        final assetId = await buildStep.resolver.assetIdForElement(lib);
        final isLibrary = await buildStep.resolver.isLibrary(assetId);
        if (!isLibrary) return null;
        lib = await buildStep.resolver.libraryFor(assetId);
      }
    }
  }
}

extension ConstructorElementX on ConstructorElement {
  /// Adapted from [freezed](https://github.com/rrousselGit/freezed/blob/c78465c720b6f98c6e6f2f02504b899668fea530/packages/freezed/lib/src/freezed_generator.dart#L816).
  ///
  /// Tries to get the redirected name of a constructor if this
  /// [ConstructorElement] is a redirecting one. Simply checking the provided
  ///
  /// ```dart
  /// e.redirectedConstructor != null
  /// ```
  ///
  /// is not enough, as it will only return true if the redirected constructor
  /// is actually defined. However, we are going to generate code for the
  /// redirected constructor, so this would not yield the correct result.
  Future<String?> getRedirectedNameOrNull(BuildStep buildStep) async {
    final ast = await getAstNodeOrNull(buildStep);
    if (ast == null) return null;
    if (ast.endToken.stringValue != ';') return null;

    Token? equalToken = ast.endToken;
    // walk backwards to find the equal token in the ast.
    while (true) {
      if (equalToken == null || equalToken.charOffset < nameOffset) {
        return null;
      }
      if (equalToken.stringValue == '=>') return null;
      if (equalToken.stringValue == '=') break;
      equalToken = equalToken.previous;
    }

    var genericOrEndToken = equalToken;

    // walk forward to scan for the either the start of the generic type (`<`)
    // or the end of the constructor (`;`).
    while (genericOrEndToken.stringValue != '<' &&
        genericOrEndToken.stringValue != ';') {
      genericOrEndToken = genericOrEndToken.next!;
    }
    final s = source.contents.data;

    // get the redirected name
    final redirectedName = s
        .substring(equalToken.charOffset + 1, genericOrEndToken.charOffset)
        .trim();
    if (redirectedName.isEmpty) return null;
    return redirectedName;
  }
}
