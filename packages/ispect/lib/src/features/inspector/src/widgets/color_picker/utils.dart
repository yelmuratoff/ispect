import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Retrieves the color of a pixel from a `ByteData` object at the specified
/// coordinates (`x`, [y]) within an image of the given [width].
///
/// The `ByteData` is expected to represent an image in a format where each
/// pixel is stored as 4 consecutive bytes (RGBA format).
///
/// If the calculated index for the pixel exceeds the length of the `ByteData`,
/// the method returns `Colors.transparent`.
///
/// - Parameters:
///   - byteData: The `ByteData` object containing the image data.
///   - width: The width of the image in pixels.
///   - x: The x-coordinate of the pixel to retrieve.
///   - y: The y-coordinate of the pixel to retrieve.
///
/// - Returns: A `Color` object representing the color of the pixel at the
///   specified coordinates.
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

/// Converts a `Color` object to its hexadecimal string representation.
///
/// The returned string is in the format `#RRGGBB` by default. If `withAlpha`
/// is set to `true`, the format will include the alpha channel as `#AARRGGBB`.
///
/// - `color`: The `Color` object to convert.
/// - `withAlpha`: A boolean flag indicating whether to include the alpha
///   channel in the output. Defaults to `false`.
///
/// Returns:
/// A string representing the color in hexadecimal format.
String colorToHexString(Color color, {bool withAlpha = false}) {
  final a =
      ((color.a * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final r =
      ((color.r * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final g =
      ((color.g * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');
  final b =
      ((color.b * 255.0).round() & 0xff).toRadixString(16).padLeft(2, '0');

  if (withAlpha) {
    return '#$a$r$g$b';
  }

  return '#$r$g$b';
}
