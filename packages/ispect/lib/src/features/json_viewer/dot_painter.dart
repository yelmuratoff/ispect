import 'package:flutter/material.dart';

class DotPainter extends CustomPainter {
  DotPainter({
    required this.count,
    this.y = 10.0,
    this.radius = 1.0,
    this.spacing = 5,
    this.color = Colors.grey,
  }) : assert(count >= 0, 'Count must be non-negative');
  final double count;
  final double y;
  final double radius;
  final double spacing;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < count; i++) {
      final x = spacing * i;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DotPainter oldDelegate) =>
      oldDelegate.count != count ||
      oldDelegate.y != y ||
      oldDelegate.radius != radius ||
      oldDelegate.spacing != spacing ||
      oldDelegate.color != color;
}
