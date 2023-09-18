import 'package:flutter/foundation.dart';

import '../reactive.dart';

extension AsValueListenableExtension<T> on Observable<T> {
  /// Converts an [Observable] into a [ValueListenable].
  ValueListenable<T> valueListenable() => _AsValueListenable(this);
}

extension AsObservableExtension<T> on ValueListenable<T> {
  /// Converts a [ValueListenable] into an [Observable].
  Observable<T> observable() => _AsObservable(this);
}

class _AsValueListenable<T> with ObserverMixin implements Observer, ValueListenable<T> {
  final Observable<T> _observable;
  final List<VoidCallback> _callbacks = [];
  late T _value;
  bool _visited = false;

  _AsValueListenable(this._observable) {
    _value = _observable.get(this);
  }

  @override
  void visit(List<void Function()> posts) {
    if (!_visited) {
      _visited = true;
      posts.add(() {
        _visited = false;
        _value = _observable.get(this);
      });
      posts.addAll(_callbacks);
    }
  }

  @override
  void addListener(VoidCallback listener) => _callbacks.add(listener);

  @override
  void removeListener(VoidCallback listener) => _callbacks.remove(listener);

  @override
  T get value => _value;
}

class _AsObservable<T> implements Observable<T> {
  final ValueListenable<T> _listenable;

  _AsObservable(this._listenable);

  @override
  void connect(Observer o) {
    final weak = WeakReference(o);
    _listenable.addListener(() => weak.target?.notify());
  }

  @override
  T get(Observer? o) {
    if (o != null) connect(o);
    return _listenable.value;
  }
}
