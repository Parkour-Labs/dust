import 'dart:convert' show utf8;
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
