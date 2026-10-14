import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiValueListenableBuilder extends StatefulWidget {
  const MultiValueListenableBuilder({
    super.key,
    required this.valueListenables,
    required this.builder,
  });

  final List<ValueListenable> valueListenables;
  final WidgetBuilder builder;

  @override
  State<MultiValueListenableBuilder> createState() =>
      _MultiValueListenableBuilderState();
}

class _MultiValueListenableBuilderState
    extends State<MultiValueListenableBuilder> {
  @override
  void initState() {
    super.initState();
    _registerListeners();
  }

  void _onUpdated() {
    setState(() {});
  }

  void _registerListeners() {
    for (final listenable in widget.valueListenables) {
      listenable.addListener(_onUpdated);
    }
  }

  void _deregisterListeners(List<ValueListenable> listenables) {
    for (final listenable in listenables) {
      listenable.removeListener(_onUpdated);
    }
  }

  @override
  void didUpdateWidget(covariant MultiValueListenableBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.valueListenables, widget.valueListenables)) {
      return;
    }
    _deregisterListeners(oldWidget.valueListenables);
    _registerListeners();
  }

  @override
  void dispose() {
    _deregisterListeners(widget.valueListenables);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(context);
  }
}
