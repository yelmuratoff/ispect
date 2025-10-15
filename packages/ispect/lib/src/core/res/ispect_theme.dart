import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/ispect/domain/models/log_description.dart';

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
class ISpectTheme {
  /// Creates an `ISpectTheme` instance with customizable settings.
  ///
  /// - `pageTitle`: The title displayed on the inspector page.
  /// - `lightBackgroundColor`: Background color in light mode.
  /// - `darkBackgroundColor`: Background color in dark mode.
  /// - `lightDividerColor`: Divider color in light mode.
  /// - `darkDividerColor`: Divider color in dark mode.
  /// - `logColors`: Custom colors mapped to log types.
  /// - `logIcons`: Custom icons mapped to log types.
  /// - `logDescriptions`: List of descriptions for various log types.
  const ISpectTheme({
    this.pageTitle = 'ISpect',
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightDividerColor,
    this.darkDividerColor,
    this.logColors = const {},
    this.logIcons = const {},
    this.logDescriptions = const [],
  });

  /// The title displayed on the inspector page.
  final String? pageTitle;

  /// Background color used in light mode.
  final Color? lightBackgroundColor;

  /// Background color used in dark mode.
  final Color? darkBackgroundColor;

  /// Divider color used in light mode.
  final Color? lightDividerColor;

  /// Divider color used in dark mode.
  final Color? darkDividerColor;

  /// A map of colors associated with different log types.
  final Map<String, Color> logColors;

  /// A map of icons associated with different log types.
  final Map<String, IconData> logIcons;

  /// A list of descriptions for log types.
  final List<LogDescription> logDescriptions;

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
    Color? lightBackgroundColor,
    Color? darkBackgroundColor,
    Color? lightDividerColor,
    Color? darkDividerColor,
    Map<String, Color>? logColors,
    Map<String, IconData>? logIcons,
    List<LogDescription>? logDescriptions,
    String? pageTitle,
  }) =>
      ISpectTheme(
        pageTitle: pageTitle ?? this.pageTitle,
        lightBackgroundColor: lightBackgroundColor ?? this.lightBackgroundColor,
        darkBackgroundColor: darkBackgroundColor ?? this.darkBackgroundColor,
        lightDividerColor: lightDividerColor ?? this.lightDividerColor,
        darkDividerColor: darkDividerColor ?? this.darkDividerColor,
        logColors: logColors ?? this.logColors,
        logIcons: logIcons ?? this.logIcons,
        logDescriptions: logDescriptions ?? this.logDescriptions,
      );

  /// Returns the appropriate background color based on the current theme mode.
  ///
  /// - Uses `darkBackgroundColor` in dark mode.
  /// - Uses `lightBackgroundColor` in light mode.
  Color? backgroundColor(BuildContext context) =>
      context.isDarkMode ? darkBackgroundColor : lightBackgroundColor;

  /// Returns the appropriate divider color based on the current theme mode.
  ///
  /// - Uses `darkDividerColor` in dark mode.
  /// - Uses `lightDividerColor` in light mode.
  Color? dividerColor(BuildContext context) =>
      context.isDarkMode ? darkDividerColor : lightDividerColor;

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
  Map<String, Color> colors(BuildContext context) => {
        ...logColors,
        ...context.isDarkMode
            ? ISpectConstants.darkTypeColors
            : ISpectConstants.lightTypeColors,
      };

  /// Returns a combined map of default and custom log icons.
  ///
  /// - Merges `logIcons` with default icons from `ISpectConstants`.
  Map<String, IconData> icons(BuildContext context) => {
        ...logIcons,
        ...ISpectConstants.typeIcons,
      };

  IconData getTypeIcon(BuildContext context, {required String? key}) {
    if (key == null) return Icons.bug_report_outlined;
    final iconData = icons(context)[key];
    return iconData ?? Icons.bug_report_outlined;
  }

  /// Returns a filtered list of enabled log descriptions.
  ///
  /// - Merges default descriptions from `ISpectConstants`.
  /// - Filters out descriptions marked as disabled.
  List<LogDescription> descriptions(BuildContext context) {
    final descMap = <String, LogDescription>{};

    // Add default descriptions
    for (final desc in ISpectConstants.defaultLogDescriptions(context)) {
      descMap[desc.key] = desc;
    }

    // Overwrite with custom descriptions
    for (final desc in logDescriptions) {
      descMap[desc.key] = desc;
    }

    // Return only enabled descriptions
    return descMap.values.where((desc) => !desc.isDisabled).toList();
  }
}
