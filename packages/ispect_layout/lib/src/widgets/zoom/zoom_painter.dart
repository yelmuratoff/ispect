import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ispect_layout/src/widgets/components/information_box_widget.dart';

/// Shared painter for the zoom overlay and zoomable color picker.
///
/// Renders [image] centred at [imageOffset], scaled by `zoomScale / pixelRatio`.
/// Fills the background with [backgroundColor] so areas outside the source
/// image bounds don't show through stale GPU state.
class ZoomPainter extends CustomPainter {
  ZoomPainter({
    required this.image,
    required this.imageOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
    this.backgroundColor = const Color(0x00000000),
  })  : _backgroundPaint = Paint()..color = backgroundColor,
        _imagePaint = Paint()..filterQuality = FilterQuality.low;

  final ui.Image image;
  final Offset imageOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;
  final Color backgroundColor;

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
      ..clipRect(Offset.zero & size)
      ..translate(halfSize, halfSize)
      ..scale(scale)
      ..drawImage(image, -imageOffset, _imagePaint);
  }

  @override
  bool shouldRepaint(covariant ZoomPainter oldDelegate) =>
      image != oldDelegate.image ||
      imageOffset != oldDelegate.imageOffset ||
      overlaySize != oldDelegate.overlaySize ||
      zoomScale != oldDelegate.zoomScale ||
      pixelRatio != oldDelegate.pixelRatio ||
      backgroundColor != oldDelegate.backgroundColor;
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
