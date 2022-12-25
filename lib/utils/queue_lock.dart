import 'dart:async';

/// Java-style mutex lock with exception handling (probably more efficient).
/// See: https://github.com/tekartik/synchronized.dart/blob/master/synchronized/lib/src/basic_lock.dart
class QueueLock {
  /// The last element in the queue.
  /// If all tasks have been completed, this will be marked `null`.
  Future<void>? _last;

  /// Returns if there is no task remaining in the queue.
  bool get cleared => _last == null;

  /// Wait for the current last task to complete.
  /// If there is no task remaining in the queue, returns `null`.
  Future<void>? wait() => _last;

  /// Request [operation] to be run exclusively.
  ///
  /// If lock is currently locked, there will be a coroutine switch point
  /// between the caller and the beginning of [operation].
  Future<T> enqueue<T>(Future<T> Function() operation) async {
    // (Atomic) Push a `Completer` to the end of the queue.
    final prev = wait();
    final curr = Completer<void>.sync();
    _last = curr.future;
    // Wait for the previous task in the queue to complete.
    // There should not be any errors as we never used `Completer.completeError()`.
    if (prev != null) await prev;
    try {
      // Execute operation.
      return await operation();
      // Any errors are propagated back to the returned `Future`.
    } finally {
      // (Atomic) If no new task was pushed to the queue (i.e. `curr` is still
      // the last one), mark the lock as released. Otherwise mark the current
      // task as completed and newer tasks will start immediately.
      if (_last == curr.future) _last = null;
      curr.complete();
    }
  }
}
