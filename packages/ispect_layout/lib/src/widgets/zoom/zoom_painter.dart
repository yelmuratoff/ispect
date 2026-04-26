import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ispect_layout/src/widgets/components/information_box_widget.dart';

/// Shared painter for the zoom overlay and zoomable color picker.
///
/// Renders [image] centred at [imageOffset], scaled by `zoomScale / pixelRatio`.
/// Uses [FilterQuality.none] (nearest-neighbour) so individual source pixels
/// stay crisp at high zoom — essential for color picking accuracy.
///
/// When [showPixelGrid] is enabled and the on-screen size of one source pixel
/// exceeds [pixelGridThreshold] logical px, a 1-logical-px hairline grid is
/// rendered on top so the user can identify which pixel is being sampled.
class ZoomPainter extends CustomPainter {
  ZoomPainter({
    required this.image,
    required this.imageOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
    this.backgroundColor = const Color(0x00000000),
    this.showPixelGrid = true,
    this.pixelGridThreshold = 8.0,
    this.pixelGridColor = const Color(0x33000000),
  })  : _backgroundPaint = Paint()..color = backgroundColor,
        _imagePaint = Paint()..filterQuality = FilterQuality.none;

  final ui.Image image;
  final Offset imageOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;
  final Color backgroundColor;

  /// Draw a 1-logical-px hairline grid over the zoomed image when each source
  /// pixel covers more than [pixelGridThreshold] logical pixels on screen.
  final bool showPixelGrid;
  final double pixelGridThreshold;
  final Color pixelGridColor;

  final Paint _backgroundPaint;
  final Paint _imagePaint;

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundColor.a > 0) {
      canvas.drawRect(Offset.zero & size, _backgroundPaint);
    }

    final halfSize = overlaySize / 2.0;
    final scale = (1 / pixelRatio) * zoomScale;

    canvas
      ..save()
      ..clipRect(Offset.zero & size)
      ..translate(halfSize, halfSize)
      ..scale(scale)
      ..drawImage(image, -imageOffset, _imagePaint)
      ..restore();

    if (showPixelGrid && scale >= pixelGridThreshold) {
      _drawPixelGrid(canvas, size, scale, halfSize);
    }
  }

  void _drawPixelGrid(
    Canvas canvas,
    Size size,
    double scale,
    double halfSize,
  ) {
    // Each source pixel maps to `scale` logical px on screen. We draw grid
    // lines aligned with pixel boundaries of the source image, in the overlay
    // coordinate space, so they match what the user sees.
    final paint = Paint()
      ..color = pixelGridColor
      ..strokeWidth = 1.0
      ..isAntiAlias = false;

    // The image pixel currently at canvas centre.
    final centerImageX = imageOffset.dx;
    final centerImageY = imageOffset.dy;

    // First grid line offset in screen-space relative to centre.
    final firstX = (centerImageX.floorToDouble() - centerImageX) * scale;
    final firstY = (centerImageY.floorToDouble() - centerImageY) * scale;

    canvas.save();
    canvas.translate(halfSize, halfSize);
    canvas
        .clipRect(Rect.fromLTWH(-halfSize, -halfSize, size.width, size.height));

    for (var x = firstX; x <= halfSize; x += scale) {
      canvas.drawLine(Offset(x, -halfSize), Offset(x, halfSize), paint);
    }
    for (var x = firstX - scale; x >= -halfSize; x -= scale) {
      canvas.drawLine(Offset(x, -halfSize), Offset(x, halfSize), paint);
    }
    for (var y = firstY; y <= halfSize; y += scale) {
      canvas.drawLine(Offset(-halfSize, y), Offset(halfSize, y), paint);
    }
    for (var y = firstY - scale; y >= -halfSize; y -= scale) {
      canvas.drawLine(Offset(-halfSize, y), Offset(halfSize, y), paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant ZoomPainter oldDelegate) =>
      image != oldDelegate.image ||
      imageOffset != oldDelegate.imageOffset ||
      overlaySize != oldDelegate.overlaySize ||
      zoomScale != oldDelegate.zoomScale ||
      pixelRatio != oldDelegate.pixelRatio ||
      backgroundColor != oldDelegate.backgroundColor ||
      showPixelGrid != oldDelegate.showPixelGrid ||
      pixelGridThreshold != oldDelegate.pixelGridThreshold ||
      pixelGridColor != oldDelegate.pixelGridColor;
}

/// Auto-hiding zoom level indicator. Visible for 1 s after each [zoomScale]
/// change, then fades out.
class ZoomLevelIndicator extends StatefulWidget {
  const ZoomLevelIndicator({
    super.key,
    required this.zoomScale,
    this.visibilityDuration = const Duration(seconds: 1),
    this.fadeDuration = const Duration(milliseconds: 200),
  });

  final double zoomScale;
  final Duration visibilityDuration;
  final Duration fadeDuration;

  @override
  State<ZoomLevelIndicator> createState() => _ZoomLevelIndicatorState();
}

class _ZoomLevelIndicatorState extends State<ZoomLevelIndicator> {
  Timer? _hideTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _showZoomScale();
  }

  @override
  void didUpdateWidget(covariant ZoomLevelIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.zoomScale != oldWidget.zoomScale) {
      _showZoomScale();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _showZoomScale() {
    if (!mounted) return;
    setState(() => _isVisible = true);
    _hideTimer?.cancel();
    _hideTimer = Timer(widget.visibilityDuration, () {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: widget.fadeDuration,
        child: InformationBoxWidget(
          child: Text('x${widget.zoomScale}'),
        ),
      );
}
