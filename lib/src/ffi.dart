// Copyright 2024 ParkourLabs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

export 'ffi/native_bindings.dart';
export 'ffi/native_structs.dart';

import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'ffi/native_bindings.dart';
import 'store.dart';

class Ffi {
  static final bindings = NativeBindings(library);
  static final library = switch (defaultTargetPlatform) {
    TargetPlatform.android => DynamicLibrary.open('libdust.so'),
    TargetPlatform.iOS => DynamicLibrary.process(),
    TargetPlatform.macOS => DynamicLibrary.process(),
    TargetPlatform.linux => DynamicLibrary.open('libdust.so'),
    TargetPlatform.windows => DynamicLibrary.open('dust.dll'),
    _ => throw UnimplementedError('Unsupported platform'),
  };

  static void init(String databasePath, List<Repository> repositories) {
    for (final repository in repositories) {
      final schema = repository.init();
      for (final label in schema.stickyNodes) {
        bindings.dust_add_sticky_node(label);
      }
      for (final label in schema.stickyAtoms) {
        bindings.dust_add_sticky_atom(label);
      }
      for (final label in schema.stickyEdges) {
        bindings.dust_add_sticky_edge(label);
      }
      for (final label in schema.acyclicEdges) {
        bindings.dust_add_acyclic_edge(label);
      }
    }
    final ptr = databasePath.toNativeUtf8(allocator: malloc);
    bindings.dust_open(ptr.length, ptr.cast<Uint8>());
    malloc.free(ptr);
  }
}
