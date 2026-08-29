import 'package:flutter/material.dart';

/// Squircle shape helpers for the inspector overlay UI.
///
/// Mirrors ISpect's design language but is kept local because `ispect_layout`
/// is a standalone package and must not depend on `ispect`. The shape is
/// Flutter's [RoundedSuperellipseBorder] — the iOS squircle the framework
/// gained in 3.32 — which scales its radii down to the box it lands on, so one
/// [radius] is safe on a wide toolbar and on a narrow chip alike.
///
/// [radius] is the corner radius itself, as it is for a circular corner.
abstract final class InspectorSquircle {
  const InspectorSquircle._();

  /// A squircle border for [radius], with an optional [side]. Use as a `shape:`
  /// on [Material], [InkWell.customBorder], or [ShapeDecoration].
  static RoundedSuperellipseBorder border({
    double radius = 12,
    BorderSide side = BorderSide.none,
  }) => borderOf(BorderRadius.all(Radius.circular(radius)), side: side);

  /// The same squircle for a [borderRadius] that differs per corner.
  static RoundedSuperellipseBorder borderOf(
    BorderRadiusGeometry borderRadius, {
    BorderSide side = BorderSide.none,
  }) => RoundedSuperellipseBorder(borderRadius: borderRadius, side: side);

  /// A [ShapeDecoration] with squircle corners for [radius].
  static ShapeDecoration decoration({
    Color? color,
    double radius = 12,
    BorderSide side = BorderSide.none,
    List<BoxShadow>? shadows,
  }) => ShapeDecoration(
    color: color,
    shadows: shadows,
    shape: border(radius: radius, side: side),
  );
}
