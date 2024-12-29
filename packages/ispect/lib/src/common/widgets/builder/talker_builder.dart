import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';

typedef ISpectifyWidgetBuilder = Widget Function(
  BuildContext context,
  List<ISpectiyData> data,
);

class ISpectifyBuilder extends StatelessWidget {
  const ISpectifyBuilder({
    required this.iSpectify,
    required this.builder,
    super.key,
  });

  final ISpectiy iSpectify;
  final ISpectifyWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: iSpectify.stream,
        builder: (context, _) => builder(context, iSpectify.history),
      );
}
