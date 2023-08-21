import 'dart:ffi';
import 'package:flutter/foundation.dart';
import 'package:flutter_beacons/ffi/ffi_bindings.dart';

class Ffi {
  final FfiBindings beaconsBindings;

  Ffi._(DynamicLibrary dylib) : beaconsBindings = FfiBindings(dylib);

  /// The global FFI bindings.
  static Ffi? _ffi;

  /// Obtains the global FFI bindings.
  static Ffi instance() => _ffi ??= create();

  static Ffi create() {
    final DynamicLibrary dylib;
    switch (defaultTargetPlatform) {
      case TargetPlatform.linux:
      case TargetPlatform.android:
        dylib = DynamicLibrary.open("libnative.so");
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        dylib = DynamicLibrary.open("libnative.dylib");
        break;
      case TargetPlatform.windows:
        dylib = DynamicLibrary.open("native.dll");
        break;
      default:
        throw UnimplementedError();
    }
    return Ffi._(dylib);
  }
}
