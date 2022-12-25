import 'package:meta/meta.dart';

/// Sometimes we need to store graph structures with undirected (double) edges. In this case, the existence
/// of an incoming edge can make the node remain reachable for a long time, preventing its memory to be freed.
/// At such, it is necessary to write a `dispose()` function for each node that separates it from the rest of the graph,
/// so that their memory can be eventually freed by the garbage collector.
///
/// [Disposable] is a mixin that tries to make this easier.
mixin Disposable {
  bool _disposed = false;

  /// Check if node is marked as `disposed`.
  bool get disposed => _disposed;

  /// Marks node as `disposed`.
  @mustCallSuper
  void dispose() {
    assert(!_disposed);
    _disposed = true;
  }

  /// Convenient helper function for disposing members.
  ///
  /// Usage example:
  ///
  /// ```dart
  /// class MyObject with Disposable {
  ///   final Active<String> name = ...;
  ///   final Active<String?> description = ...;
  ///   final Reactive<String> combined = ...;
  ///
  ///   @override
  ///   void dispose() {
  ///     super.dispose();
  ///     disposes([name, description, combined]);
  ///   }
  /// }
  /// ```
  void disposes(Iterable<Disposable> members) {
    for (final member in members) {
      member.dispose();
    }
  }
}
