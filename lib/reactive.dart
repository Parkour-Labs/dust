import 'package:meta/meta.dart';

export 'reactive/hooks.dart';
export 'reactive/value_listenable.dart';
export 'reactive/widgets.dart';

/// A notifiable object.
abstract interface class Observer {
  /// Registers a dependency.
  ///
  /// This function is useful for implementing the interface, but not commonly
  /// called from outside.
  void depend(Observable o);

  /// Visits this observer, letting it register additional post-visit callbacks
  /// in a given list.
  ///
  /// This function is useful for implementing the interface, but not commonly
  /// called from outside.
  void visit(List<void Function()> posts);
}

extension ObserverExtension on Observer {
  /// Notifies this observer.
  void notify() {
    final posts = <void Function()>[];
    visit(posts);
    for (final post in posts) {
      post();
    }
  }
}

/// An observable value.
abstract interface class Observable<T> {
  /// Two-way onnects with observer [o].
  ///
  /// This function is useful for implementing the interface, but not commonly
  /// called from outside.
  void connect(Observer o);

  /// Retrieves value, optionally connecting with observer [o].
  ///
  /// This is the common part of [watch] and [peek], and is more composable
  /// sometimes.
  T get(Observer? o);
}

extension ObservableExtension<T> on Observable<T> {
  /// Retrieves value and connects with observer [o].
  T watch(Observer o) => get(o);

  /// Retrieves value only once.
  T peek() => get(null);
}

/// An observable mutable value.
abstract interface class ObservableMut<T> extends Observable<T> {
  void set(T value);
}

/// An observable list.
abstract interface class ObservableList<T> extends Observable<List<T>> {
  // int length(Observer? o);
  T? element(int index, Observer? o);
}

/// An observable mutable list.
abstract interface class ObservableMutList<T> extends ObservableList<T> {
  void insert(int index, T value);
  void update(int index, T value);
  void remove(int index);
}

/// An observable set or multiset.
abstract interface class ObservableSet<T> extends Observable<List<T>> {
  // int length(Observer? o);
}

/// An observable mutable set or multiset.
abstract interface class ObservableMutSet<T> extends ObservableSet<T> {
  void insert(T value);
  void remove(T value);
}

/// An observable map.
abstract interface class ObservableMap<S, T> extends Observable<List<(S, T)>> {
  // int length(Observer? o);
  T? element(S key, Observer? o);
}

/// An observable mutable map.
abstract interface class ObservableMutMap<S, T> extends ObservableMap<S, T> {
  void update(S key, T value);
  void remove(S key);
}

/// The "default" partial implementation of [Observer].
abstract mixin class ObserverMixin implements Observer {
  final List<Observable> _in = [];

  @override
  void depend(Observable o) {
    _in.add(o);
  }

  @mustCallSuper
  @override
  void visit(List<void Function()> posts) {
    _in.clear();
  }
}

/// The "default" partial implementation of [Observable].
abstract mixin class ObservableMixin<T> implements Observable<T> {
  final List<WeakReference<Observer>> _out = [];

  @override
  void connect(Observer o) {
    _out.add(WeakReference(o));
    o.depend(this);
  }

  /// Visits all observers.
  void visitAll(List<void Function()> posts) {
    final out = List<WeakReference<Observer>>.from(_out);
    _out.clear();
    for (final weak in out) {
      weak.target?.visit(posts);
    }
  }
}

extension ObservableMixinExtension<T> on ObservableMixin<T> {
  /// Notifies all observers.
  void notifyAll() {
    final posts = <void Function()>[];
    visitAll(posts);
    for (final post in posts) {
      post();
    }
  }
}

/// A simple independent value that is [ObservableMut].
class Active<T> with ObservableMixin<T> implements ObservableMut<T> {
  T _value;

  Active(this._value);

  @override
  T get(Observer? o) {
    if (o != null) connect(o);
    return _value;
  }

  @override
  void set(T value) {
    this._value = value;
    notifyAll();
  }
}

/// A value computed and cached from other [Observable]s.
class Reactive<T> with ObservableMixin<T>, ObserverMixin implements Observable<T>, Observer {
  T Function(Observer o) _recompute;
  bool _dirty = false;
  late T _value;

  Reactive(this._recompute) {
    _value = _recompute(this);
  }

  @override
  void visit(List<void Function()> posts) {
    super.visit(posts);
    if (!_dirty) {
      _dirty = true;
      visitAll(posts);
    }
  }

  @override
  T get(Observer? o) {
    if (_dirty) {
      _dirty = false;
      _value = _recompute(this);
    }
    if (o != null) connect(o);
    return _value;
  }

  void set(T Function(Observer o) recompute) {
    this._recompute = recompute;
    notify();
  }
}

/// Executes a function whenever a given [Observable] is notified.
class Trigger<T> with ObserverMixin implements Observer {
  final Observable<T> _observable;
  final void Function(T value) _callback;
  bool _visited = false;

  Trigger(this._observable, this._callback) {
    _callback(_observable.get(this));
  }

  @override
  void visit(List<void Function()> posts) {
    super.visit(posts);
    if (!_visited) {
      _visited = true;
      posts.add(() {
        _visited = false;
        _callback(_observable.get(this));
      });
    }
  }
}

/// Executes a function whenever a given [Observable] is notified.
///
/// This variant also remembers the previous value, so the function can test
/// if the value has actually changed or not.
class Comparer<T> with ObserverMixin implements Observer {
  final Observable<T> _observable;
  final void Function(T? prev, T curr) _callback;
  T? _prev;
  bool _visited = false;

  Comparer(this._observable, this._callback) {
    final curr = _observable.get(this);
    _callback(_prev, curr);
    _prev = curr;
  }

  @override
  void visit(List<void Function()> posts) {
    super.visit(posts);
    if (!_visited) {
      _visited = true;
      posts.add(() {
        _visited = false;
        final curr = _observable.get(this);
        _callback(_prev, curr);
        _prev = curr;
      });
    }
  }
}
