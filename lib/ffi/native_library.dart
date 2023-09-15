import 'dart:ffi';
import 'package:flutter/foundation.dart';

/// Load and get the library containing all the Rust code.
DynamicLibrary getNativeLibrary() => _nativeLibrary ??= _loadNativeLibrary();

DynamicLibrary? _nativeLibrary;

DynamicLibrary _loadNativeLibrary() {
  final library = switch (defaultTargetPlatform) {
    TargetPlatform.android => DynamicLibrary.open('libbeacons.so'),
    TargetPlatform.iOS => DynamicLibrary.process(),
    TargetPlatform.macOS => DynamicLibrary.process(),
    TargetPlatform.linux => DynamicLibrary.open('libbeacons.so'),
    TargetPlatform.windows => DynamicLibrary.open('beacons.dll'),
    _ => throw UnimplementedError()
  };
  return library;
}
