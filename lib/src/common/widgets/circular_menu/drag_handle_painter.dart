import 'package:flutter/material.dart';

class LineWithCurvePainter extends CustomPainter {
  const LineWithCurvePainter({required this.isInRightSide});
  final bool isInRightSide;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startX = isInRightSide ? size.width - 8.0 : 8.0;
    final controlPointX = size.width / 2;
    final endX = size.width / 2 + (isInRightSide ? 2 : -2);

    final path = Path()
      ..moveTo(startX, 14)
      ..quadraticBezierTo(
        controlPointX,
        size.height / 2,
        endX,
        size.height - 14,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
