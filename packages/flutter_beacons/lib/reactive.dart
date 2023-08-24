abstract interface class Observable<T> {
  void register(Node ref);
  void notify();
  T peek();
  T get(Node ref);
}

class Node {
  List<Node> _in = [];
  List<WeakReference<Node>> _out = [];

  void notify() {
    _in.clear();
    final out = _out;
    _out = [];
    for (final weak in out) {
      final node = weak.target;
      if (node != null) {
        node.notify();
      }
    }
  }

  void register(Node ref) {
    ref._in.add(this);
    _out.add(WeakReference(ref));
  }
}

class Active<T> extends Node implements Observable<T> {
  T value;

  Active(this.value);

  @override
  T get(Node ref) {
    register(ref);
    return peek();
  }

  @override
  T peek() {
    return value;
  }

  void set(T value) {
    this.value = value;
    notify();
  }
}

class Reactive<T> extends Node implements Observable<T> {
  late T value;
  bool notified = false;
  T Function(Node ref) recompute;

  Reactive(this.recompute) {
    value = recompute(this);
  }

  @override
  void notify() {
    super.notify();
    notified = true;
  }

  @override
  T get(Node ref) {
    register(ref);
    return peek();
  }

  @override
  T peek() {
    if (notified) {
      notified = false;
      value = recompute(this);
    }
    return value;
  }

  void set(T Function(Node ref) recompute) {
    this.recompute = recompute;
    notify();
  }
}

class Observer extends Node {
  void Function()? callback;

  Observer(this.callback);

  @override
  void notify() {
    super.notify();
    callback?.call();
  }

  void set(void Function()? callback) {
    this.callback = callback;
  }
}
