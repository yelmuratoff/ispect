import 'package:flutter/material.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

/// Squircle shape factory shared across ISpect surfaces.
///
/// Every card, badge, button, sheet, and panel face goes through here, so the
/// corner is defined once. The shape is Flutter's [RoundedSuperellipseBorder]
/// — the iOS squircle the framework gained in 3.32 — which scales its radii
/// down to the box it lands on, so one logical radius is safe on a 400-pixel
/// sheet and on a 35-pixel tab alike.
///
/// [radius] is the corner radius itself, as it is for a circular corner — the
/// superellipse does not fall short the way a [ContinuousRectangleBorder] does,
/// so nothing is scaled on the way in.
abstract final class ISpectSquircle {
  const ISpectSquircle._();

  /// A squircle border for [radius], with an optional [side]. Use as a `shape:`
  /// on [Material], [InkWell.customBorder], or [ShapeDecoration].
  static RoundedSuperellipseBorder border({
    double radius = ISpectConstants.cardBorderRadius,
    BorderSide side = BorderSide.none,
  }) => borderOf(BorderRadius.all(Radius.circular(radius)), side: side);

  /// The same squircle for a [borderRadius] that differs per corner.
  static RoundedSuperellipseBorder borderOf(
    BorderRadiusGeometry borderRadius, {
    BorderSide side = BorderSide.none,
  }) => RoundedSuperellipseBorder(borderRadius: borderRadius, side: side);

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
    borderRadius: BorderRadius.all(Radius.circular(radius)),
    borderSide: side,
  );
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

/// [InputBorder] that paints squircle corners by delegating to a
/// [RoundedSuperellipseBorder]. The floating-label gap is ignored — ISpect
/// inputs use hint text, not floating labels.
class ISpectSquircleInputBorder extends InputBorder {
  const ISpectSquircleInputBorder({
    super.borderSide = BorderSide.none,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  final BorderRadius borderRadius;

  RoundedSuperellipseBorder get _shape =>
      RoundedSuperellipseBorder(borderRadius: borderRadius, side: borderSide);

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
