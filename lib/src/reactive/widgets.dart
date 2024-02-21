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

import 'package:flutter/widgets.dart';

import '../reactive.dart';

abstract class ReactiveWidget extends StatefulWidget {
  const ReactiveWidget({super.key});

  Widget build(BuildContext context, Observer o);

  @override
  State<ReactiveWidget> createState() => _ReactiveWidgetState();
}

class ReactiveBuilder extends ReactiveWidget {
  final Widget Function(BuildContext context, Observer o) builder;

  const ReactiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context, Observer o) => builder(context, o);
}

class _ReactiveWidgetState extends State<ReactiveWidget>
    with ObserverMixin
    implements Observer {
  bool _visited = false;

  @override
  void visit(List<void Function()> posts) {
    super.visit(posts);
    if (!_visited) {
      _visited = true;
      posts.add(() {
        _visited = false;
        if (mounted) setState(() {});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, this);
  }
}
