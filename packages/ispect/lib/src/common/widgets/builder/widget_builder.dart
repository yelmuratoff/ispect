import 'package:flutter/material.dart';
import 'package:ispectify/ispectify.dart';

typedef ISpectifyWidgetBuilder = Widget Function(
  BuildContext context,
  List<ISpectifyData> data,
);

class ISpectifyBuilder extends StatelessWidget {
  const ISpectifyBuilder({
    required this.iSpectify,
    required this.builder,
    super.key,
  });

  final ISpectify iSpectify;
  final ISpectifyWidgetBuilder builder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
        stream: iSpectify.stream,
        builder: (context, _) => builder(context, iSpectify.history),
      );
}
