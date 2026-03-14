import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/inspector/src/inspector/box_info.dart';

class OverlayPainter extends CustomPainter {
  const OverlayPainter({
    required this.boxInfo,
    required this.targetRectColor,
    required this.containerRectColor,
  });

  final BoxInfo boxInfo;

  final Color targetRectColor;
  final Color containerRectColor;

  Paint get targetRectPaint => Paint()..color = targetRectColor;
  Paint get containerRectPaint => Paint()..color = containerRectColor;

  @override
  void paint(Canvas canvas, Size size) {
    final targetRectShifted = boxInfo.targetRectShifted;
    if (targetRectShifted == null) return;

    canvas.drawRect(
      targetRectShifted,
      targetRectPaint,
    );

    if (boxInfo.containerRect != null) {
      final paddingRects = [
        boxInfo.paddingRectLeft,
        boxInfo.paddingRectTop,
        boxInfo.paddingRectRight,
        boxInfo.paddingRectBottom,
      ];

      for (final rect in paddingRects) {
        if (rect == null) continue;
        canvas.drawRect(
          rect.shift(-boxInfo.overlayOffset),
          containerRectPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(OverlayPainter oldDelegate) =>
      oldDelegate.boxInfo != boxInfo ||
      oldDelegate.containerRectColor != containerRectColor ||
      oldDelegate.targetRectColor != targetRectColor;
}
