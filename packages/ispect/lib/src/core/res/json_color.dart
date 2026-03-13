import 'package:flutter/material.dart';

/// Defines a set of colors used for representing JSON data types and HTTP methods.
///
/// All type colors provide light/dark variants to ensure WCAG AA contrast
/// (≥ 4.5:1) on both light and dark backgrounds.
class JsonColors {
  JsonColors._();

  // ---------------------------------------------------------------------------
  // JSON value type colors — light / dark pairs
  // ---------------------------------------------------------------------------

  /// Color used for `null` values in JSON.
  static const nullColor = Colors.blueGrey;
  static const nullColorDark = Color(0xFFB0BEC5); // blueGrey[200] — soft grey

  /// Color used for `boolean` values in JSON.
  static const boolColor = Colors.orange;
  static const boolColorDark = Color(0xFF4FC3F7); // lightBlue[300] — like VS Code

  /// Color used for JSON tree structure elements.
  static const jsonTreeColor = Color(0xFF2D45C3);
  static const jsonTreeColorDark = Color(0xFF9FA8DA); // indigo[200]

  /// Color used for JSON objects.
  static const objectColor = Colors.blue;
  static const objectColorDark = Color(0xFF90CAF9); // blue[200]

  /// Color used for JSON arrays.
  static const arrayColor = Color(0xFF00897B); // teal[600]
  static const arrayColorDark = Color(0xFF80CBC4); // teal[200]

  /// Color used for numeric values in JSON.
  static const numColor = Colors.deepPurpleAccent;
  static const numColorDark = Color(0xFFB5CEA8); // VS Code-style green for nums

  /// Color used for string values in JSON.
  static const stringColor = Color(0xFFCD44D9);
  static const stringColorDark = Color(0xFFCE9178); // VS Code-style warm orange

  /// Background color of the JSON viewer.
  static const jsonBackgroundColor = Color(0xFFE8E8E8);

  /// Color used for JSON keys.
  static const jsonKeyColor = Color(0xFF2D45C3);
  static const jsonKeyColorDark = Color(0xFF9FA8DA); // indigo[200]

  /// Color used for hidden containers in JSON structure.
  static const hiddenContainerColor = Color(0xFFBB5BC3);

  /// Color used for date-time values in JSON.
  static const dateTimeColor = Colors.teal;
  static const dateTimeColorDark = Color(0xFF80CBC4); // teal[200]

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

  /// Maps HTTP methods to their respective colors.
  static const methodColors = {
    'GET': Colors.green,
    'POST': Colors.blue,
    'PUT': Colors.orange,
    'DELETE': Colors.red,
    'PATCH': Colors.purple,
    'HEAD': Colors.pink,
    'OPTIONS': Colors.teal,
    'TRACE': Colors.grey,
    'CONNECT': Colors.brown,
  };
}
