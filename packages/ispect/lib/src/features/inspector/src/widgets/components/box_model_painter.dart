import 'package:flutter/material.dart';

import 'package:ispect/src/features/inspector/src/widgets/inspector/box_info.dart';

final class BoxModelPainter extends CustomPainter {
  const BoxModelPainter({
    required this.boxInfo,
    required this.targetColor,
    required this.containerColor,
  });

  final BoxInfo boxInfo;
  final Color targetColor;
  final Color containerColor;

  Paint get _targetPaint => Paint()
    ..color = targetColor
    ..style = PaintingStyle.fill;

  Paint get _containerPaint => Paint()..color = containerColor;

  Paint get _containerDashPaint =>
      Paint()..color = containerColor.withValues(alpha: 0.35);

  static const double _dashWidth = 4;
  static const double _dashSkip = 0;

  void _paintBackground(Canvas canvas, Size size) {
    final sizePath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height);

    var dashPosition = 0.0;
    while (dashPosition < size.height * 2) {
      final path = Path()
        ..moveTo(0, dashPosition)
        ..lineTo(dashPosition, 0)
        ..lineTo(dashPosition + _dashWidth, 0)
        ..lineTo(0, dashPosition + _dashWidth);

      canvas.drawPath(
        Path.combine(PathOperation.intersect, path, sizePath),
        _containerDashPaint,
      );

      dashPosition += _dashWidth + _dashSkip;
    }
  }

  void _paintForeground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 4.0,
        size.height / 4.0,
        size.width / 2.0,
        size.height / 2.0,
      ),
      _targetPaint,
    );
  }

  TextPainter _getTextPainter(String text) {
    const textStyle = TextStyle(fontSize: 8);

    final span = TextSpan(text: text, style: textStyle);
    return TextPainter(text: span, textDirection: TextDirection.ltr);
  }

  void _paintBoxSize(Canvas canvas, Size size) {
    final painter = _getTextPainter('144 x 50')
      ..layout(maxWidth: size.width / 2.0);

    painter.paint(
      canvas,
      Offset(size.width - painter.width, size.height - painter.height) / 2.0,
    );
  }

  void _paintPaddingBox(
    Canvas canvas,
    Size size, {
    required double padding,
    required Offset offset,
  }) {
    final painter = _getTextPainter(padding.toStringAsFixed(1))
      ..layout(maxWidth: size.width / 4.0);

    final topLeft = Offset(
      offset.dx - painter.width / 2.0,
      offset.dy - painter.height / 2.0,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        topLeft & painter.size,
        const Radius.circular(2),
      ),
      _containerPaint,
    );

    painter.paint(canvas, topLeft);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintForeground(canvas, size);
    _paintBoxSize(canvas, size);

    _paintPaddingBox(
      canvas,
      size,
      padding: boxInfo.paddingLeft!,
      offset: Offset(
        size.width / 8.0,
        size.height / 2.0,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
