export 'ffi/native_bindings.dart';
export 'ffi/native_structs.dart';

import 'dart:ffi';
import 'package:flutter/foundation.dart';

import 'ffi/native_bindings.dart';

class Ffi {
  static final bindings = NativeBindings(library);
  static final library = switch (defaultTargetPlatform) {
    TargetPlatform.android => DynamicLibrary.open('libqinhuai.so'),
    TargetPlatform.iOS => DynamicLibrary.process(),
    TargetPlatform.macOS => DynamicLibrary.process(),
    TargetPlatform.linux => DynamicLibrary.open('libqinhuai.so'),
    TargetPlatform.windows => DynamicLibrary.open('qinhuai.dll'),
    _ => throw UnimplementedError('Unsupported platform'),
  };
}
