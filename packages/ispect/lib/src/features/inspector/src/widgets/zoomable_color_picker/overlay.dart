import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/information_box_widget.dart';
import 'package:ispect/src/features/json_viewer/extensions/color_extensions.dart';

/// A combined overlay widget for zoomable color picker with color display
/// and zoom level indicators.
///
/// Features:
/// - Triple-layer circular border design
/// - Zoomed image preview with custom painter
/// - Color hex code display
/// - Auto-hiding zoom level indicator
/// - Center color indicator dot
class CombinedOverlayWidget extends StatelessWidget {
  const CombinedOverlayWidget({
    required this.image,
    required this.imageOffset,
    required this.overlayOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
    required this.color,
    super.key,
  });

  final ui.Image image;
  final Offset imageOffset;
  final Offset overlayOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.appTheme.colorScheme;
    final borderColor = colorScheme.inverseSurface.withValues(alpha: 0.2);
    final textColor = color.contrastText();

    return Material(
      color: Colors.transparent,
      child: SizedBox.square(
        dimension: overlaySize,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(
                color: borderColor,
                width: 20,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(
                  color: color,
                  width: 18,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(
                    color: borderColor,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  ),
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 12,
                    color: Colors.black12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        isComplex: true,
                        willChange: true,
                        painter: _ZoomPainter(
                          image: image,
                          imageOffset: imageOffset,
                          overlayOffset: overlayOffset,
                          overlaySize: overlaySize,
                          zoomScale: zoomScale,
                          pixelRatio: pixelRatio,
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, -0.8),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            border: Border.all(
                              color: textColor.withValues(alpha: 0.2),
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              colorToHexString(color),
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, -0.8),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ZoomLevelDisplay(zoomScale: zoomScale),
                      ),
                    ),
                    Center(
                      child: SizedBox.square(
                        dimension: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: textColor.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom painter for rendering zoomed image content in the overlay.
///
/// Optimizes performance with proper shouldRepaint implementation
/// and efficient canvas operations.
class _ZoomPainter extends CustomPainter {
  const _ZoomPainter({
    required this.image,
    required this.imageOffset,
    required this.overlayOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
  });

  final ui.Image image;
  final Offset imageOffset;
  final Offset overlayOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final halfSize = overlaySize / 2.0;
    final scale = (1 / pixelRatio) * zoomScale;

    canvas
      ..clipRect(Offset.zero & size)
      ..translate(halfSize, halfSize)
      ..scale(scale)
      ..drawImage(image, -imageOffset, Paint());
  }

  @override
  bool shouldRepaint(covariant _ZoomPainter oldDelegate) =>
      image != oldDelegate.image ||
      imageOffset != oldDelegate.imageOffset ||
      overlayOffset != oldDelegate.overlayOffset ||
      overlaySize != oldDelegate.overlaySize ||
      zoomScale != oldDelegate.zoomScale ||
      pixelRatio != oldDelegate.pixelRatio;
}

/// Auto-hiding zoom level display widget with smooth fade animation.
///
/// Shows zoom scale for 1 second after changes, then fades out.
/// Properly manages timer lifecycle and mounted state checks.
class _ZoomLevelDisplay extends StatefulWidget {
  const _ZoomLevelDisplay({
    required this.zoomScale,
  });

  final double zoomScale;

  @override
  State<_ZoomLevelDisplay> createState() => _ZoomLevelDisplayState();
}

class _ZoomLevelDisplayState extends State<_ZoomLevelDisplay> {
  static const _visibilityDuration = Duration(seconds: 1);
  static const _animationDuration = Duration(milliseconds: 200);

  Timer? _hideTimer;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    _showZoomScale();
  }

  @override
  void didUpdateWidget(covariant _ZoomLevelDisplay oldWidget) {
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
    _hideTimer = Timer(_visibilityDuration, () {
      if (mounted) {
        setState(() => _isVisible = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _isVisible ? 1.0 : 0.0,
        duration: _animationDuration,
        child: InformationBoxWidget(
          color: context.ispectTheme.primary?.resolve(context),
          child: Text('x${widget.zoomScale}'),
        ),
      );
}
