import 'dart:typed_data';

import 'package:flutter/material.dart';

Color getPixelFromByteData(
  ByteData byteData, {
  required int width,
  required int x,
  required int y,
}) {
  final index = (y * width + x) * 4;

  if (index >= byteData.lengthInBytes) {
    return Colors.transparent;
  }

  final r = byteData.getUint8(index);
  final g = byteData.getUint8(index + 1);
  final b = byteData.getUint8(index + 2);
  final a = byteData.getUint8(index + 3);

  return Color.fromARGB(a, r, g, b);
}

/// Returns the [color] in hexadecimal (#RRGGBB) format.
///
/// If [withAlpha] is `true`, then returns it in #AARRGGBB format.
String colorToHexString(Color color, {bool withAlpha = false}) {
  final a = color.a.round().toRadixString(16).padLeft(2, '0');
  final r = color.r.round().toRadixString(16).padLeft(2, '0');
  final g = color.g.round().toRadixString(16).padLeft(2, '0');
  final b = color.b.round().toRadixString(16).padLeft(2, '0');

  if (withAlpha) {
    return '$a$r$g$b';
  }

  return '$r$g$b';
}

Color getTextColorOnBackground(Color background) {
  final luminance = background.computeLuminance();

  if (luminance > 0.5) return Colors.black;
  return Colors.white;
}
