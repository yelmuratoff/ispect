import 'package:flutter/material.dart';

/// Defines a set of colors used for representing JSON data types and HTTP methods.
///
/// All type colors provide light/dark variants to ensure WCAG AA contrast
/// (≥ 4.5:1) on both light and dark backgrounds. Dark variants use lighter
/// Material shades of the same hue.
class JsonColors {
  JsonColors._();

  /// Color used for `null` values in JSON.
  static const nullColor = Colors.blueGrey;
  static const nullColorDark = Color(0xFFB0BEC5);

  /// Color used for `boolean` values in JSON.
  static const boolColor = Colors.orange;
  static const boolColorDark = Color(0xFFFFCC80);

  /// Color used for JSON tree structure elements.
  static const jsonTreeColor = Color(0xFF2D45C3);
  static const jsonTreeColorDark = Color(0xFF9FA8DA);

  /// Color used for JSON objects.
  static const objectColor = Colors.blue;
  static const objectColorDark = Color(0xFF90CAF9);

  /// Color used for JSON arrays.
  static const arrayColor = Color(0xFF00897B);
  static const arrayColorDark = Color(0xFF80CBC4);

  /// Color used for numeric values in JSON.
  static const numColor = Colors.deepPurpleAccent;
  static const numColorDark = Color(0xFFB39DDB);

  /// Color used for string values in JSON.
  static const stringColor = Color(0xFFCD44D9);
  static const stringColorDark = Color(0xFFF48FB1);

  /// Background color of the JSON viewer.
  static const jsonBackgroundColor = Color(0xFFE8E8E8);

  /// Color used for JSON keys.
  static const jsonKeyColor = Color(0xFF2D45C3);
  static const jsonKeyColorDark = Color(0xFF9FA8DA);

  /// Color used for hidden containers in JSON structure.
  static const hiddenContainerColor = Color(0xFFBB5BC3);

  /// Color used for date-time values in JSON. The dark variant is kept distinct
  /// from [arrayColorDark] so the two type colors stay distinguishable.
  static const dateTimeColor = Colors.teal;
  static const dateTimeColorDark = Color(0xFFA5D6A7);

  /// Returns the appropriate color for [Brightness].
  static Color nullColorFor(Brightness b) =>
      b == Brightness.dark ? nullColorDark : nullColor;
  static Color boolColorFor(Brightness b) =>
      b == Brightness.dark ? boolColorDark : boolColor;
  static Color numColorFor(Brightness b) =>
      b == Brightness.dark ? numColorDark : numColor;
  static Color stringColorFor(Brightness b) =>
      b == Brightness.dark ? stringColorDark : stringColor;
  static Color objectColorFor(Brightness b) =>
      b == Brightness.dark ? objectColorDark : objectColor;
  static Color arrayColorFor(Brightness b) =>
      b == Brightness.dark ? arrayColorDark : arrayColor;
  static Color dateTimeColorFor(Brightness b) =>
      b == Brightness.dark ? dateTimeColorDark : dateTimeColor;

  /// Returns a color based on the provided HTTP `statusCode`.
  ///
  /// - `2xx` (Success) → Green
  /// - `4xx` (Client Errors) → Red
  /// - `5xx` (Server Errors) → Red
  /// - Other / Unknown → Grey
  static Color statusColor(int? statusCode) => switch (statusCode) {
        null => Colors.grey,
        >= 200 && < 300 => Colors.green,
        >= 300 && < 400 => Colors.orange,
        >= 400 && < 500 => Colors.red,
        >= 500 => Colors.red,
        _ => Colors.grey,
      };

  /// HTTP method colors for the light theme.
  ///
  /// Darker Material [800] shades keep method labels readable on the light
  /// badge surface and stay visibly distinct from the saturated status
  /// signals (success green, error red, pending orange), which sit at the
  /// [500] level. Raw [Colors.red]/[Colors.orange]/[Colors.green] would
  /// collide exactly with those signals and read as a failure.
  static const methodColors = {
    'GET': Color(0xFF2E7D32),
    'POST': Color(0xFF1565C0),
    'PUT': Color(0xFFEF6C00),
    'DELETE': Color(0xFFC62828),
    'PATCH': Color(0xFF6A1B9A),
    'HEAD': Color(0xFFAD1457),
    'OPTIONS': Color(0xFF00695C),
    'TRACE': Color(0xFF424242),
    'CONNECT': Color(0xFF4E342E),
  };

  /// HTTP method colors for the dark theme.
  ///
  /// Lighter Material [300] shades read better on dark surfaces and stay
  /// visibly distinct from the saturated status signals (error red,
  /// pending orange).
  static const methodColorsDark = {
    'GET': Color(0xFF81C784),
    'POST': Color(0xFF64B5F6),
    'PUT': Color(0xFFFFB74D),
    'DELETE': Color(0xFFE57373),
    'PATCH': Color(0xFFBA68C8),
    'HEAD': Color(0xFFF06292),
    'OPTIONS': Color(0xFF4DB6AC),
    'TRACE': Color(0xFFBDBDBD),
    'CONNECT': Color(0xFFA1887F),
  };

  /// Returns the color for an HTTP [method] on the given [brightness].
  ///
  /// Returns `null` for unknown methods so callers can supply a fallback.
  static Color? methodColorFor(String method, Brightness brightness) =>
      (brightness == Brightness.dark
          ? methodColorsDark
          : methodColors)[method.toUpperCase()];
}
