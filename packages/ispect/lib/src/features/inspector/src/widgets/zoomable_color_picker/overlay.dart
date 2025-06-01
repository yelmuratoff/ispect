import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/inspector/src/widgets/color_picker/utils.dart';
import 'package:ispect/src/features/inspector/src/widgets/components/information_box_widget.dart';

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
    final borderColor =
        context.ispectTheme.colorScheme.inverseSurface.withValues(alpha: 0.2);
    final textColor = getTextColorOnBackground(color);
    return SizedBox(
      width: overlaySize,
      height: overlaySize,
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
                  // Color hex display
                  Align(
                    alignment: const Alignment(0, -0.8),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: color,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(4)),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: textColor.withValues(alpha: 0.2),
                            ),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(4)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '#${colorToHexString(color)}',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Zoom level display
                  Align(
                    alignment: const Alignment(0, -0.8),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ZoomLevelDisplay(zoomScale: zoomScale),
                    ),
                  ),
                  // Centered color indicator
                  const _CenterColorIndicator(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CenterColorIndicator extends StatelessWidget {
  const _CenterColorIndicator();

  @override
  Widget build(BuildContext context) {
    final parent =
        context.findAncestorWidgetOfExactType<CombinedOverlayWidget>();
    if (parent == null) return const SizedBox.shrink();
    final color = parent.color;
    final borderColor = getTextColorOnBackground(color).withValues(alpha: 0.2);
    return Center(
      child: SizedBox.square(
        dimension: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

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
    canvas
      ..clipRect(Offset.zero & size)
      ..translate(overlaySize / 2.0, overlaySize / 2.0)
      ..scale((1 / pixelRatio) * zoomScale)
      ..drawImage(image, -imageOffset, Paint());
  }

  @override
  bool shouldRepaint(_ZoomPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.imageOffset != imageOffset ||
      oldDelegate.overlayOffset != overlayOffset ||
      oldDelegate.overlaySize != overlaySize ||
      oldDelegate.zoomScale != zoomScale;
}

class _ZoomLevelDisplay extends StatefulWidget {
  const _ZoomLevelDisplay({
    required this.zoomScale,
  });

  final double zoomScale;

  @override
  State<_ZoomLevelDisplay> createState() => __ZoomLevelDisplayState();
}

class __ZoomLevelDisplayState extends State<_ZoomLevelDisplay> {
  Timer? _zoomHideTimer;
  bool _isZoomScaleVisible = false;

  @override
  void initState() {
    super.initState();
    _showZoomScale();
  }

  Future<void> _showZoomScale() async {
    if (mounted) {
      setState(() => _isZoomScaleVisible = true);
    }
    _zoomHideTimer?.cancel();
    _zoomHideTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isZoomScaleVisible = false);
      }
    });
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
    _zoomHideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _isZoomScaleVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: InformationBoxWidget(
          color: context.ispectTheme.colorScheme.primary,
          child: Text('x${widget.zoomScale}'),
        ),
      );
}
