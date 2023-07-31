// ignore_for_file: non_constant_identifier_names

import 'dart:ffi';

class FFIBindings {
  /// Holds the symbol lookup function.
  final Pointer<T> Function<T extends NativeType>(String symbol) _lookup;

  /// The symbols are looked up in [library].
  FFIBindings._(DynamicLibrary library) : _lookup = library.lookup;

  late final add = _lookup<NativeFunction<Uint64 Function(Uint64, Uint64)>>('add').asFunction<int Function(int, int)>();

  /// The global FFI bindings.
  static late final FFIBindings _bindings;

  /// Initialises the global FFI bindings.
  static void initialize(DynamicLibrary library) => _bindings = FFIBindings._(library);

  /// Obtains the global FFI bindings. Must be called after [FFIBindings.initialize].
  static FFIBindings instance() => _bindings;
}
