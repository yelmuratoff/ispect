import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';

typedef TalkerWidgetBuilder = Widget Function(
  BuildContext context,
  List<ISpectiyData> data,
);

class TalkerBuilder extends StatelessWidget {
  const TalkerBuilder({
    required this.iSpectify,
    required this.builder,
    super.key,
  });

  final ISpectiy iSpectify;
  final TalkerWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: iSpectify.stream,
        builder: (context, _) => builder(context, iSpectify.history),
      );
}
