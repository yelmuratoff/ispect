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

  /// Exponent of the superellipse [adaptiveBorder] draws. `2` is a circular
  /// arc and larger is squarer; an iOS icon sits near `5`. This one is close
  /// to the circle, where the corner still reads as a squircle rather than as
  /// a rounded rectangle.
  static const double superellipseExponent = 2.6;

  /// A superellipse corner whose radius is capped at half the shortest side of
  /// the rect it is painted into.
  ///
  /// Two reasons to reach for this over [border]. It rounds further:
  /// [ContinuousRectangleBorder] is a shallow approximation that runs out of
  /// roundness at half the shortest side, which is where the panel's collapsed
  /// button already sits. And it stays well formed at any size:
  /// `ContinuousRectangleBorder` clamps a radius to the whole shortest side,
  /// and past half of it `_getPath` walks each edge backwards — the top runs
  /// from `left + radius` to `right - radius` once those cross — so a visible
  /// [BorderSide] strokes the four reversed edges as bars outside the shape.
  ///
  /// Use it where one shape is painted onto boxes of different sizes, so no
  /// single radius can be right for all of them.
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

/// A true superellipse corner, sized to the rect it lands on.
/// See [ISpectSquircle.adaptiveBorder].
@immutable
final class ISpectAdaptiveSquircle extends OutlinedBorder {
  const ISpectAdaptiveSquircle({
    this.radius = ISpectConstants.cardBorderRadius,
    this.exponent = ISpectSquircle.superellipseExponent,
    super.side,
  });

  /// Corner radius, capped at half the shortest side of the painted rect.
  ///
  /// Unlike [ISpectSquircle.border] this is the radius itself, with no
  /// [ISpectSquircle.scale] correction: that factor exists to offset how far
  /// [ContinuousRectangleBorder] falls short of a squircle, and a superellipse
  /// does not fall short.
  final double radius;

  /// Superellipse exponent. `2` is a circular arc, larger is squarer.
  final double exponent;

  /// Segments per corner. A corner never exceeds half the shortest side, so a
  /// fixed count keeps the longest arc under a pixel per segment.
  static const int _segments = 32;

  static double? _tabledExponent;
  static List<Offset>? _table;

  /// The corner sampled on a unit radius, so a paint scales the table instead
  /// of calling [math.pow] twice per segment.
  ///
  /// One entry, not a map: the exponent is interpolated by [lerpFrom], so a
  /// cache keyed by every value it passes through would grow without bound.
  static List<Offset> _unitCorner(double exponent) {
    final cached = _table;
    if (cached != null && _tabledExponent == exponent) return cached;

    final power = 2 / exponent;
    final built = List<Offset>.generate(_segments + 1, (i) {
      final t = i / _segments * (math.pi / 2);
      return Offset(
        math.pow(math.cos(t), power).toDouble(),
        math.pow(math.sin(t), power).toDouble(),
      );
    }, growable: false);
    _tabledExponent = exponent;
    _table = built;
    return built;
  }

  Path _path(Rect rect) {
    final r = math.min(radius, rect.shortestSide / 2);
    if (r <= 0) return Path()..addRect(rect);

    final unit = _unitCorner(exponent);
    final path = Path()..moveTo(rect.left, rect.top + r);
    void corner(
      double cx,
      double cy,
      double sx,
      double sy, {
      required bool forward,
    }) {
      for (var i = 0; i <= _segments; i++) {
        final point = unit[forward ? i : _segments - i];
        path.lineTo(cx + sx * (r - r * point.dx), cy + sy * (r - r * point.dy));
      }
    }

    corner(rect.left, rect.top, 1, 1, forward: true);
    path.lineTo(rect.right - r, rect.top);
    corner(rect.right, rect.top, -1, 1, forward: false);
    path.lineTo(rect.right, rect.bottom - r);
    corner(rect.right, rect.bottom, -1, -1, forward: true);
    path.lineTo(rect.left + r, rect.bottom);
    corner(rect.left, rect.bottom, 1, -1, forward: false);
    return path..close();
  }

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none) return;
    canvas.drawPath(_path(rect), side.toPaint());
  }

  @override
  ISpectAdaptiveSquircle copyWith({
    BorderSide? side,
    double? radius,
    double? exponent,
  }) => ISpectAdaptiveSquircle(
    radius: radius ?? this.radius,
    exponent: exponent ?? this.exponent,
    side: side ?? this.side,
  );

  @override
  ISpectAdaptiveSquircle scale(double t) => ISpectAdaptiveSquircle(
    radius: radius * t,
    exponent: exponent,
    side: side.scale(t),
  );

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) => a is ISpectAdaptiveSquircle
      ? ISpectAdaptiveSquircle(
          radius: lerpDouble(a.radius, radius, t)!,
          exponent: lerpDouble(a.exponent, exponent, t)!,
          side: BorderSide.lerp(a.side, side, t),
        )
      : super.lerpFrom(a, t);

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) => b is ISpectAdaptiveSquircle
      ? ISpectAdaptiveSquircle(
          radius: lerpDouble(radius, b.radius, t)!,
          exponent: lerpDouble(exponent, b.exponent, t)!,
          side: BorderSide.lerp(side, b.side, t),
        )
      : super.lerpTo(b, t);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ISpectAdaptiveSquircle &&
          other.radius == radius &&
          other.exponent == exponent &&
          other.side == side;

  @override
  int get hashCode => Object.hash(radius, exponent, side);
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
