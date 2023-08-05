import 'dart:ffi';

import 'package:flutter/foundation.dart';
import 'package:flutter_beacons/ffi/ffi_bindings.dart';

class Ffi {
  static Ffi? _instance;

  static Ffi get instance {
    return _instance ??= create();
  }

  static Ffi create() {
    final DynamicLibrary dylib;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        dylib = DynamicLibrary.open("libnative.so");
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        dylib = DynamicLibrary.open("libnative.dylib");
        break;
      default:
        throw UnimplementedError();
    }
    return Ffi(dylib);
  }

  final DynamicLibrary _dylib;

  final FfiBindings _bindings;

  Ffi(DynamicLibrary dylib)
      : _dylib = dylib,
        _bindings = FfiBindings(dylib);

  DynamicLibrary get dylib => _dylib;

  FfiBindings get bindings => _bindings;
}
