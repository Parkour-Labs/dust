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

class _ReactiveWidgetState extends State<ReactiveWidget> with ObserverMixin implements Observer {
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
