import 'dart:async';

/// Modified `QueueLock` that allows for multiple concurrent read operations.
class RWQueueLock {
  /// The last write operation in progress.
  /// If all writes have been completed, this will be marked `null`.
  Future<void>? _lastWrite;

  /// The last read operations in progress (after the last write in progress, if any).
  /// If there is no read operation after the last write, this will be the empty set.
  final Set<Future<void>> _lastReads = {};

  /// Returns if there is no task remaining in the queue.
  bool get cleared => _lastWrite == null && _lastReads.isEmpty;

  /// Wait for the current last write operation to complete.
  /// If there is no write operation remaining in the queue, returns `null`.
  Future<void>? waitWrite() => _lastWrite;

  /// Wait for the current last task to complete.
  /// If there is no task remaining in the queue, returns `null`.
  Future<void>? wait() {
    if (_lastReads.isNotEmpty) return Future.wait(_lastReads);
    if (_lastWrite != null) return _lastWrite!;
    return null;
  }

  /// Request a read [operation] to be run exclusively with any writes.
  ///
  /// If a write operation is in progress, there will be a coroutine switch point
  /// between the caller and the beginning of [operation].
  ///
  /// After [operation] completes, the returned future immediately completes,
  /// without running any other code synchronously (except releasing lock).
  Future<T> enqueueRead<T>(Future<T> Function() operation) async {
    // (Atomic) Push a `Completer` to the end of the queue.
    final prev = waitWrite();
    final curr = Completer<void>();
    _lastReads.add(curr.future);
    // Wait for the previous write in the queue to complete.
    // There should not be any errors as we never used `Completer.completeError()`.
    if (prev != null) await prev;
    try {
      // Execute operation.
      return await operation();
      // Any errors are propagated back to the returned `Future`.
    } finally {
      // (Atomic) Mark the current read as completed.
      if (_lastReads.contains(curr.future)) _lastReads.remove(curr.future);
      curr.complete();
    }
  }

  /// Request a write [operation] to be run exclusively.
  ///
  /// If lock is currently locked, there will be a coroutine switch point
  /// between the caller and the beginning of [operation].
  ///
  /// After [operation] completes, the returned future immediately completes,
  /// without running any other code synchronously (except releasing lock).
  Future<T> enqueueWrite<T>(Future<T> Function() operation) async {
    // (Atomic) Push a `Completer` to the end of the queue.
    final prev = wait();
    final curr = Completer<void>();
    _lastWrite = curr.future;
    _lastReads.clear();
    // Wait for the previous tasks in the queue to complete.
    // There should not be any errors as we never used `Completer.completeError()`.
    if (prev != null) await prev;
    try {
      // Execute operation.
      return await operation();
      // Any errors are propagated back to the returned `Future`.
    } finally {
      // (Atomic) Mark the current write as completed.
      if (_lastWrite == curr.future) _lastWrite = null;
      curr.complete();
    }
  }
}
