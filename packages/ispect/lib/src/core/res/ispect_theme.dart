import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

@immutable
class ISpectDynamicColor {
  const ISpectDynamicColor({
    this.dark,
    this.light,
  });

  factory ISpectDynamicColor.fromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');
    return ISpectDynamicColor(
      dark: map['dark'] != null ? Color(cast<int>('dark')) : null,
      light: map['light'] != null ? Color(cast<int>('light')) : null,
    );
  }

  factory ISpectDynamicColor.fromJson(String source) {
    final decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'Expected Map<String, dynamic>, got ${decoded.runtimeType}',
      );
    }
    return ISpectDynamicColor.fromMap(decoded);
  }

  final Color? dark;
  final Color? light;

  Color? resolve(BuildContext context) => context.isDarkMode ? dark : light;

  ISpectDynamicColor copyWith({
    Color? dark,
    Color? light,
  }) =>
      ISpectDynamicColor(
        dark: dark ?? this.dark,
        light: light ?? this.light,
      );

  Map<String, dynamic> toMap() => {
        'dark': dark?.toARGB32(),
        'light': light?.toARGB32(),
      };

  String toJson() => json.encode(toMap());

  @override
  String toString() => '''ISpectDynamicColor(
      dark: $dark,
      light: $light,
      )''';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ISpectDynamicColor &&
        other.dark == dark &&
        other.light == light;
  }

  @override
  int get hashCode => Object.hash(dark, light);
}

/// Defines the theme configuration for `ISpect`, including colors, icons, and log descriptions.
///
/// This class allows customization of appearance settings such as:
/// - Background and divider colors for light and dark modes.
/// - Log-specific colors and icons.
/// - Custom descriptions for log levels.
///
/// ### Example Usage:
/// ```dart
/// final theme = ISpectTheme(
///   pageTitle: 'Custom Inspector',
///   lightBackgroundColor: Colors.white,
///   darkBackgroundColor: Colors.black,
///   logColors: {'error': Colors.red, 'info': Colors.blue},
///   logIcons: {'error': Icons.error, 'info': Icons.info},
///   logDescriptions: `LogDescription(name: 'Error', description: 'An error occurred')`,
/// );
/// ```
@immutable
class ISpectTheme {
  /// Creates an `ISpectTheme` instance with customizable settings.
  ///
  const ISpectTheme({
    this.pageTitle = 'ISpect',
    this.background,
    this.foreground,
    this.divider,
    this.primary,
    this.card,
    this.logColors = const {},
    this.logIcons = const {},
    this.logDescriptions = const {},
    this.categoryLabels = const {},
    this.logCategories = const {},
    this.customLogTypes = const [],
    this.panelTheme,
  });

  factory ISpectTheme.fromJson(String source) {
    final decoded = json.decode(source);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'Expected Map<String, dynamic>, got ${decoded.runtimeType}',
      );
    }
    return ISpectTheme.fromMap(decoded);
  }

  factory ISpectTheme.fromMap(Map<String, dynamic> map) {
    T cast<T>(String k) => map[k] is T
        ? map[k] as T
        : throw ArgumentError.value(map[k], k, '$T ← ${map[k].runtimeType}');
    return ISpectTheme(
      pageTitle: cast<String?>('page_title'),
      background: map['background'] != null
          ? ISpectDynamicColor.fromMap(
              Map.from(cast<Map<String, dynamic>>('background')),
            )
          : null,
      foreground: map['foreground'] != null
          ? ISpectDynamicColor.fromMap(
              Map.from(cast<Map<String, dynamic>>('foreground')),
            )
          : null,
      divider: map['divider'] != null
          ? ISpectDynamicColor.fromMap(
              Map.from(cast<Map<String, dynamic>>('divider')),
            )
          : null,
      primary: map['primary'] != null
          ? ISpectDynamicColor.fromMap(
              Map.from(cast<Map<String, dynamic>>('primary')),
            )
          : null,
      card: map['card'] != null
          ? ISpectDynamicColor.fromMap(
              Map.from(cast<Map<String, dynamic>>('card')),
            )
          : null,
      logColors: cast<Map<String, dynamic>?>('log_colors')
              ?.map((k, v) => MapEntry(k, Color((v as num?)?.toInt() ?? 0))) ??
          const <String, Color>{},
      logIcons: cast<Map<String, dynamic>?>('log_icons')?.map(
            (k, v) => MapEntry(k, IconData((v as num?)?.toInt() ?? 0)),
          ) ??
          const <String, IconData>{},
      logDescriptions: cast<Map<String, dynamic>?>('log_descriptions')
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const <String, String>{},
      categoryLabels: cast<Map<String, dynamic>?>('category_labels')
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const <String, String>{},
      logCategories: cast<Map<String, dynamic>?>('log_categories')
              ?.map((k, v) => MapEntry(k, v.toString())) ??
          const <String, String>{},
    );
  }

  /// The title displayed on the inspector page.
  final String? pageTitle;

  /// Background color
  final ISpectDynamicColor? background;

  /// Foreground color
  final ISpectDynamicColor? foreground;

  /// Divider color
  final ISpectDynamicColor? divider;

  /// Primary color
  final ISpectDynamicColor? primary;

  /// Card color
  final ISpectDynamicColor? card;

  /// A map of colors associated with different log types.
  final Map<String, Color> logColors;

  /// A map of icons associated with different log types.
  final Map<String, IconData> logIcons;

  /// A map of descriptions associated with different log types.
  final Map<String, String> logDescriptions;

  /// Custom labels for trace categories (e.g. `{'network': 'HTTP'}` overrides
  /// the default "HTTP" label in filter grouping).
  final Map<String, String> categoryLabels;

  /// Maps custom log keys to category IDs (e.g. `{'my-log': 'network'}`).
  /// Used by dynamic filter grouping to resolve category for custom log types.
  final Map<String, String> logCategories;

  /// Custom log types shown in the filter UI alongside built-in types.
  ///
  /// Define types with [ISpectLogType] and register colors/icons/descriptions
  /// via [logColors], [logIcons], [logDescriptions]. Category labels go in
  /// [categoryLabels].
  ///
  /// ```dart
  /// ISpectTheme(
  ///   customLogTypes: [
  ///     ISpectLogType('firebase-read', category: 'firebase', title: 'Firebase Read'),
  ///   ],
  ///   logColors: {'firebase-read': Colors.amber},
  ///   categoryLabels: {'firebase': 'Firebase'},
  /// )
  /// ```
  final List<ISpectLogType> customLogTypes;

  /// Theme settings for draggable panels within ISpect.
  final DraggablePanelTheme? panelTheme;

  /// Creates a new `ISpectTheme` instance with updated values while retaining
  /// existing ones where not specified.
  ///
  /// - `pageTitle`: Updates the title.
  /// - `lightBackgroundColor`: Updates the background color for light mode.
  /// - `darkBackgroundColor`: Updates the background color for dark mode.
  /// - `lightDividerColor`: Updates the divider color for light mode.
  /// - `darkDividerColor`: Updates the divider color for dark mode.
  /// - `logColors`: Updates the map of log colors.
  /// - `logIcons`: Updates the map of log icons.
  /// - `logDescriptions`: Updates the list of log descriptions.
  ///
  /// ### Example:
  /// ```dart
  /// final updatedTheme = theme.copyWith(pageTitle: 'New Inspector');
  /// ```
  ISpectTheme copyWith({
    String? pageTitle,
    ISpectDynamicColor? background,
    ISpectDynamicColor? foreground,
    ISpectDynamicColor? divider,
    ISpectDynamicColor? primary,
    ISpectDynamicColor? card,
    Map<String, Color>? logColors,
    Map<String, IconData>? logIcons,
    Map<String, String>? logDescriptions,
    Map<String, String>? categoryLabels,
    Map<String, String>? logCategories,
    List<ISpectLogType>? customLogTypes,
    DraggablePanelTheme? panelTheme,
  }) =>
      ISpectTheme(
        pageTitle: pageTitle ?? this.pageTitle,
        background: background ?? this.background,
        foreground: foreground ?? this.foreground,
        divider: divider ?? this.divider,
        primary: primary ?? this.primary,
        card: card ?? this.card,
        logColors: logColors ?? this.logColors,
        logIcons: logIcons ?? this.logIcons,
        logDescriptions: logDescriptions ?? this.logDescriptions,
        categoryLabels: categoryLabels ?? this.categoryLabels,
        logCategories: logCategories ?? this.logCategories,
        customLogTypes: customLogTypes ?? this.customLogTypes,
        panelTheme: panelTheme ?? this.panelTheme,
      );

  /// Retrieves the color associated with a specific log type.
  ///
  /// - `key`: The log type identifier.
  /// - Returns the mapped color if found; otherwise, defaults to `Colors.grey`.
  Color? getTypeColor(BuildContext context, {required String? key}) {
    if (key == null) return Colors.grey;
    return colors(context)[key];
  }

  /// Retrieves the color associated with a log level.
  ///
  /// - `key`: The log level identifier.
  /// - Strips the `'LogLevel.'` prefix before looking up the color.
  /// - Returns the mapped color if found; otherwise, defaults to `Colors.grey`.
  Color getColorByLogLevel(BuildContext context, {required String? key}) {
    if (key == null) return Colors.transparent;
    return colors(context)[key.replaceAll('LogLevel.', '')] ?? Colors.grey;
  }

  /// Returns a combined map of default and custom log colors based on theme mode.
  ///
  /// - Merges `logColors` with default colors from `ISpectConstants`.
  /// - Uses dark mode colors if enabled.
  Map<String, Color> colors(BuildContext context) =>
      context.isDarkMode ? _getDarkColors(this) : _getLightColors(this);

  /// Returns a combined map of default and custom log icons.
  ///
  /// - Merges `logIcons` with default icons from `ISpectConstants`.
  Map<String, IconData> icons(BuildContext context) => {
        ...ISpectConstants.typeIcons,
        ...logIcons,
      };

  IconData getTypeIcon(BuildContext context, {required String? key}) {
    if (key == null) return Icons.bug_report_outlined;
    final iconData = icons(context)[key];
    return iconData ?? Icons.bug_report_outlined;
  }

  /// Returns a combined map of default and custom log descriptions.
  ///
  /// - Merges default descriptions from `ISpectConstants` with `logDescriptions`.
  Map<String, String> descriptions(BuildContext context) {
    final defaultDescriptions = {
      for (final desc in ISpectConstants.defaultLogDescriptions(context))
        if (desc.description != null) desc.key: desc.description!,
    };
    return {
      ...defaultDescriptions,
      ...logDescriptions,
    };
  }

  String? getTypeDescription(BuildContext context, {required String? key}) {
    if (key == null) return null;
    return descriptions(context)[key];
  }

  Map<String, dynamic> toMap() => {
        'page_title': pageTitle,
        'background': background?.toMap(),
        'foreground': foreground?.toMap(),
        'divider': divider?.toMap(),
        'primary': primary?.toMap(),
        'card': card?.toMap(),
        'log_colors': logColors,
        'log_icons': logIcons,
        'log_descriptions': logDescriptions,
        'category_labels': categoryLabels,
        'log_categories': logCategories,
        'custom_log_type_keys': customLogTypes.map((t) => t.key).toList(),
      };

  String toJson() => json.encode(toMap());

  @override
  String toString() => '''ISpectTheme(
      pageTitle: $pageTitle,
      background: $background,
      foreground: $foreground,
      divider: $divider,
      primary: $primary,
      card: $card,
      logColors: $logColors,
      logIcons: $logIcons,
      logDescriptions: $logDescriptions,
      categoryLabels: $categoryLabels,
      logCategories: $logCategories,
      customLogTypes: ${customLogTypes.map((t) => t.key).toList()},
      panelTheme: $panelTheme,
      )''';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final mapEquals = const DeepCollectionEquality().equals;

    final listEquals = const ListEquality<ISpectLogType>().equals;
    return other is ISpectTheme &&
        other.pageTitle == pageTitle &&
        other.background == background &&
        other.foreground == foreground &&
        other.divider == divider &&
        other.primary == primary &&
        other.card == card &&
        mapEquals(other.logColors, logColors) &&
        mapEquals(other.logIcons, logIcons) &&
        mapEquals(other.logDescriptions, logDescriptions) &&
        mapEquals(other.categoryLabels, categoryLabels) &&
        mapEquals(other.logCategories, logCategories) &&
        listEquals(other.customLogTypes, customLogTypes) &&
        other.panelTheme == panelTheme;
  }

  @override
  int get hashCode {
    const equality = DeepCollectionEquality();
    return Object.hash(
      pageTitle,
      background,
      foreground,
      divider,
      primary,
      card,
      equality.hash(logColors),
      equality.hash(logIcons),
      equality.hash(logDescriptions),
      equality.hash(categoryLabels),
      equality.hash(logCategories),
      const ListEquality<ISpectLogType>().hash(customLogTypes),
      panelTheme,
    );
  }
}

// Per-instance caches stored externally to keep ISpectTheme const-constructible
final Expando<Map<String, Color>> _lightColorsExpando =
    Expando<Map<String, Color>>('ISpectTheme.lightColors');
final Expando<Map<String, Color>> _darkColorsExpando =
    Expando<Map<String, Color>>('ISpectTheme.darkColors');

Map<String, Color> _getLightColors(ISpectTheme theme) {
  final cached = _lightColorsExpando[theme];
  if (cached != null) return cached;
  final merged = {
    ...ISpectConstants.lightTypeColors,
    ...theme.logColors,
  };
  _lightColorsExpando[theme] = merged;
  return merged;
}

Map<String, Color> _getDarkColors(ISpectTheme theme) {
  final cached = _darkColorsExpando[theme];
  if (cached != null) return cached;
  final merged = {
    ...ISpectConstants.darkTypeColors,
    ...theme.logColors,
  };
  _darkColorsExpando[theme] = merged;
  return merged;
}
