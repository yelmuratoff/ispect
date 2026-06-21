import 'package:flutter/material.dart';

/// Squircle (continuous-corner) shape helpers for the inspector overlay UI.
///
/// Mirrors ISpect's design language (continuous corners, scale 1.8) but is kept
/// local because `ispect_layout` is a standalone package and must not depend on
/// `ispect`. Continuous corners under-round versus a circular radius of the same
/// value, so a logical [radius] is multiplied by [scale].
abstract final class InspectorSquircle {
  const InspectorSquircle._();

  /// Multiplier applied to a logical radius so a [ContinuousRectangleBorder]
  /// reads as round as a circular radius of the original value. Must stay in
  /// sync with `ISpectSquircle.scale` so both packages render alike.
  static const double scale = 2;

  /// A [ContinuousRectangleBorder] for the logical [radius], with an optional
  /// [side]. Use as a `shape:` on [Material], [InkWell.customBorder], or
  /// [ShapeDecoration].
  static ContinuousRectangleBorder border({
    double radius = 12,
    BorderSide side = BorderSide.none,
  }) =>
      ContinuousRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius * scale)),
        side: side,
      );

  /// A [ShapeDecoration] with squircle corners for the logical [radius].
  static ShapeDecoration decoration({
    Color? color,
    double radius = 12,
    BorderSide side = BorderSide.none,
    List<BoxShadow>? shadows,
  }) =>
      ShapeDecoration(
        color: color,
        shadows: shadows,
        shape: border(radius: radius, side: side),
      );
}
