import 'dart:convert' show utf8;
import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

Never fail(String msg, Element element) {
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
  if (type.nullabilitySuffix != NullabilitySuffix.none) fail('Type `$type` should not be nullable.', elem);
  final alias = type.alias;
  if (alias != null) {
    return resolve(alias.element.aliasedType, elem);
  } else {
    if (type is! InterfaceType) fail('Type `$type` should be an object type (class or interface).', elem);
    return type;
  }
}

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
      if (type.isDartCoreRecord) {
        final revivable = reader.revive();
        final positional = revivable.positionalArguments.map(recursive).join(', ');
        return '($positional)';
      } else if (type.isDartCoreEnum) {
        final revivable = reader.revive();
        final accessor = revivable.accessor;
        return accessor;
      } else {
        final revivable = reader.revive();
        final name = type.element.name;
        final dot = (revivable.accessor != '') ? '.' : '';
        final accessor = revivable.accessor;
        final positional = revivable.positionalArguments.map(recursive).join(', ');
        final comma = revivable.namedArguments.isNotEmpty ? ', ' : '';
        final named = revivable.namedArguments.entries.map((e) => '${e.key}: ${recursive(e.value)}').join(', ');
        return '$name$dot$accessor($positional$comma$named)';
      }
    }
    fail('Unsupported constant value $value', elem);
  }

  return recursive(value);
}
