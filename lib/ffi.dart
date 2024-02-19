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
import 'package:flutter/foundation.dart';

import 'ffi/native_bindings.dart';

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
}
