import 'package:flutter/material.dart';

/// A CustomPainter that draws a series of dots in a horizontal line.
///
/// This painter is designed to create a row of evenly spaced circles (dots)
/// at a specified y-coordinate. It is useful for creating visual indicators,
/// dots leaders, or decorative elements.
class DotPainter extends CustomPainter {
  /// Creates a [DotPainter] that draws evenly spaced dots.
  ///
  /// The [count] parameter specifies how many dots to draw.
  /// The [y] parameter determines the vertical position of the dots.
  /// The [radius] parameter controls the size of each dot.
  /// The [spacing] parameter determines the distance between dots.
  /// The [color] parameter sets the color of the dots.
  DotPainter({
    required this.count,
    this.y = 10.0,
    this.radius = 1.0,
    this.spacing = 5,
    this.color = Colors.grey,
  }) : assert(count >= 0, 'Count must be non-negative');

  /// Number of dots to draw
  final double count;

  /// Vertical position of the dots
  final double y;

  /// Radius of each dot
  final double radius;

  /// Spacing between dots
  final double spacing;

  /// Color of the dots
  final Color color;

  // Cached paint object for better performance
  Paint? _cachedPaint;

  @override
  void paint(Canvas canvas, Size size) {
    // Don't draw anything if count is effectively zero
    if (count < 0.01) return;

    // Use or create cached paint object
    _cachedPaint ??= Paint()..style = PaintingStyle.fill;

    // Set color (may change between paints)
    _cachedPaint!.color = color;

    // Convert to integer count for the loop
    final dotsCount = count.ceil();

    // For small counts, use simple loop
    if (dotsCount < 50) {
      for (var i = 0; i < dotsCount; i++) {
        final x = spacing * i;
        canvas.drawCircle(Offset(x, y), radius, _cachedPaint!);
      }
      return;
    }

    // For large counts, batch draws to improve performance
    for (var i = 0; i < dotsCount; i += 10) {
      final batchSize = (i + 10 > dotsCount) ? dotsCount - i : 10;
      for (var j = 0; j < batchSize; j++) {
        final x = spacing * (i + j);
        canvas.drawCircle(Offset(x, y), radius, _cachedPaint!);
      }
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
