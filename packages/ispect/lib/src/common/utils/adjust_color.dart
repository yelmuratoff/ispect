import 'package:flutter/material.dart';

/// Adjusts the brightness of a given [color] by the specified [brightness] factor.
///
/// The [brightness] value must be between `0.0` (completely dark) and `1.0` (original color).
///
/// This function modifies the red, green, and blue components of the color based on the
/// brightness factor, ensuring a smooth transition between light and dark shades.
///
/// ### Example:
/// ```dart
/// Color baseColor = Colors.blue;
/// Color brighterColor = adjustColorBrightness(baseColor, 0.8);
/// ```
///
/// - If [brightness] is `1.0`, the color remains unchanged.
/// - If [brightness] is `0.0`, the color becomes black.
///
/// Throws an assertion error if [brightness] is outside the valid range.
Color adjustColorBrightness(Color color, double brightness) {
  assert(
    brightness >= 0.0 && brightness <= 1.0,
    'Brightness must be between 0.0 and 1.0',
  );

  final red = color.r * brightness;
  final green = color.g * brightness;
  final blue = color.b * brightness;

  return color.withValues(
    alpha: color.a,
    red: red,
    green: green,
    blue: blue,
  );
}

/// Darkens a given [color] by the specified [darken] factor.
///
/// The [darken] value must be between `0.0` (original color) and `1.0` (completely black).
///
/// This function reduces the red, green, and blue components proportionally to create a
/// darker version of the input color.
///
/// ### Example:
/// ```dart
/// Color baseColor = Colors.red;
/// Color darkerColor = adjustColorDarken(baseColor, 0.2);
/// ```
///
/// - If [darken] is `0.0`, the color remains unchanged.
/// - If [darken] is `1.0`, the color becomes black.
///
/// Throws an assertion error if [darken] is outside the valid range.
Color adjustColorDarken(Color color, double darken) {
  assert(
    darken >= 0.0 && darken <= 1.0,
    'Darken must be between 0.0 and 1.0',
  );

  final red = color.r * (1.0 - darken);
  final green = color.g * (1.0 - darken);
  final blue = color.b * (1.0 - darken);

  return color.withValues(
    alpha: color.a,
    red: red,
    green: green,
    blue: blue,
  );
}

/// Adjusts the given [color] based on the [value] and [isDark] flag.
///
/// If [isDark] is `true`, the function darkens the color using [adjustColorDarken].
/// Otherwise, it brightens the color using [adjustColorBrightness].
///
/// The [value] parameter determines the intensity of the adjustment.
/// - If [isDark] is `true`, a higher [value] makes the color darker.
/// - If [isDark] is `false`, a higher [value] makes the color brighter.
///
/// ### Example:
/// ```dart
/// Color baseColor = Colors.green;
/// Color modifiedColor = adjustColor(color: baseColor, value: 0.3, isDark: true);
/// ```
///
/// Throws an assertion error if [value] is not within the valid range (`0.0 - 1.0`).
Color adjustColor({
  required Color color,
  required double value,
  required bool isDark,
}) {
  assert(
    value >= 0.0 && value <= 1.0,
    'Value must be between 0.0 and 1.0',
  );

  return isDark
      ? adjustColorDarken(color, value)
      : adjustColorBrightness(color, value);
}
