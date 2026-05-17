import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ispect_layout/src/widgets/color_picker/utils.dart';
import 'package:ispect_layout/src/widgets/zoom/zoom_painter.dart';

/// Visual style for [ZoomableColorPickerOverlay]. Centralises the magic
/// numbers that used to be hard-coded inside the widget tree.
class ZoomableColorPickerStyle {
  const ZoomableColorPickerStyle({
    this.outerRingWidth = 2.0,
    this.colorRingWidth = 16.0,
    this.innerRingWidth = 2.0,
    this.shadowBlur = 12.0,
    this.shadowSpread = 1.0,
    this.shadowColor = const Color(0x1F000000),
    this.crosshairThickness = 1.0,
    this.crosshairLength = 14.0,
    this.crosshairGap = 4.0,
    this.backgroundColor = const Color(0xFF1E1E1E),
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoomableColorPickerStyle &&
          runtimeType == other.runtimeType &&
          outerRingWidth == other.outerRingWidth &&
          colorRingWidth == other.colorRingWidth &&
          innerRingWidth == other.innerRingWidth &&
          shadowBlur == other.shadowBlur &&
          shadowSpread == other.shadowSpread &&
          shadowColor == other.shadowColor &&
          crosshairThickness == other.crosshairThickness &&
          crosshairLength == other.crosshairLength &&
          crosshairGap == other.crosshairGap &&
          backgroundColor == other.backgroundColor;

  @override
  int get hashCode => Object.hash(
        outerRingWidth,
        colorRingWidth,
        innerRingWidth,
        shadowBlur,
        shadowSpread,
        shadowColor,
        crosshairThickness,
        crosshairLength,
        crosshairGap,
        backgroundColor,
      );

  final double outerRingWidth;
  final double colorRingWidth;
  final double innerRingWidth;
  final double shadowBlur;
  final double shadowSpread;
  final Color shadowColor;
  final double crosshairThickness;
  final double crosshairLength;
  final double crosshairGap;
  final Color backgroundColor;

  static const ZoomableColorPickerStyle defaults = ZoomableColorPickerStyle();
}

/// Where the HUD chip is rendered relative to the picker disc. The caller
/// computes the best fit based on available screen space; the overlay just
/// places the chip accordingly.
enum HudPlacement { above, right, below, left }

/// Combined overlay for the zoomable colour picker.
///
/// Composition (top-down rebuild scope):
/// - [_PickerCanvas] — owns the ZoomPainter (repaints on offset/scale/image).
/// - [_PickerCrosshair] — 1-px crosshair indicating the sampled pixel.
/// - [_PickerRingPainter] — three concentric rings + drop shadow in one paint.
/// - [_PickerHud] — hex + WCAG contrast chip.
class ZoomableColorPickerOverlay extends StatelessWidget {
  const ZoomableColorPickerOverlay({
    super.key,
    required this.image,
    required this.imageOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
    required this.color,
    this.hudPlacement = HudPlacement.above,
    this.style = ZoomableColorPickerStyle.defaults,
  });

  final ui.Image image;
  final Offset imageOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;
  final Color color;

  /// Side of the disc the HUD chip is rendered on. The caller picks the
  /// first side that has enough room on screen (priority above → right →
  /// left → below), so the chip never gets clipped.
  final HudPlacement hudPlacement;
  final ZoomableColorPickerStyle style;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ringBorderColor = colorScheme.inverseSurface.withValues(alpha: 0.2);

    // Layout footprint stays exactly overlaySize × overlaySize so the disc
    // never shifts when the HUD reflows. The HUD is a Positioned overlay
    // anchored at the disc's horizontal centre via a -50% self-translation,
    // and is free to overflow below the Stack thanks to Clip.none.
    return Material(
      color: Colors.transparent,
      child: SizedBox.square(
        dimension: overlaySize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: _PickerCircle(
                color: color,
                ringBorderColor: ringBorderColor,
                style: style,
                child: ClipOval(
                  child: RepaintBoundary(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: _PickerCanvas(
                            image: image,
                            imageOffset: imageOffset,
                            overlaySize: overlaySize,
                            zoomScale: zoomScale,
                            pixelRatio: pixelRatio,
                            backgroundColor: style.backgroundColor,
                          ),
                        ),
                        Positioned.fill(
                          child: _PickerCrosshair(style: style),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: ZoomLevelIndicator(zoomScale: zoomScale),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // HUD: by default anchored ABOVE the disc (cursor lives below
            // the picker, putting the chip below would sit under the finger).
            // The caller picks a different side when there's no room — e.g.
            // when the picker hugs the top of the screen.
            _hudPositioned(
              child: _PickerHud(
                color: color,
                surface: colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Positions the HUD chip on the requested side of the disc, with a small
  /// gap. The chip is centred along the side's cross-axis. Gap accounts for
  /// the rings drawn outside the canvas so the chip never overlaps them.
  Widget _hudPositioned({required Widget child}) {
    final ringTotal =
        style.outerRingWidth + style.colorRingWidth + style.innerRingWidth;
    final gapAxial = 16.0 + ringTotal;
    final gapLateral = 12.0 + ringTotal;

    switch (hudPlacement) {
      case HudPlacement.above:
        return Positioned(
          left: overlaySize / 2,
          bottom: overlaySize + gapAxial,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0),
            child: child,
          ),
        );
      case HudPlacement.below:
        return Positioned(
          left: overlaySize / 2,
          top: overlaySize + gapAxial,
          child: FractionalTranslation(
            translation: const Offset(-0.5, 0),
            child: child,
          ),
        );
      case HudPlacement.right:
        return Positioned(
          left: overlaySize + gapLateral,
          top: overlaySize / 2,
          child: FractionalTranslation(
            translation: const Offset(0, -0.5),
            child: child,
          ),
        );
      case HudPlacement.left:
        return Positioned(
          right: overlaySize + gapLateral,
          top: overlaySize / 2,
          child: FractionalTranslation(
            translation: const Offset(0, -0.5),
            child: child,
          ),
        );
    }
  }
}

class _PickerCircle extends StatelessWidget {
  const _PickerCircle({
    required this.color,
    required this.ringBorderColor,
    required this.style,
    required this.child,
  });

  final Color color;
  final Color ringBorderColor;
  final ZoomableColorPickerStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Rings are painted OUTSIDE the canvas (the Stack above uses Clip.none),
    // so the zoomed image fills the full overlaySize and the disc visually
    // grows beyond its layout box — matching the legacy strokeAlignOutside
    // look where the inner picture was never cropped by the frame.
    return CustomPaint(
      painter: _PickerRingPainter(
        color: color,
        borderColor: ringBorderColor,
        style: style,
      ),
      child: child,
    );
  }
}

/// Paints — in one go — the drop shadow and three concentric rings that
/// frame the zoomed image. Replaces three nested DecoratedBox + a clipped
/// BoxShadow that wasn't rendering correctly with `strokeAlignOutside`.
class _PickerRingPainter extends CustomPainter {
  _PickerRingPainter({
    required this.color,
    required this.borderColor,
    required this.style,
  });

  final Color color;
  final Color borderColor;
  final ZoomableColorPickerStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    final canvasRadius = shortestSide / 2;

    final outerW = style.outerRingWidth;
    final colorW = style.colorRingWidth;
    final innerW = style.innerRingWidth;

    // Three concentric strokes laid OUTSIDE the canvas, in the order they
    // sit visually (closest-to-image first). The image area itself stays
    // the full overlaySize.
    final radii = <_RingSpec>[
      _RingSpec(
        radius: canvasRadius + innerW / 2,
        width: innerW,
        color: borderColor,
      ),
      _RingSpec(
        radius: canvasRadius + innerW + colorW / 2,
        width: colorW,
        color: color,
      ),
      _RingSpec(
        radius: canvasRadius + innerW + colorW + outerW / 2,
        width: outerW,
        color: borderColor,
      ),
    ];

    // Drop shadow under the whole disc — drawn first so it sits behind
    // the rings. Anchored at the outermost ring rim so the soft halo wraps
    // the visible disc, not the inner image edge.
    final discOuterRadius = canvasRadius + innerW + colorW + outerW;
    if (style.shadowColor.a > 0 && style.shadowBlur > 0) {
      canvas.drawCircle(
        center,
        discOuterRadius + style.shadowSpread,
        Paint()
          ..color = style.shadowColor
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, style.shadowBlur),
      );
    }

    final paint = Paint()..style = PaintingStyle.stroke;
    for (final ring in radii) {
      paint
        ..color = ring.color
        ..strokeWidth = ring.width;
      canvas.drawCircle(center, ring.radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PickerRingPainter oldDelegate) =>
      color != oldDelegate.color ||
      borderColor != oldDelegate.borderColor ||
      style != oldDelegate.style;
}

class _RingSpec {
  const _RingSpec({
    required this.radius,
    required this.width,
    required this.color,
  });
  final double radius;
  final double width;
  final Color color;
}

class _PickerCanvas extends StatelessWidget {
  const _PickerCanvas({
    required this.image,
    required this.imageOffset,
    required this.overlaySize,
    required this.zoomScale,
    required this.pixelRatio,
    required this.backgroundColor,
  });

  final ui.Image image;
  final Offset imageOffset;
  final double overlaySize;
  final double zoomScale;
  final double pixelRatio;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        willChange: true,
        painter: ZoomPainter(
          image: image,
          imageOffset: imageOffset,
          overlaySize: overlaySize,
          zoomScale: zoomScale,
          pixelRatio: pixelRatio,
          backgroundColor: backgroundColor,
        ),
      ),
    );
  }
}

/// Crosshair indicator with a transparent gap at the centre, so the user can
/// see the actual sampled pixel through the cross.
class _PickerCrosshair extends StatelessWidget {
  const _PickerCrosshair({required this.style});

  final ZoomableColorPickerStyle style;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CrosshairPainter(
        thickness: style.crosshairThickness,
        length: style.crosshairLength,
        gap: style.crosshairGap,
      ),
    );
  }
}

/// Two-pass crosshair: a thicker semi-transparent dark outline and a thinner
/// solid white inner line for readable contrast on any background. A thin
/// 1-px white border (no fill, no shadow) marks the centre pixel — strictly
/// a hairline, not a chip.
class _CrosshairPainter extends CustomPainter {
  _CrosshairPainter({
    required this.thickness,
    required this.length,
    required this.gap,
  });

  final double thickness;
  final double length;
  final double gap;

  static const double _boxSize = 6.0;
  static const Radius _boxRadius = Radius.circular(1.0);

  static final _outlinePaint = Paint()
    ..color = const Color(0xCC000000)
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke;
  static final _innerPaint = Paint()
    ..color = const Color(0xFFFFFFFF)
    ..isAntiAlias = false
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    void drawArms(Paint paint) {
      canvas
        ..drawLine(Offset(cx - length, cy), Offset(cx - gap, cy), paint)
        ..drawLine(Offset(cx + gap, cy), Offset(cx + length, cy), paint)
        ..drawLine(Offset(cx, cy - length), Offset(cx, cy - gap), paint)
        ..drawLine(Offset(cx, cy + gap), Offset(cx, cy + length), paint);
    }

    _outlinePaint.strokeWidth = thickness + 2.0;
    drawArms(_outlinePaint);

    _innerPaint.strokeWidth = thickness;
    drawArms(_innerPaint);

    // Pixel marker: a single 1-px hairline outline, no fill, no inner pass.
    // The interior shows the zoomed pixel through — that's what tells the
    // user which pixel they're sampling. Dark stroke so it stays a visible
    // outline (not a "container") even when the underlying pixel is white.
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: _boxSize,
        height: _boxSize,
      ),
      _boxRadius,
    );
    _outlinePaint.strokeWidth = 1.0;
    canvas.drawRRect(boxRect, _outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _CrosshairPainter oldDelegate) =>
      thickness != oldDelegate.thickness ||
      length != oldDelegate.length ||
      gap != oldDelegate.gap;
}

/// HUD shown below the picker circle. Single fixed-height chip with the
/// hex value and a WCAG contrast hint — never reflows during pixel hunting.
///
/// ColorScheme token matches are intentionally not shown here: they fire too
/// rarely (anti-aliased pixels almost never equal a pure token), and when
/// they do, the layout shift jerks the picker. The match is surfaced in the
/// commit snackbar instead, where it has room and timing on its side.
class _PickerHud extends StatelessWidget {
  const _PickerHud({
    required this.color,
    required this.surface,
  });

  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    final textColor = getTextColorOnBackground(color);
    final hex = colorToDisplayHex(color);
    final ratio = contrastRatio(color, surface);
    final wcag = wcagLevel(ratio);

    final hexStyle = TextStyle(
      color: textColor.withValues(alpha: 0.9),
      fontSize: 12,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w600,
    );
    final ratioStyle = TextStyle(
      color: textColor.withValues(alpha: 0.7),
      fontSize: 11,
      fontFeatures: const [FontFeature.tabularFigures()],
      fontWeight: FontWeight.w500,
    );

    return _Chip(
      background: color,
      border: textColor.withValues(alpha: 0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(hex, softWrap: false, style: hexStyle),
          const SizedBox(width: 8),
          Text(
            '${ratio.toStringAsFixed(2)}:1 $wcag',
            softWrap: false,
            style: ratioStyle,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.background,
    required this.border,
    required this.child,
  });

  final Color background;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: child,
      ),
    );
  }
}
