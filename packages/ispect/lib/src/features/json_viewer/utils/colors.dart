// ignore_for_file: deprecated_member_use, avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/core/res/json_color.dart';

/// Utility class containing color and styling helper methods for JSON tree viewing
class JsonColorsUtils {
  /// Returns a default color based on the `JsonNodeType`.
  static Color valueColor(Object? value, Color defaultColor) {
    if (value == null) {
      return JsonColors.nullColor;
    }
    if (value is int || value is double || value is num) {
      return JsonColors.numColor;
    }
    if (value is bool) {
      return JsonColors.boolColor;
    }
    if (value is String) {
      return JsonColors.stringColor;
    }
    if (value is Iterable || value is List) {
      return JsonColors.arrayColor;
    }
    if (value is Map) {
      return JsonColors.objectColor;
    }
    return defaultColor;
  }

  /// Resolves the display color of the value based on the `keyName`.
  static Color? valueColorByKey(
    BuildContext context,
    String keyName,
    Object? value,
  ) {
    final theme = ISpect.read(context).theme;
    return switch (keyName) {
      'key' => theme.getTypeColor(context, key: value.toString()),
      'title' => theme.getTypeColor(context, key: value.toString()),
      'method' => JsonColors.methodColors[value.toString()],
      'base-url' ||
      'url' ||
      'uri' ||
      'real-uri' ||
      'location' ||
      'path' ||
      'Authorization' =>
        JsonColors.stringColor,
      'status_code' => JsonColors.statusColor(value as int?),
      'exception' => theme.getTypeColor(context, key: 'exception'),
      'error' => theme.getTypeColor(context, key: 'error'),
      'stack-trace' => theme.getTypeColor(context, key: 'error'),
      'log-level' => theme.getColorByLogLevel(context, key: value.toString()),
      'time' || 'date' => JsonColors.dateTimeColor,
      _ => valueColor(
          value,
          Theme.of(context).colorScheme.secondary,
        ),
    };
  }
}
