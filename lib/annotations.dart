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

/// The annotation for a model class. A model is an object that can be
/// serialized and persisted to the database.
class Model {
  const Model({
    this.generateForwarding = false,
  });

  /// This field is used to indicate whether if the generated model would have
  /// getter and setter methods forwarded directly to the underlying fields. It
  /// is useful if you want to save some typing. If this field is set to true,
  /// then in stead of having:
  ///
  /// ```dart
  /// // gets the name of the todo.
  /// final name = todo.name$.get(null);
  /// // sets the name of the todo.
  /// todo.name$.set('New Name');
  /// // iterate through the tags of the todo
  /// for (final tag in todo.tags$.get(null)) {
  ///   print(tag.name.get(null));
  /// }
  /// ```
  ///
  /// You can have:
  ///
  /// ```dart
  /// // gets the name of the todo.
  /// final name = todo.name;
  /// // sets the name of the todo.
  /// todo.name = 'New Name';
  /// // iterate through the tags of the todo
  /// for (final tag in todo.tags) {
  ///   print(tag.name);
  /// }
  /// ```
  ///
  /// Note that the `$` postfixed fields are still generated and usable, and
  /// you would want to use them if you want to subscribe to the changes of
  /// the fields. Enabling this flag may lead to potential bugs if you forget
  /// to subscribe to the observable fields when you need reactivity.
  ///
  /// This flag is set to false by default, meaning that `dust` will only
  /// generate the fields, but not the convenient getters and setters. The
  /// rationale behind this is that we want to force users to call the `get`
  /// method, which has a required but nullable parameter `Observer`. This
  /// will reduce the likelihood of developer mistakes for not subscribing to
  /// the observable fields.
  ///
  /// Currently we do not support fine-grained control over which fields to
  /// opt-in for forwarding and which to opt-out. Therefore, this method shall
  /// be applied to all the fields in the model.
  final bool generateForwarding;
}

class Serializable<T> {
  final Serializer<T> serializer;
  const Serializable(this.serializer);
}

/// The annotation for providing a default value to a field. We would love to
/// call it `@Default`, but that may cause potential naming collisions with
/// the `freezed` package, which users may use.
class DustDft<T> {
  /// The default value for this field.
  final T defaultValue;

  const DustDft(this.defaultValue);
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
