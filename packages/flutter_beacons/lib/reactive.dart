abstract interface class Observable<T> {
  void register(Node? o);
  void notify();
  T get(Node? o);
}

class Node {
  List<Node> _in = [];
  List<WeakReference<Node>> _out = [];

  void notify() {
    _in.clear();
    final out = _out;
    _out = [];
    for (final weak in out) {
      weak.target?.notify();
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
  void notify() {
    super.notify();
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
  void notify() {
    super.notify();
    _callback?.call(this);
  }

  void set(void Function(Node self)? callback) {
    this._callback = callback;
  }
}
