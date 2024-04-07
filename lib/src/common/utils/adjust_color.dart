import 'package:flutter/material.dart';

Color adjustColorBrightness(Color color, double brightness) {
  assert(brightness >= 0.0 && brightness <= 1.0, 'Brightness must be between 0.0 and 1.0');

  int red = ((color.red * brightness) + (255 * (1.0 - brightness))).round();
  int green = ((color.green * brightness) + (255 * (1.0 - brightness))).round();
  int blue = ((color.blue * brightness) + (255 * (1.0 - brightness))).round();

  return Color.fromARGB(color.alpha, red, green, blue);
}
