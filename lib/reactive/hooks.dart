import 'package:flutter_hooks/flutter_hooks.dart';

import '../reactive.dart';

/// Flutter Hooks extension that calls a function on widget state initialisation.
void useInit(void Function() init) {
  useEffect(() {
    init();
    return null;
  }, []);
}

/// Flutter Hooks extension that calls a function on widget state disposal.
void useDispose(void Function() dispose) {
  useEffect(() {
    return dispose;
  }, []);
}

/// Flutter Hooks extension that calls a function on widget state initialisation,
/// and another one on disposal.
void useInitDispose(void Function() init, void Function() dispose) {
  useEffect(() {
    init();
    return dispose;
  }, []);
}

/// Flutter Hooks extension that gives an [Active] value.
Active<T> useActive<T>(T value) {
  return useRef(Active(value)).value;
}

/// Flutter Hooks extension that gives a [Reactive] value.
Reactive<T> useReactive<T>(T Function(Observer o) recompute) {
  return useRef(Reactive(recompute)).value;
}

/// Flutter Hooks extension that calls a function whenever an [Observable] is notified.
Trigger<T> useTrigger<T>(Observable<T> observable, void Function(T value) callback) {
  return useRef(Trigger(observable, callback)).value;
}
