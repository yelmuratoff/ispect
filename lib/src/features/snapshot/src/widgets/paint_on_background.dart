// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:ispect/src/features/snapshot/src/widgets/painter.dart';

class PaintOnChild extends StatelessWidget {
  const PaintOnChild({
    required this.child,
    required this.isPaintingActive,
    required this.controller,
    super.key,
  });

  final Widget child;
  final bool isPaintingActive;
  final PainterController controller;

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          child,
          if (isPaintingActive) Painter(controller),
        ],
      );
}
