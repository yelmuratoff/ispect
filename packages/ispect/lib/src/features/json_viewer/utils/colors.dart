// ignore_for_file: deprecated_member_use, avoid_dynamic_calls

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/core/res/json_color.dart';

/// Utility class containing color and styling helper methods for JSON tree viewing
class JsonColorsUtils {
  /// Returns a default color based on the value type, adapted for [brightness].
  static Color valueColor(
    Object? value,
    Color defaultColor,
    Brightness brightness,
  ) =>
      switch (value) {
        null => JsonColors.nullColorFor(brightness),
        int() || double() || num() => JsonColors.numColorFor(brightness),
        bool() => JsonColors.boolColorFor(brightness),
        String() => JsonColors.stringColorFor(brightness),
        Iterable() || List() => JsonColors.arrayColorFor(brightness),
        Map() => JsonColors.objectColorFor(brightness),
        _ => defaultColor,
      };

  /// Resolves the display color of the value based on the `keyName`.
  static Color valueColorByKey(
    BuildContext context,
    String keyName,
    Object? value,
  ) {
    final theme = ISpect.read(context).theme;
    final appTheme = Theme.of(context);
    final brightness = appTheme.brightness;
    final defaultSecondary = appTheme.colorScheme.secondary;
    final result = switch (keyName) {
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
        JsonColors.stringColorFor(brightness),
      'status_code' => JsonColors.statusColor(
        value is int ? value : int.tryParse(value.toString()),
      ),
      'exception' => theme.getTypeColor(context, key: 'exception'),
      'error' => theme.getTypeColor(context, key: 'error'),
      'stack-trace' => theme.getTypeColor(context, key: 'error'),
      'log-level' => theme.getColorByLogLevel(context, key: value.toString()),
      'time' || 'date' => JsonColors.dateTimeColorFor(brightness),
      _ => valueColor(value, defaultSecondary, brightness),
    };
    return result ?? valueColor(value, defaultSecondary, brightness);
  }
}
