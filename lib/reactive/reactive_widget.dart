/*
import 'package:flutter/widgets.dart';

import 'reactive.dart';

abstract class ReactiveWidget extends StatefulWidget {
  const ReactiveWidget({super.key});

  Widget build(BuildContext context, Ref ref);

  @override
  State<ReactiveWidget> createState() => _ReactiveWidgetState();
}

class ReactiveBuilder extends ReactiveWidget {
  final Widget Function(BuildContext context, Ref ref) builder;

  const ReactiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context, Ref ref) => builder(context, ref);
}

class _ReactiveWidgetState extends State<ReactiveWidget> {
  late final Watcher watcher;

  @override
  void initState() {
    super.initState();
    watcher = Watcher(() => setState(() {}));
  }

  @override
  void dispose() {
    watcher.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return watcher.recompute((ref) => widget.build(context, ref));
  }
}
*/
