import 'package:flutter/material.dart';

/// Defines a set of colors used for representing JSON data types and HTTP methods.
class JsonColors {
  JsonColors._();

  /// Color used for `null` values in JSON.
  static const nullColor = Colors.blueGrey;

  /// Color used for `boolean` values in JSON.
  static const boolColor = Colors.orange;

  /// Color used for JSON tree structure elements.
  static const jsonTreeColor = Color(0xFF2D45C3);

  /// Color used for JSON objects.
  static const objectColor = Colors.blue;

  /// Color used for JSON arrays.
  static const arrayColor = Colors.blue;

  /// Color used for numeric values in JSON.
  static const numColor = Colors.deepPurpleAccent;

  /// Color used for string values in JSON.
  static const stringColor = Color(0xFFCD44D9);

  /// Background color of the JSON viewer.
  static const jsonBackgroundColor = Color(0xFFE8E8E8);

  /// Color used for JSON keys.
  static const jsonKeyColor = Color(0xFF2D45C3);

  /// Color used for hidden containers in JSON structure.
  static const hiddenContainerColor = Color(0xFFBB5BC3);

  /// Color used for date-time values in JSON.
  static const dateTimeColor = Colors.teal;

  /// Returns a color based on the provided HTTP `statusCode`.
  ///
  /// - `2xx` (Success) → Green
  /// - `4xx` (Client Errors) → Red
  /// - `5xx` (Server Errors) → Red
  /// - Other / Unknown → Grey
  static Color getStatusColor(int? statusCode) {
    if (statusCode == null) {
      return Colors.grey;
    } else if (statusCode >= 200 && statusCode < 300) {
      return Colors.green;
    } else if (statusCode >= 400 && statusCode < 500) {
      return Colors.red;
    } else if (statusCode >= 500) {
      return Colors.red;
    } else {
      return Colors.grey;
    }
  }

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
