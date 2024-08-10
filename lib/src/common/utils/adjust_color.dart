import 'package:flutter/material.dart';

Color adjustColorBrightness(Color color, double brightness) {
  assert(
    brightness >= 0.0 && brightness <= 1.0,
    'Brightness must be between 0.0 and 1.0',
  );

  final red = ((color.red * brightness) + (255 * (1.0 - brightness))).round();
  final green = ((color.green * brightness) + (255 * (1.0 - brightness))).round();
  final blue = ((color.blue * brightness) + (255 * (1.0 - brightness))).round();

  return Color.fromARGB(color.alpha, red, green, blue);
}

Color adjustColorDarken(Color color, double darken) {
  assert(darken >= 0.0 && darken <= 1.0, 'Darken must be between 0.0 and 1.0');

  final red = (color.red * (1.0 - darken)).round();
  final green = (color.green * (1.0 - darken)).round();
  final blue = (color.blue * (1.0 - darken)).round();

  return Color.fromARGB(color.alpha, red, green, blue);
}

Color adjustColor({
  required Color color,
  required double value,
  required bool isDark,
}) {
  if (isDark) {
    return adjustColorDarken(color, value);
  } else {
    return adjustColorBrightness(color, value);
  }
}
