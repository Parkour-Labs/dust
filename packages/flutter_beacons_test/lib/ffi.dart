import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter_beacons/ffi/ffi_bindings.dart';

class Ffi {
  final DynamicLibrary library;
  final FfiBindings beaconsBindings;
  final FfiTestBindings beaconsTestBindings;

  Ffi._(this.library)
      : beaconsBindings = FfiBindings(library),
        beaconsTestBindings = FfiTestBindings(library);

  /// The global FFI bindings.
  static Ffi? _ffi;

  /// Obtains the global FFI bindings.
  static Ffi get instance => _ffi ??= create();

  static Ffi create() {
    final DynamicLibrary dylib = switch (defaultTargetPlatform) {
      TargetPlatform.linux || TargetPlatform.android => DynamicLibrary.open("libnative.so"),
      TargetPlatform.iOS || TargetPlatform.macOS => DynamicLibrary.open("libnative.dylib"),
      TargetPlatform.windows => DynamicLibrary.open("native.dll"),
      _ => throw UnimplementedError()
    };
    return Ffi._(dylib);
  }
}
