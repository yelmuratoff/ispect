import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/inspector/src/inspector/box_info.dart';

/// Paints edge-to-edge distance measurements between two
/// compared [BoxInfo] overlays.
///
/// Behaviour:
/// - **No overlap on an axis**: draws a dashed line between the nearest edges
///   and labels the gap distance.
/// - **One contains the other**: draws padding lines from each inner edge to
///   the corresponding outer edge.
/// - **Partial overlap**: draws lines from the overlapping edges with signed
///   distance (negative = overlap amount).
class CompareOverlayPainter extends CustomPainter {
  const CompareOverlayPainter({
    required this.boxInfoA,
    required this.boxInfoB,
    required this.lineColor,
  });

  final BoxInfo boxInfoA;
  final BoxInfo boxInfoB;
  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rectA = boxInfoA.targetRectShifted;
    final rectB = boxInfoB.targetRectShifted;
    if (rectA == null || rectB == null) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical center of the horizontal overlap zone (for drawing H lines)
    final overlapTop = rectA.top > rectB.top ? rectA.top : rectB.top;
    final overlapBottom =
        rectA.bottom < rectB.bottom ? rectA.bottom : rectB.bottom;
    final midY = (overlapTop + overlapBottom) / 2;

    // Horizontal center of the vertical overlap zone (for drawing V lines)
    final overlapLeft = rectA.left > rectB.left ? rectA.left : rectB.left;
    final overlapRight = rectA.right < rectB.right ? rectA.right : rectB.right;
    final midX = (overlapLeft + overlapRight) / 2;

    // --- Horizontal measurement (edge-to-edge) ---
    final hGap = _horizontalGap(rectA, rectB);
    if (hGap != null) {
      final y = overlapTop < overlapBottom ? midY : rectA.center.dy;

      _drawMeasurementLine(
        canvas: canvas,
        from: Offset(hGap.start, y),
        to: Offset(hGap.end, y),
        distance: hGap.distance,
        isHorizontal: true,
        linePaint: linePaint,
        dashPaint: dashPaint,
      );
    }

    // --- Vertical measurement (edge-to-edge) ---
    final vGap = _verticalGap(rectA, rectB);
    if (vGap != null) {
      final x = overlapLeft < overlapRight ? midX : rectA.center.dx;

      _drawMeasurementLine(
        canvas: canvas,
        from: Offset(x, vGap.start),
        to: Offset(x, vGap.end),
        distance: vGap.distance,
        isHorizontal: false,
        linePaint: linePaint,
        dashPaint: dashPaint,
      );
    }
  }

  void _drawMeasurementLine({
    required Canvas canvas,
    required Offset from,
    required Offset to,
    required double distance,
    required bool isHorizontal,
    required Paint linePaint,
    required Paint dashPaint,
  }) {
    if (distance.abs() < 0.5) return;

    _drawDashedLine(canvas, from, to, dashPaint);

    // End caps perpendicular to the line
    const capSize = 4.0;
    if (isHorizontal) {
      canvas
        ..drawLine(
          Offset(from.dx, from.dy - capSize),
          Offset(from.dx, from.dy + capSize),
          linePaint,
        )
        ..drawLine(
          Offset(to.dx, to.dy - capSize),
          Offset(to.dx, to.dy + capSize),
          linePaint,
        );
    } else {
      canvas
        ..drawLine(
          Offset(from.dx - capSize, from.dy),
          Offset(from.dx + capSize, from.dy),
          linePaint,
        )
        ..drawLine(
          Offset(to.dx - capSize, to.dy),
          Offset(to.dx + capSize, to.dy),
          linePaint,
        );
    }

    // Label at midpoint
    final labelOffset = isHorizontal
        ? Offset((from.dx + to.dx) / 2, from.dy - 12)
        : Offset(to.dx + 6, (from.dy + to.dy) / 2);

    _drawLabel(canvas, distance.toStringAsFixed(1), labelOffset, lineColor);
  }

  /// Returns the horizontal edge-to-edge gap between two rects.
  /// Null if they are at the same horizontal position.
  _Gap? _horizontalGap(Rect a, Rect b) {
    // B is to the right of A
    if (b.left >= a.right) {
      return _Gap(start: a.right, end: b.left, distance: b.left - a.right);
    }
    // A is to the right of B
    if (a.left >= b.right) {
      return _Gap(start: b.right, end: a.left, distance: a.left - b.right);
    }
    // Overlapping — show distance between left edges
    final leftDist = (b.left - a.left).abs();
    if (leftDist > 0.5) {
      final leftStart = a.left < b.left ? a.left : b.left;
      final leftEnd = a.left < b.left ? b.left : a.left;
      return _Gap(start: leftStart, end: leftEnd, distance: leftDist);
    }
    return null;
  }

  /// Returns the vertical edge-to-edge gap between two rects.
  /// Null if they are at the same vertical position.
  _Gap? _verticalGap(Rect a, Rect b) {
    // B is below A
    if (b.top >= a.bottom) {
      return _Gap(start: a.bottom, end: b.top, distance: b.top - a.bottom);
    }
    // A is below B
    if (a.top >= b.bottom) {
      return _Gap(start: b.bottom, end: a.top, distance: a.top - b.bottom);
    }
    // Overlapping — show distance between top edges
    final topDist = (b.top - a.top).abs();
    if (topDist > 0.5) {
      final topStart = a.top < b.top ? a.top : b.top;
      final topEnd = a.top < b.top ? b.top : a.top;
      return _Gap(start: topStart, end: topEnd, distance: topDist);
    }
    return null;
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint,
  ) {
    const dashLength = 4.0;
    const gapLength = 3.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = (end - start).distance;

    if (distance < 1) return;

    final unitDx = dx / distance;
    final unitDy = dy / distance;

    var drawn = 0.0;
    var drawing = true;

    while (drawn < distance) {
      final segmentLength = drawing ? dashLength : gapLength;
      final remaining = distance - drawn;
      final len = segmentLength < remaining ? segmentLength : remaining;

      if (drawing) {
        canvas.drawLine(
          Offset(
            start.dx + unitDx * drawn,
            start.dy + unitDy * drawn,
          ),
          Offset(
            start.dx + unitDx * (drawn + len),
            start.dy + unitDy * (drawn + len),
          ),
          paint,
        );
      }

      drawn += len;
      drawing = !drawing;
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset position,
    Color color,
  ) {
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: 10,
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          background: Paint()..color = const Color(0xCC000000),
        ),
      )
      ..addText(text);

    final paragraph = paragraphBuilder.build()
      ..layout(const ui.ParagraphConstraints(width: 80));

    canvas.drawParagraph(
      paragraph,
      Offset(position.dx - paragraph.width / 2, position.dy - 6),
    );
  }

  @override
  bool shouldRepaint(CompareOverlayPainter oldDelegate) =>
      oldDelegate.boxInfoA != boxInfoA ||
      oldDelegate.boxInfoB != boxInfoB ||
      oldDelegate.lineColor != lineColor;
}

class _Gap {
  const _Gap({
    required this.start,
    required this.end,
    required this.distance,
  });

  final double start;
  final double end;
  final double distance;
}
