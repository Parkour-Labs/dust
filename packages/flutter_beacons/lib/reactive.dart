abstract interface class Observable<T> {
  void register(WeakReference<Node> ref);
  void notify();
  T peek();
  T get(WeakReference<Node> ref);
}

class Node {
  List<WeakReference<Node>> _out = [];

  WeakReference<Node> weak() {
    return WeakReference(this);
  }

  void notify() {
    final out = _out;
    _out = [];
    for (final weak in out) {
      final node = weak.target;
      if (node != null) {
        node.notify();
      }
    }
  }

  void register(WeakReference<Node> ref) {
    _out.add(ref);
  }
}

class Active<T> extends Node implements Observable<T> {
  T value;

  Active(this.value);

  @override
  T get(WeakReference<Node> ref) {
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
  T Function(WeakReference<Node> ref) recompute;

  Reactive(this.recompute) {
    value = recompute(weak());
  }

  @override
  void notify() {
    super.notify();
    notified = true;
  }

  @override
  T get(WeakReference<Node> ref) {
    register(ref);
    return peek();
  }

  @override
  T peek() {
    if (notified) {
      notified = false;
      value = recompute(weak());
    }
    return value;
  }

  void set(T Function(WeakReference<Node> ref) recompute) {
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
