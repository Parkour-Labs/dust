import 'package:meta/meta.dart';

import '../basic/disposable.dart';
export '../basic/disposable.dart';

@immutable
class Ref {
  final Sink sink;
  const Ref.of(this.sink);
}

/// Adds a dependency edge from [source] to [sink].
void _addEdge(Source source, Sink sink) {
  assert(!source.disposed && !sink.disposed);
  source._dependents.add(sink);
  sink._dependencies.add(source);
}

/// Removes a dependency edge from [source] to [sink].
void _removeEdge(Source source, Sink sink) {
  assert(source._dependents.contains(sink) && sink._dependencies.contains(source));
  source._dependents.remove(sink);
  sink._dependencies.remove(source);
}

/// This part deals with dependents.
mixin Source on Disposable {
  final List<Sink> _dependents = [];

  Iterable<Sink> get dependents => _dependents;

  /// Adds one dependent to this node.
  void addDependent(Sink sink) => _addEdge(this, sink);

  /// Adds dependents to this node.
  void addDependents(Iterable<Sink> sinks) {
    for (final sink in sinks) {
      addDependent(sink);
    }
  }

  /// Removes one dependent of this node.
  void removeDependent(Sink sink) => _removeEdge(this, sink);

  /// Removes all dependents of this node.
  void clearDependents() {
    for (final d in _dependents) {
      d._dependencies.remove(this);
    }
    _dependents.clear();
  }

  /// If a node can have dependents, the default implementation of notify is to notify all dependents.
  @mustCallSuper
  void notify() {
    for (final d in dependents) {
      d.notify();
    }
  }
}

/// This part deals with dependencies.
mixin Sink on Disposable {
  final List<Source> _dependencies = [];

  Iterable<Source> get dependencies => _dependencies;

  /// Adds one dependency to this node.
  void addDependency(Source source) => _addEdge(source, this);

  /// Adds dependencies to this node.
  void addDependencies(Iterable<Source> sources) {
    for (final source in sources) {
      addDependency(source);
    }
  }

  /// Removes one dependency of this node.
  void removeDependency(Source source) => _removeEdge(source, this);

  /// Removes all dependencies of this node.
  void clearDependencies() {
    for (final d in _dependencies) {
      d._dependents.remove(this);
    }
    _dependencies.clear();
  }

  /// If a node can have dependencies, it should be prepared to handle notifications.
  void notify();
}

/// A signal node can have dependents.
class Signal with Disposable, Source {
  @override
  void dispose() {
    super.dispose();
    clearDependents();
  }
}

/// A watcher node can have dependencies.
/// The [g] function is eagerly executed every time one of the dependencies is marked as dirty.
class Watcher with Disposable, Sink {
  final void Function() g;

  Watcher(this.g);

  @override
  void dispose() {
    super.dispose();
    clearDependencies();
  }

  @override
  void notify() => g();

  /// Update dependencies using function [f].
  T recompute<T>(T Function(Ref) f) {
    // Remove old dependencies.
    clearDependencies();
    // Create new dependencies.
    return f(Ref.of(this));
  }
}

/// An active value node can have dependents.
class Active<T> with Disposable, Source {
  T _value;

  Active(T value) : _value = value;
  Active.copy(Active<T> r) : _value = r._value;

  @override
  void dispose() {
    super.dispose();
    clearDependents();
  }

  T get(Ref? ref) {
    if (ref != null) addDependent(ref.sink);
    return _value;
  }

  void set(T value) {
    _value = value;
    notify();
  }
}

/// A reactive node can have both dependencies and dependents.
class Reactive<T> with Disposable, Source, Sink {
  bool _dirty = false;
  bool _recomputing = false;
  late T Function(Ref) _f;
  late T _value;

  Reactive(T Function(Ref ref) f) {
    _f = f;
    notify();
  }

  @override
  void dispose() {
    super.dispose();
    clearDependents();
    clearDependencies();
  }

  T get(Ref? ref) {
    if (ref != null) addDependent(ref.sink);
    if (_dirty) recompute();
    return _value;
  }

  void set(T Function(Ref ref) f) {
    _f = f;
    notify();
  }

  @override
  void notify() {
    if (_dirty) return;
    _dirty = true;
    super.notify();
  }

  T recompute() {
    assert(!_recomputing, 'Circular dependency detected.');
    // Remove old dependencies.
    clearDependencies();
    // Create new dependencies.
    try {
      _recomputing = true;
      _value = _f(Ref.of(this));
    } finally {
      _recomputing = false;
    }
    // Unmark dirty flag.
    _dirty = false;
    return _value;
  }
}
