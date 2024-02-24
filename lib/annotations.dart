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

export 'src/serializer.dart' show Serializer;

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

/// The annotation for providing a default value to a field. We would love to
/// call it `@Default`, but that may cause potential naming collisions with
/// the `freezed` package, which users may use.
class Dft<T> {
  /// The default value for this field.
  final T defaultValue;

  const Dft(this.defaultValue);
}

/// The annotation for marking a field as a link to another node. If the
/// [backTo] is specified, then this link is a backlink to another model that
/// links to this model. Otherwise, this link is a regular link to another
/// model.
///
/// TODO: think of a better name.
class Ln {
  final String? backTo;
  const Ln({this.backTo});
}

class Glb {
  const Glb();
}

/// Traditional SQL databases have the ability to enforce "referential
/// integrity": you will never get unexpected null values or broken links when
/// reading non-nullable fields and relationships. For example, if a folder's
/// parent field is non-nullable, deleting a folder that contains other folders
/// will either fail ("on delete cancel" mode) or result in all sub-folders
/// being deleted ("on delete cascade" mode).
///
/// In Qinhuai, due to the presence of concurrent modifications from different
/// clients, the "on delete cancel" strategy is not possible - there is always
/// a possibility, that another client has just directed (on their copy) a
/// non-nullable edge to the object you are about to delete. Moreover, the
/// storage format of Qinhuai is not optimal when it comes to checking
/// traditional referential integrity constraints (in the form of "all objects
/// of type A always have non-nullable fields/links of types [X, Y, Z]"). So
/// this model is proposed instead:
///
/// - Every atom and link must connect non-deleted nodes; any violation causes
///   the atom or link to be deleted.
/// - You can declare certain types of nodes, atoms and edges to be "sticky".
///   - Once created, "sticky" nodes can never have their label changed; any
///     violation causes the node to be deleted.
///   - Once created, "sticky" atoms and edges can never have their src or
///     label changed; any violation causes the original src node to be
///     deleted.
///   - In other words, either all "sticky" things remain "stuck" to the node,
///     or the node is completely erased.
/// - Qinhuai will delete and delete, until no further violations of rules
///   exist (or all data has been deleted).
///
/// This process is the last step before committing a transaction, so a saved
/// database will always be in a consistent state. The additional deletes are
/// recorded as regular operations, so that they can be synchronised. This
/// will not affect convergence: only finitely many additional deletes can be
/// appended (there are only finitely many things to delete...)
class Sticky {
  const Sticky();
}

class Acyclic {
  const Acyclic();
}
