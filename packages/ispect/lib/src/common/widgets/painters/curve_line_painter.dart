import 'package:flutter/material.dart';

/// A custom painter that draws a curved line with a quadratic Bezier path.
///
/// This painter is designed to render a **curved connector line** that can be
/// positioned on either the left or right side of the container. The curve
/// smoothly transitions from a **starting point** to an **ending point** with
/// a **midway control point**, giving it an elegant flow.
///
/// ### Parameters:
/// - `isInRightSide`: Determines whether the curve starts from the right side (`true`)
///   or from the left side (`false`).
/// - `color`: Defines the stroke color of the curve.
///
/// ### Example Usage:
/// ```dart
/// CustomPaint(
///   size: Size(100, 100),
///   painter: CurveLinePainter(
///     isInRightSide: true,
///     color: Colors.blue,
///   ),
/// )
/// ```
class CurveLinePainter extends CustomPainter {
  /// Creates a `CurveLinePainter` instance with the given parameters.
  ///
  /// - `isInRightSide`: If `true`, the curve starts from the right; otherwise, it starts from the left.
  /// - `color`: The color used for the curve stroke.
  const CurveLinePainter({
    required this.isInRightSide,
    required this.color,
  });

  /// Determines the starting side of the curve.
  ///
  /// - `true`: The curve starts from the right.
  /// - `false`: The curve starts from the left.
  final bool isInRightSide;

  /// The stroke color of the curved line.
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Define the paint properties for the curve.
    final paint = Paint()
      ..color = color
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Define the starting X position based on the side.
    final startX = isInRightSide ? size.width - 7.0 : 7.0;

    // Define the control point for the quadratic Bezier curve.
    final controlPointX = size.width / 2;

    // Define the ending X position with a slight offset based on the side.
    final endX = size.width / 2 + (isInRightSide ? 3 : -3);

    // Create the path for the curve.
    final path = Path()
      ..moveTo(startX, 14) // Start position with a vertical offset.
      ..quadraticBezierTo(
        controlPointX, // Control point X (midpoint).
        size.height / 2, // Control point Y (halfway down).
        endX, // End position X.
        size.height - 14, // End position Y with vertical offset.
      );

    // Draw the curved path on the canvas.
    canvas.drawPath(path, paint);
  }

  /// Determines whether the painter should repaint.
  ///
  /// Since this is a **static** painter (values are set in the constructor),
  /// it does **not** require repainting.
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
