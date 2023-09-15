abstract interface class Observable<T> {
  void register(Node? o);
  void notify();
  T get(Node? o);
}

class Node {
  final List<Node> _in = [];
  List<WeakReference<Node>> _out = [];

  void pre(List<void Function()> callbacks) {
    _in.clear();
    final out = _out;
    _out = [];
    for (final weak in out) {
      weak.target?.pre(callbacks);
    }
  }

  void notify() {
    final callbacks = <void Function()>[];
    pre(callbacks);
    for (final callback in callbacks) {
      callback();
    }
  }

  void register(Node? o) {
    if (o != null) {
      o._in.add(this);
      _out.add(WeakReference(o));
    }
  }
}

class Active<T> extends Node implements Observable<T> {
  T _value;

  Active(this._value);

  @override
  T get(Node? o) {
    register(o);
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
  T Function(Node o) _recompute;

  Reactive(this._recompute) {
    _value = _recompute(this);
  }

  @override
  void pre(List<void Function()> callbacks) {
    super.pre(callbacks);
    _notified = true;
  }

  @override
  T get(Node? o) {
    if (_notified) {
      _notified = false;
      _value = _recompute(this);
    }
    register(o);
    return _value;
  }

  void set(T Function(Node o) recompute) {
    this._recompute = recompute;
    notify();
  }
}

class Observer extends Node {
  void Function(Node o)? _callback;

  Observer(this._callback) {
    _callback?.call(this);
  }

  @override
  void pre(List<void Function()> callbacks) {
    super.pre(callbacks);
    callbacks.add(() => _callback?.call(this));
  }

  void set(void Function(Node self)? callback) {
    _callback = callback;
  }
}
