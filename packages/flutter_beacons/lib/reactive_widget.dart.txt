import 'package:flutter/widgets.dart';

import 'reactive.dart';

abstract class ReactiveWidget extends StatefulWidget {
  const ReactiveWidget({super.key});

  Widget build(BuildContext context, WeakReference<Node> ref);

  @override
  State<ReactiveWidget> createState() => _ReactiveWidgetState();
}

class ReactiveBuilder extends ReactiveWidget {
  final Widget Function(BuildContext context, WeakReference<Node> ref) builder;

  const ReactiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context, WeakReference<Node> ref) => builder(context, ref);
}

class _ReactiveWidgetState extends State<ReactiveWidget> {
  late final Observer observer;

  @override
  void initState() {
    super.initState();
    observer = Observer(() => setState(() {}));
  }

  @override
  void dispose() {
    observer.set(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context, observer.weak());
  }
}
