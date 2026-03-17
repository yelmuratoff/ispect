import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/inspector/src/inspector/box_info.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/box_info_panel_widget.dart';

/// Paints Figma-style distance measurement lines between two compared widgets.
///
/// Uses [computeCompareDistances] — the same logic as the panel — so
/// the drawn lines always match the displayed numbers.
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
    final from = boxInfoA.targetRectShifted;
    final to = boxInfoB.targetRectShifted;
    if (from == null || to == null) return;

    final distances = computeCompareDistances(from, to);

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final dashPaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (final d in distances) {
      _drawMeasurement(
        canvas,
        d.startOffset,
        d.endOffset,
        d.value,
        isHorizontal: d.isHorizontal,
        linePaint: linePaint,
        dashPaint: dashPaint,
      );
    }
  }

  void _drawMeasurement(
    Canvas canvas,
    Offset from,
    Offset to,
    double distance, {
    required bool isHorizontal,
    required Paint linePaint,
    required Paint dashPaint,
  }) {
    if (distance < 0.5) return;

    _drawDashedLine(canvas, from, to, dashPaint);

    const cap = 4.0;
    if (isHorizontal) {
      canvas
        ..drawLine(
          Offset(from.dx, from.dy - cap),
          Offset(from.dx, from.dy + cap),
          linePaint,
        )
        ..drawLine(
          Offset(to.dx, to.dy - cap),
          Offset(to.dx, to.dy + cap),
          linePaint,
        );

      _drawLabel(
        canvas,
        distance.toStringAsFixed(1),
        Offset((from.dx + to.dx) / 2, from.dy - 12),
      );
    } else {
      canvas
        ..drawLine(
          Offset(from.dx - cap, from.dy),
          Offset(from.dx + cap, from.dy),
          linePaint,
        )
        ..drawLine(
          Offset(to.dx - cap, to.dy),
          Offset(to.dx + cap, to.dy),
          linePaint,
        );

      _drawLabel(
        canvas,
        distance.toStringAsFixed(1),
        Offset(to.dx + 6, (from.dy + to.dy) / 2),
      );
    }
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
          Offset(start.dx + unitDx * drawn, start.dy + unitDy * drawn),
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

  void _drawLabel(Canvas canvas, String text, Offset position) {
    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(textAlign: TextAlign.center, fontSize: 10),
    )
      ..pushStyle(
        ui.TextStyle(
          color: lineColor,
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
