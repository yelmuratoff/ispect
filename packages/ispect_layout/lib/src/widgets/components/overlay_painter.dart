import 'package:flutter/widgets.dart';

import '../inspector/box_info.dart';

class OverlayPainter extends CustomPainter {
  OverlayPainter({
    required this.boxInfo,
    required this.targetRectColor,
    required this.containerRectColor,
    this.showContainerRenderBox = true,
  });

  final BoxInfo boxInfo;
  final Color targetRectColor;
  final Color containerRectColor;
  final bool showContainerRenderBox;

  Paint get targetRectPaint => Paint()..color = targetRectColor;

  Paint get containerRectPaint => Paint()..color = containerRectColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      boxInfo.targetRectShifted,
      targetRectPaint,
    );

    if (showContainerRenderBox && boxInfo.containerRect != null) {
      final paddingRects = [
        boxInfo.paddingRectLeft,
        boxInfo.paddingRectTop,
        boxInfo.paddingRectRight,
        boxInfo.paddingRectBottom,
      ];

      for (final rect in paddingRects) {
        canvas.drawRect(
          rect!.shift(-boxInfo.overlayOffset),
          containerRectPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(OverlayPainter oldDelegate) {
    return oldDelegate.boxInfo != boxInfo ||
        oldDelegate.containerRectColor != containerRectColor ||
        oldDelegate.targetRectColor != targetRectColor;
  }
}
