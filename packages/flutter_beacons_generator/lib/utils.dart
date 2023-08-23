import 'dart:convert' show utf8;
import 'package:analyzer/dart/element/element.dart';
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
