import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Reads the color of a pixel at ([x], [y]) from a raw `RGBA8888` [byteData]
/// buffer (as produced by `ui.Image.toByteData(format: ImageByteFormat.rawRgba)`).
///
/// Returns `null` for out-of-range coordinates or truncated buffers — callers
/// must handle this rather than relying on a default colour.
///
/// The buffer layout is asserted in debug mode; in release the bounds checks
/// remain so a malformed buffer cannot read past the end of memory.
Color? getPixelFromByteData(
  ByteData byteData, {
  required int width,
  required int height,
  required int x,
  required int y,
}) {
  assert(width > 0 && height > 0, 'image dimensions must be positive');
  assert(
    byteData.lengthInBytes >= width * height * 4,
    'expected RGBA8888 buffer of at least width*height*4 bytes; '
    'got ${byteData.lengthInBytes} for ${width}x$height',
  );

  if (x < 0 || x >= width || y < 0 || y >= height) {
    return null;
  }

  final index = (y * width + x) * 4;

  if (index < 0 || index + 3 >= byteData.lengthInBytes) {
    return null;
  }

  final r = byteData.getUint8(index);
  final g = byteData.getUint8(index + 1);
  final b = byteData.getUint8(index + 2);
  final a = byteData.getUint8(index + 3);

  return Color.fromARGB(a, r, g, b);
}

/// Returns the [color] in `#RRGGBB` (or `#AARRGGBB` when [withAlpha] is true).
///
/// Pass [withAlpha] explicitly when you always want the alpha channel; the
/// helper [colorToDisplayHex] auto-includes alpha only when the colour is
/// translucent, which is usually what UI wants.
String colorToHexString(Color color, {bool withAlpha = false}) {
  final a = (color.a * 255).round().toRadixString(16).padLeft(2, '0');
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');

  if (withAlpha) {
    return '$a$r$g$b';
  }

  return '$r$g$b';
}

/// Auto-formats a [color] for display:
/// - opaque    → `#RRGGBB`
/// - translucent → `#AARRGGBB`
///
/// This avoids silently dropping alpha when the user picks a semi-transparent
/// pixel (overlays, scrims, shadows).
String colorToDisplayHex(Color color) {
  final isOpaque = (color.a * 255).round() >= 255;
  return '#${colorToHexString(color, withAlpha: !isOpaque)}'.toUpperCase();
}

/// Picks a readable text colour (black or white) for content drawn on top of
/// [background], using a simple luminance threshold.
///
/// For accessibility-grade contrast use [contrastRatio] / [wcagLevel].
Color getTextColorOnBackground(Color background) {
  final luminance = background.computeLuminance();

  if (luminance > 0.5) return Colors.black;
  return Colors.white;
}

/// WCAG 2.1 contrast ratio between [a] and [b]. Range: 1.0 – 21.0.
///
/// AA requires ≥ 4.5:1 for normal text, ≥ 3.0:1 for large text;
/// AAA requires ≥ 7.0:1 for normal text, ≥ 4.5:1 for large text.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// Compact WCAG label for a contrast [ratio] at normal text size:
/// `AAA` (≥ 7), `AA` (≥ 4.5), `AA Large` (≥ 3), otherwise `Fail`.
String wcagLevel(double ratio) {
  if (ratio >= 7.0) return 'AAA';
  if (ratio >= 4.5) return 'AA';
  if (ratio >= 3.0) return 'AA Large';
  return 'Fail';
}
