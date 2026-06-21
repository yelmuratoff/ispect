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
  }) =>
      ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius * scale)),
        side: side,
      );

  /// A [ShapeDecoration] with squircle corners for the logical [radius]; a
  /// drop-in replacement for a `BoxDecoration(borderRadius: …)` fill or border.
  static ShapeDecoration decoration({
    Color? color,
    double radius = ISpectConstants.cardBorderRadius,
    BorderSide side = BorderSide.none,
    Gradient? gradient,
    List<BoxShadow>? shadows,
  }) =>
      ShapeDecoration(
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
  }) =>
      ISpectSquircleInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius * scale)),
        borderSide: side,
      );
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
  }) =>
      ISpectSquircleInputBorder(
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
