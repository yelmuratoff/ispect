import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/icons.dart';

class ISpectTheme {
  const ISpectTheme({
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightDividerColor,
    this.darkDividerColor,
    this.logColors = const {},
    this.logIcons = const {},
    this.logDescriptions = const {},
    this.disabledLogDescriptions = const {},
  });

  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;
  final Color? lightDividerColor;
  final Color? darkDividerColor;

  final Map<String, Color> logColors;
  final Map<String, IconData> logIcons;
  final Map<String, String> logDescriptions;
  final Set<String> disabledLogDescriptions;

  ISpectTheme copyWith({
    Color? lightBackgroundColor,
    Color? darkBackgroundColor,
    Color? lightDividerColor,
    Color? darkDividerColor,
    Map<String, Color>? logColors,
    Map<String, IconData>? logIcons,
    Map<String, String>? logDescriptions,
    Set<String>? disabledLogDescriptions,
  }) =>
      ISpectTheme(
        lightBackgroundColor: lightBackgroundColor ?? this.lightBackgroundColor,
        darkBackgroundColor: darkBackgroundColor ?? this.darkBackgroundColor,
        lightDividerColor: lightDividerColor ?? this.lightDividerColor,
        darkDividerColor: darkDividerColor ?? this.darkDividerColor,
        logColors: logColors ?? this.logColors,
        logIcons: logIcons ?? this.logIcons,
        logDescriptions: logDescriptions ?? this.logDescriptions,
        disabledLogDescriptions:
            disabledLogDescriptions ?? this.disabledLogDescriptions,
      );

  Color? backgroundColor(BuildContext context) =>
      context.isDarkMode ? darkBackgroundColor : lightBackgroundColor;

  Color? dividerColor(BuildContext context) =>
      context.isDarkMode ? darkDividerColor : lightDividerColor;

  Color getTypeColor(BuildContext context, {required String? key}) {
    if (key == null) return Colors.transparent;
    return colors(context)[key] ?? Colors.grey;
  }

  Map<String, Color> colors(BuildContext context) {
    final mergedColors = {
      ...logColors,
      ...context.isDarkMode ? darkTypeColors : lightTypeColors,
    };
    return mergedColors;
  }

  Map<String, IconData> icons(BuildContext context) {
    final mergedIcons = {
      ...logIcons,
      ...typeIcons,
    };

    return mergedIcons;
  }

  Map<String, String> descriptions(BuildContext context) {
    final mergedDescriptions = {
      ...defaultLogDescriptions(context),
      ...logDescriptions,
    };

    return Map.fromEntries(
      mergedDescriptions.entries
          .where((entry) => !disabledLogDescriptions.contains(entry.key)),
    );
  }

  static const lightTypeColors = {
    /// Base logs section
    'error': Color.fromARGB(255, 192, 38, 38),
    'critical': Color.fromARGB(255, 142, 22, 22),
    'info': Color.fromARGB(255, 25, 118, 210),
    'debug': Color.fromARGB(255, 97, 97, 97),
    'verbose': Color.fromARGB(255, 117, 117, 117),
    'warning': Color.fromARGB(255, 255, 160, 0),
    'exception': Color.fromARGB(255, 211, 47, 47),
    'good': Color.fromARGB(255, 56, 142, 60),
    'print': Color.fromARGB(255, 25, 118, 210),
    'analytics': Color.fromARGB(255, 182, 177, 25),

    /// Http section
    'http-error': Color.fromARGB(255, 192, 38, 38),
    'http-request': Color.fromARGB(255, 162, 0, 190),
    'http-response': Color.fromARGB(255, 0, 158, 66),

    /// Bloc section
    'bloc-event': Color.fromARGB(255, 25, 118, 210),
    'bloc-transition': Color.fromARGB(255, 85, 139, 47),
    'bloc-close': Color.fromARGB(255, 192, 38, 38),
    'bloc-create': Color.fromARGB(255, 56, 142, 60),
    'bloc-state': Color.fromARGB(255, 0, 105, 135),

    'riverpod-add': Color.fromARGB(255, 56, 142, 60),
    'riverpod-update': Color.fromARGB(255, 0, 105, 135),
    'riverpod-dispose': Color(0xFFD50000),
    'riverpod-fail': Color.fromARGB(255, 192, 38, 38),

    /// Flutter section
    'route': Color(0xFF8E24AA),
  };

  static const darkTypeColors = {
    /// Base logs section
    'error': Color.fromARGB(255, 239, 83, 80),
    'critical': Color.fromARGB(255, 198, 40, 40),
    'info': Color.fromARGB(255, 66, 165, 245),
    'debug': Color.fromARGB(255, 158, 158, 158),
    'verbose': Color.fromARGB(255, 189, 189, 189),
    'warning': Color.fromARGB(255, 239, 108, 0),
    'exception': Color.fromARGB(255, 239, 83, 80),
    'good': Color.fromARGB(255, 120, 230, 129),
    'print': Color.fromARGB(255, 66, 165, 245),
    'analytics': Color.fromARGB(255, 255, 255, 0),

    /// Http section
    'http-error': Color.fromARGB(255, 239, 83, 80),
    'http-request': Color(0xFFF602C1),
    'http-response': Color(0xFF26FF3C),

    /// Bloc section
    'bloc-event': Color(0xFF63FAFE),
    'bloc-transition': Color(0xFF56FEA8),
    'bloc-close': Color(0xFFFF005F),
    'bloc-create': Color.fromARGB(255, 120, 230, 129),
    'bloc-state': Color.fromARGB(255, 0, 125, 160),

    'riverpod-add': Color.fromARGB(255, 120, 230, 129),
    'riverpod-update': Color.fromARGB(255, 120, 180, 190),
    'riverpod-dispose': Color(0xFFFF005F),
    'riverpod-fail': Color.fromARGB(255, 239, 83, 80),

    /// Flutter section
    'route': Color(0xFFAF5FFF),
  };

  Map<String, String> defaultLogDescriptions(BuildContext context) {
    final l10n = context.ispectL10n;
    return {
      'error': l10n.errorLogDesc,
      'critical': l10n.criticalLogDesc,
      'info': l10n.infoLogDesc,
      'debug': l10n.debugLogDesc,
      'verbose': l10n.verboseLogDesc,
      'warning': l10n.warningLogDesc,
      'exception': l10n.exceptionLogDesc,
      'good': l10n.goodLogDesc,
      'print': l10n.printLogDesc,
      'analytics': l10n.analyticsLogDesc,
      'http-error': l10n.httpErrorLogDesc,
      'http-request': l10n.httpRequestLogDesc,
      'http-response': l10n.httpResponseLogDesc,
      'bloc-event': l10n.blocEventLogDesc,
      'bloc-transition': l10n.blocTransitionLogDesc,
      'bloc-close': l10n.blocCloseLogDesc,
      'bloc-create': l10n.blocCreateLogDesc,
      'bloc-state': l10n.blocStateLogDesc,
      'riverpod-add': l10n.riverpodAddLogDesc,
      'riverpod-update': l10n.riverpodUpdateLogDesc,
      'riverpod-dispose': l10n.riverpodDisposeLogDesc,
      'riverpod-fail': l10n.riverpodFailLogDesc,
      'route': l10n.routeLogDesc,
    };
  }
}
