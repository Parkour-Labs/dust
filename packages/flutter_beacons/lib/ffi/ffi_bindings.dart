// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

class FFIBindings {
  /// Holds the symbol lookup function.
  final Pointer<T> Function<T extends NativeType>(String symbolName) _lookup;

  /// The symbols are looked up in [dynamicLibrary].
  FFIBindings(DynamicLibrary dynamicLibrary) : _lookup = dynamicLibrary.lookup;

  /// The symbols are looked up with [lookup].
  FFIBindings.fromLookup(Pointer<T> Function<T extends NativeType>(String symbolName) lookup) : _lookup = lookup;

  late final add = _lookup<NativeFunction<Uint64 Function(Uint64, Uint64)>>('add').asFunction<int Function(int, int)>();
}
