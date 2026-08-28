import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

/// Squircle (continuous-corner) shape factory shared across ISpect surfaces.
///
/// Continuous corners under-round versus a circular radius of the same value,
/// so a logical radius is multiplied by [scale] before being handed to
/// [ContinuousRectangleBorder]. Routing every card, badge, button, and sheet
/// through this one place keeps the squircle roundness uniform and lets call
/// sites keep passing the same logical radii they used for circular corners.
abstract final class ISpectSquircle {
  const ISpectSquircle._();

  /// Multiplier applied to a logical radius so a [ContinuousRectangleBorder]
  /// reads as round as a circular radius of the original value.
  static const double scale = 2;

  /// A [ContinuousRectangleBorder] for the logical [radius], with an optional
  /// [side]. Use as a `shape:` on [Material], [InkWell.customBorder], or
  /// [ShapeDecoration].
  static ContinuousRectangleBorder border({
    double radius = ISpectConstants.cardBorderRadius,
    BorderSide side = BorderSide.none,
  }) => ContinuousRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius * scale)),
    side: side,
  );

  /// A squircle that caps its radius at half the shortest side of the rect it
  /// is painted into.
  ///
  /// [ContinuousRectangleBorder] clamps a radius to the whole shortest side,
  /// and past half of it `_getPath` walks each edge backwards — the top runs
  /// from `left + radius` to `right - radius` once those cross. A visible
  /// [BorderSide] strokes the four reversed edges as bars sticking out of the
  /// shape. Reach for this where one shape is painted onto boxes of different
  /// sizes, so no single radius can be right for all of them.
  static OutlinedBorder adaptiveBorder({
    double radius = ISpectConstants.cardBorderRadius,
    BorderSide side = BorderSide.none,
  }) => ISpectAdaptiveSquircle(radius: radius, side: side);

  /// Returns a squircle clip deflated by [insets] without shrinking its
  /// widget's layout or hit-test bounds.
  static ShapeBorder insetBorder({
    required EdgeInsets insets,
    double radius = ISpectConstants.cardBorderRadius,
  }) => _InsetShapeBorder(
    border: border(radius: radius),
    insets: insets,
  );

  /// A [ShapeDecoration] with squircle corners for the logical [radius]; a
  /// drop-in replacement for a `BoxDecoration(borderRadius: …)` fill or border.
  static ShapeDecoration decoration({
    Color? color,
    double radius = ISpectConstants.cardBorderRadius,
    BorderSide side = BorderSide.none,
    Gradient? gradient,
    List<BoxShadow>? shadows,
  }) => ShapeDecoration(
    color: color,
    gradient: gradient,
    shadows: shadows,
    shape: border(radius: radius, side: side),
  );

  /// An [InputBorder] with squircle corners for the logical [radius]; use it
  /// for `TextField`/`SearchBar` so inputs match the rest of the surfaces
  /// (Material's [OutlineInputBorder] only draws circular corners).
  static ISpectSquircleInputBorder inputBorder({
    double radius = ISpectConstants.cardBorderRadius,
    BorderSide side = BorderSide.none,
  }) => ISpectSquircleInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(radius * scale)),
    borderSide: side,
  );
}

/// A [ContinuousRectangleBorder] sized to the rect it lands on. See
/// [ISpectSquircle.adaptiveBorder].
@immutable
final class ISpectAdaptiveSquircle extends OutlinedBorder {
  const ISpectAdaptiveSquircle({
    this.radius = ISpectConstants.cardBorderRadius,
    super.side,
  });

  /// The logical radius, before [ISpectSquircle.scale] and the per-rect cap.
  final double radius;

  ContinuousRectangleBorder _resolve(Rect rect) => ContinuousRectangleBorder(
    borderRadius: BorderRadius.all(
      Radius.circular(
        math.min(radius * ISpectSquircle.scale, rect.shortestSide / 2),
      ),
    ),
    side: side,
  );

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _resolve(rect).getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _resolve(rect).getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) =>
      _resolve(rect).paint(canvas, rect, textDirection: textDirection);

  @override
  ISpectAdaptiveSquircle copyWith({BorderSide? side, double? radius}) =>
      ISpectAdaptiveSquircle(
        radius: radius ?? this.radius,
        side: side ?? this.side,
      );

  @override
  ISpectAdaptiveSquircle scale(double t) =>
      ISpectAdaptiveSquircle(radius: radius * t, side: side.scale(t));

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is ISpectAdaptiveSquircle
      ? ISpectAdaptiveSquircle(
          radius: lerpDouble(a.radius, radius, t)!,
          side: BorderSide.lerp(a.side, side, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is ISpectAdaptiveSquircle
      ? ISpectAdaptiveSquircle(
          radius: lerpDouble(radius, b.radius, t)!,
          side: BorderSide.lerp(side, b.side, t),
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ISpectAdaptiveSquircle &&
          other.radius == radius &&
          other.side == side;

  @override
  int get hashCode => Object.hash(radius, side);
}

final class _InsetShapeBorder extends ShapeBorder {
  const _InsetShapeBorder({required this.border, required this.insets});

  final ShapeBorder border;
  final EdgeInsets insets;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => border
      .getInnerPath(insets.deflateRect(rect), textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => border
      .getOuterPath(insets.deflateRect(rect), textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) => border
      .paint(canvas, insets.deflateRect(rect), textDirection: textDirection);

  @override
  ShapeBorder scale(double t) => _InsetShapeBorder(
    border: border.scale(t),
    insets: EdgeInsets.fromLTRB(
      insets.left * t,
      insets.top * t,
      insets.right * t,
      insets.bottom * t,
    ),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _InsetShapeBorder &&
          other.border == border &&
          other.insets == insets;

  @override
  int get hashCode => Object.hash(border, insets);
}

/// [InputBorder] that paints continuous (squircle) corners by delegating to a
/// [ContinuousRectangleBorder]. The floating-label gap is ignored — ISpect
/// inputs use hint text, not floating labels.
class ISpectSquircleInputBorder extends InputBorder {
  const ISpectSquircleInputBorder({
    super.borderSide = BorderSide.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final BorderRadius borderRadius;

  ContinuousRectangleBorder get _shape =>
      ContinuousRectangleBorder(borderRadius: borderRadius, side: borderSide);

  @override
  bool get isOutline => true;

  @override
  ISpectSquircleInputBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
  }) => ISpectSquircleInputBorder(
    borderSide: borderSide ?? this.borderSide,
    borderRadius: borderRadius ?? this.borderRadius,
  );

  @override
  EdgeInsetsGeometry get dimensions => _shape.dimensions;

  @override
  ISpectSquircleInputBorder scale(double t) => ISpectSquircleInputBorder(
    borderSide: borderSide.scale(t),
    borderRadius: borderRadius * t,
  );

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getInnerPath(rect, textDirection: textDirection);

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      _shape.getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    if (borderSide.style == BorderStyle.none) return;
    _shape.paint(canvas, rect, textDirection: textDirection);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ISpectSquircleInputBorder &&
          other.borderSide == borderSide &&
          other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hash(borderSide, borderRadius);
}
