import 'package:flutter/material.dart';

/// Color calculation helpers tailored for JSON viewer UI.
extension JsonColorCalc on Color {
  /// Returns black or white to provide readable text over this background.
  /// Threshold defaults to 0.5 luminance.
  Color contrastText({double threshold = 0.5}) {
    final l = computeLuminance();
    return l > threshold ? Colors.black : Colors.white;
  }

  /// Lightens the color by the given [amount] (0..1) using HSL space.
  Color lighten([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final lighter = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lighter.toColor();
  }

  /// Darkens the color by the given [amount] (0..1) using HSL space.
  Color darken([double amount = 0.1]) {
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darker.toColor();
  }

  /// Returns a copy of this color with alpha set as a percentage [alpha]
  /// in range 0..1.
  Color withAlphaPercent(double alpha) =>
      withValues(alpha: alpha.clamp(0.0, 1.0));

  /// Blends this color with [other] by factor [t] (0..1).
  Color blend(Color other, [double t = 0.5]) {
    final tt = t.clamp(0.0, 1.0);
    final rr = r + (other.r - r) * tt;
    final gg = g + (other.g - g) * tt;
    final bb = b + (other.b - b) * tt;
    final aa = a + (other.a - a) * tt;
    return withValues(red: rr, green: gg, blue: bb, alpha: aa);
  }
}
