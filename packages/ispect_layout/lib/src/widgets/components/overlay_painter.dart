import 'package:flutter/widgets.dart';

import '../inspector/box_info.dart';

/// Visual role of an overlaid box — drives border/fill/corner styling.
enum OverlayRole { selected, hovered, compared }

class OverlayPainter extends CustomPainter {
  OverlayPainter({
    required this.boxInfo,
    required this.role,
    required this.accentColor,
    this.containerColor,
    this.showContainerRenderBox = true,
  });

  final BoxInfo boxInfo;
  final OverlayRole role;
  final Color accentColor;
  final Color? containerColor;
  final bool showContainerRenderBox;

  double get _fillAlpha => switch (role) {
        OverlayRole.selected => 0.10,
        OverlayRole.hovered => 0.06,
        OverlayRole.compared => 0.10,
      };

  double get _borderWidth => switch (role) {
        OverlayRole.selected => 2.0,
        OverlayRole.hovered => 1.2,
        OverlayRole.compared => 2.0,
      };

  bool get _showCorners => role != OverlayRole.hovered;

  bool get _dashedBorder => role == OverlayRole.hovered;

  @override
  void paint(Canvas canvas, Size size) {
    // Target may detach between build-time guards and this paint call
    // (e.g. the inspected widget left the tree in the same frame).
    if (!boxInfo.targetRenderBox.attached) return;

    final rect = boxInfo.targetRectShifted;

    _paintPaddingHighlights(canvas);
    _paintFill(canvas, rect);
    _paintBorder(canvas, rect);
    if (_showCorners) _paintCornerMarks(canvas, rect);
  }

  // If any side exceeds this, the "container" is a flex parent, not a padding
  // wrapper — skip all highlights to avoid a lopsided wash on the screen.
  static const double _paddingHighlightThresholdPx = 96.0;

  void _paintPaddingHighlights(Canvas canvas) {
    if (!showContainerRenderBox ||
        containerColor == null ||
        boxInfo.containerRect == null) {
      return;
    }

    final left = boxInfo.paddingRectLeft;
    final top = boxInfo.paddingRectTop;
    final right = boxInfo.paddingRectRight;
    final bottom = boxInfo.paddingRectBottom;

    final leftPad = left?.width ?? 0;
    final topPad = top?.height ?? 0;
    final rightPad = right?.width ?? 0;
    final bottomPad = bottom?.height ?? 0;

    const threshold = _paddingHighlightThresholdPx;
    if (leftPad > threshold ||
        topPad > threshold ||
        rightPad > threshold ||
        bottomPad > threshold) {
      return;
    }
    if (leftPad < 0.5 && topPad < 0.5 && rightPad < 0.5 && bottomPad < 0.5) {
      return;
    }

    final paint = Paint()..color = containerColor!.withValues(alpha: 0.18);
    final overlay = boxInfo.overlayOffset;

    void draw(Rect? rect, double paddingExtent) {
      if (rect == null || paddingExtent < 0.5) return;
      canvas.drawRect(rect.shift(-overlay), paint);
    }

    draw(left, leftPad);
    draw(top, topPad);
    draw(right, rightPad);
    draw(bottom, bottomPad);
  }

  void _paintFill(Canvas canvas, Rect rect) {
    canvas.drawRect(
      rect,
      Paint()..color = accentColor.withValues(alpha: _fillAlpha),
    );
  }

  void _paintBorder(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _borderWidth;

    if (_dashedBorder) {
      _drawDashedRect(canvas, rect, paint);
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  void _paintCornerMarks(Canvas canvas, Rect rect) {
    // Scale marker length with the box, clamp so tiny targets stay readable.
    final length = (rect.shortestSide * 0.2).clamp(6.0, 14.0).toDouble();
    final paint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final tl = rect.topLeft;
    final tr = rect.topRight;
    final bl = rect.bottomLeft;
    final br = rect.bottomRight;

    canvas
      ..drawLine(tl, tl.translate(length, 0), paint)
      ..drawLine(tl, tl.translate(0, length), paint)
      ..drawLine(tr, tr.translate(-length, 0), paint)
      ..drawLine(tr, tr.translate(0, length), paint)
      ..drawLine(bl, bl.translate(length, 0), paint)
      ..drawLine(bl, bl.translate(0, -length), paint)
      ..drawLine(br, br.translate(-length, 0), paint)
      ..drawLine(br, br.translate(0, -length), paint);
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint) {
    const dash = 4.0;
    const gap = 3.0;

    void line(Offset a, Offset b) {
      final total = (b - a).distance;
      if (total == 0) return;
      final direction = (b - a) / total;
      var traveled = 0.0;
      while (traveled < total) {
        final segment = (traveled + dash).clamp(0.0, total).toDouble();
        canvas.drawLine(
          a + direction * traveled,
          a + direction * segment,
          paint,
        );
        traveled = segment + gap;
      }
    }

    line(rect.topLeft, rect.topRight);
    line(rect.topRight, rect.bottomRight);
    line(rect.bottomRight, rect.bottomLeft);
    line(rect.bottomLeft, rect.topLeft);
  }

  @override
  bool shouldRepaint(OverlayPainter oldDelegate) =>
      oldDelegate.boxInfo != boxInfo ||
      oldDelegate.role != role ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.containerColor != containerColor ||
      oldDelegate.showContainerRenderBox != showContainerRenderBox;
}
