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

import 'src/serializer.dart';
export 'src/serializer.dart';

class Model {
  const Model();
}

class Serializable<T> {
  final Serializer<T> serializer;
  const Serializable(this.serializer);
}

class Default<T> {
  final T defaultValue;
  const Default(this.defaultValue);
}

class Backlink {
  final String name;
  const Backlink(this.name);
}

class Transient {
  const Transient();
}

class Global {
  const Global();
}

class Constraints {
  final bool sticky;
  final bool acyclic;
  const Constraints({this.sticky = false, this.acyclic = false});
}
