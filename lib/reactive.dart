export 'reactive/widgets.dart';
export 'reactive/hooks.dart';
export 'reactive/value_listenable.dart';

/// A notifiable object.
abstract interface class Observer {
  /// Registers a dependency.
  void depend(Observable o);

  /// Visits this observer.
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
  /// Two-way connects with observer [o].
  void connect(Observer o);

  /// Retrieves value, optionally two-way connecting with observer [o].
  T get(Observer? o);
}

/// An observable mutable value.
abstract interface class ObservableMut<T> extends Observable<T> {
  void set(T value);
}

/// An observable list.
abstract interface class ObservableList<T> extends Observable<Iterable<T>> {
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
abstract interface class ObservableSet<T> extends Observable<Iterable<T>> {
  // int length(Observer? o);
}

/// An observable mutable set or multiset.
abstract interface class ObservableMutSet<T> extends ObservableSet<T> {
  void insert(T value);
  void remove(T value);
}

/// An observable map.
abstract interface class ObservableMap<S, T> extends Observable<Iterable<(S, T)>> {
  // int length(Observer? o);
  T? element(S key, Observer? o);
}

/// An observable mutable map.
abstract interface class ObservableMutMap<S, T> extends ObservableMap<S, T> {
  void update(S key, T value);
  void remove(S key);
}

/// The "default implementation" of [Observer].
abstract mixin class ObserverMixin implements Observer {
  final List<Observable> _in = [];

  @override
  void depend(Observable o) {
    _in.add(o);
  }
}

/// The "default implementation" of [Observable].
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

extension ObservableExtension<T> on ObservableMixin<T> {
  /// Notifies all observers.
  void notifyAll() {
    final posts = <void Function()>[];
    visitAll(posts);
    for (final post in posts) {
      post();
    }
  }
}

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

class Reactive<T> with ObservableMixin<T>, ObserverMixin implements Observable<T>, Observer {
  T Function(Observer o) _recompute;
  bool _dirty = false;
  late T _value;

  Reactive(this._recompute) {
    _value = _recompute(this);
  }

  @override
  void visit(List<void Function()> posts) {
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

class Trigger<T> with ObserverMixin implements Observer {
  final Observable<T> _observable;
  final void Function(T value) _callback;
  bool _visited = false;

  Trigger(this._observable, this._callback) {
    _callback(_observable.get(this));
  }

  @override
  void visit(List<void Function()> posts) {
    if (!_visited) {
      _visited = true;
      posts.add(() {
        _visited = false;
        _callback(_observable.get(this));
      });
    }
  }
}
