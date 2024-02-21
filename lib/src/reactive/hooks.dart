// Copyright 2024 ParkourLabs
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter_hooks/flutter_hooks.dart';

import '../reactive.dart';

/// Flutter Hooks extension that calls a function on widget state initialisation.
void useInit(void Function() init) {
  useEffect(() {
    init();
    return null;
  }, const <Object>[]);
}

/// Flutter Hooks extension that calls a function on widget state disposal.
void useDispose(void Function() dispose) {
  useEffect(() {
    return dispose;
  }, const <Object>[]);
}

/// Flutter Hooks extension that calls a function on widget state initialisation,
/// and another one on disposal.
void useInitDispose(void Function() init, void Function() dispose) {
  useEffect(() {
    init();
    return dispose;
  }, const <Object>[]);
}

/// Flutter Hooks extension that gives an [Active] value.
Active<T> useActive<T>(T value) {
  return useMemoized(() => Active(value));
}

/// Flutter Hooks extension that gives a [Reactive] value.
Reactive<T> useReactive<T>(T Function(Observer o) recompute) {
  return useMemoized(() => Reactive(recompute));
}

/// Flutter Hooks extension that calls a function whenever an [Observable] is notified.
Trigger<T> useTrigger<T>(
    Observable<T> observable, void Function(T value) callback) {
  return useMemoized(() => Trigger(observable, callback));
}

/// Flutter Hooks extension that calls a function whenever an [Observable] is notified.
Comparer<T> useComparer<T>(
    Observable<T> observable, void Function(T? prev, T curr) callback) {
  return useMemoized(() => Comparer(observable, callback));
}
