import 'dart:ffi';
import 'package:flutter/foundation.dart';

/// Load and get the library containing all the Rust code.
DynamicLibrary getNativeLibrary() => _nativeLibrary ??= _loadNativeLibrary();

DynamicLibrary? _nativeLibrary;

DynamicLibrary _loadNativeLibrary() {
  final library = switch (defaultTargetPlatform) {
    TargetPlatform.android => DynamicLibrary.open('libqinhuai.so'),
    TargetPlatform.iOS => DynamicLibrary.process(),
    TargetPlatform.macOS => DynamicLibrary.process(),
    TargetPlatform.linux => DynamicLibrary.open('libqinhuai.so'),
    TargetPlatform.windows => DynamicLibrary.open('qinhuai.dll'),
    _ => throw UnimplementedError()
  };
  return library;
}
