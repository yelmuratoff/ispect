import 'package:flutter/material.dart';

Color adjustColorBrightness(Color color, double brightness) {
  assert(
    brightness >= 0.0 && brightness <= 1.0,
    'Brightness must be between 0.0 and 1.0',
  );

  final int red =
      ((color.red * brightness) + (255 * (1.0 - brightness))).round();
  final int green =
      ((color.green * brightness) + (255 * (1.0 - brightness))).round();
  final int blue =
      ((color.blue * brightness) + (255 * (1.0 - brightness))).round();

  return Color.fromARGB(color.alpha, red, green, blue);
}

Color adjustColorDarken(Color color, double darken) {
  assert(darken >= 0.0 && darken <= 1.0, 'Darken must be between 0.0 and 1.0');

  final int red = (color.red * (1.0 - darken)).round();
  final int green = (color.green * (1.0 - darken)).round();
  final int blue = (color.blue * (1.0 - darken)).round();

  return Color.fromARGB(color.alpha, red, green, blue);
}
