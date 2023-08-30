abstract interface class Observable<T> {
  void register(Node? ref);
  void notify();
  T get(Node? ref);
}

class Node {
  Set<Node> _in = {};
  Set<WeakReference<Node>> _out = {};

  void notify() {
    _in.clear();
    final out = _out;
    _out = {};
    for (final weak in out) {
      final node = weak.target;
      if (node != null) {
        node.notify();
      }
    }
  }

  void register(Node? ref) {
    if (ref != null) {
      ref._in.add(this);
      _out.add(WeakReference(ref));
    }
  }
}

class Active<T> extends Node implements Observable<T> {
  T _value;

  Active(this._value);

  @override
  T get(Node? ref) {
    register(ref);
    return _value;
  }

  void set(T value) {
    this._value = value;
    notify();
  }
}

class Reactive<T> extends Node implements Observable<T> {
  late T _value;
  bool _notified = false;
  T Function(Node ref) _recompute;

  Reactive(this._recompute) {
    _value = _recompute(this);
  }

  @override
  void notify() {
    super.notify();
    _notified = true;
  }

  @override
  T get(Node? ref) {
    if (_notified) {
      _notified = false;
      _value = _recompute(this);
    }
    register(ref);
    return _value;
  }

  void set(T Function(Node ref) recompute) {
    this._recompute = recompute;
    notify();
  }
}

class Observer extends Node {
  void Function()? _callback;

  Observer(this._callback);

  @override
  void notify() {
    super.notify();
    _callback?.call();
  }

  void set(void Function()? callback) {
    this._callback = callback;
  }
}
