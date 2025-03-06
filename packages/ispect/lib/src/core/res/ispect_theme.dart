import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/icons.dart';
import 'package:ispect/src/features/ispect/models/log_description.dart';

class ISpectTheme {
  const ISpectTheme({
    this.lightBackgroundColor,
    this.darkBackgroundColor,
    this.lightDividerColor,
    this.darkDividerColor,
    this.logColors = const {},
    this.logIcons = const {},
    this.logDescriptions = const [],
  });

  final Color? lightBackgroundColor;
  final Color? darkBackgroundColor;
  final Color? lightDividerColor;
  final Color? darkDividerColor;

  final Map<String, Color> logColors;
  final Map<String, IconData> logIcons;
  final List<LogDescription> logDescriptions;

  ISpectTheme copyWith({
    Color? lightBackgroundColor,
    Color? darkBackgroundColor,
    Color? lightDividerColor,
    Color? darkDividerColor,
    Map<String, Color>? logColors,
    Map<String, IconData>? logIcons,
    List<LogDescription>? logDescriptions,
  }) =>
      ISpectTheme(
        lightBackgroundColor: lightBackgroundColor ?? this.lightBackgroundColor,
        darkBackgroundColor: darkBackgroundColor ?? this.darkBackgroundColor,
        lightDividerColor: lightDividerColor ?? this.lightDividerColor,
        darkDividerColor: darkDividerColor ?? this.darkDividerColor,
        logColors: logColors ?? this.logColors,
        logIcons: logIcons ?? this.logIcons,
        logDescriptions: logDescriptions ?? this.logDescriptions,
      );

  Color? backgroundColor(BuildContext context) =>
      context.isDarkMode ? darkBackgroundColor : lightBackgroundColor;

  Color? dividerColor(BuildContext context) =>
      context.isDarkMode ? darkDividerColor : lightDividerColor;

  Color getTypeColor(BuildContext context, {required String? key}) {
    if (key == null) return Colors.transparent;
    return colors(context)[key] ?? Colors.grey;
  }

  Color getColorByLogLevel(BuildContext context, {required String? key}) {
    if (key == null) return Colors.transparent;
    return colors(context)[key.replaceAll('LogLevel.', '')] ?? Colors.grey;
  }

  Map<String, Color> colors(BuildContext context) => {
        ...logColors,
        ...context.isDarkMode ? darkTypeColors : lightTypeColors,
      };

  Map<String, IconData> icons(BuildContext context) => {
        ...logIcons,
        ...typeIcons,
      };

  /// Now returns only enabled descriptions.
  List<LogDescription> descriptions(BuildContext context) {
    final defaultDescriptions = defaultLogDescriptions(context);
    return [
      ...defaultDescriptions,
      ...logDescriptions.where((desc) => !desc.isDisabled),
    ];
  }

  /// Converts default log descriptions into a list of `LogDescription`.
  List<LogDescription> defaultLogDescriptions(BuildContext context) {
    final l10n = context.ispectL10n;
    return [
      LogDescription(key: 'error', description: l10n.errorLogDesc),
      LogDescription(key: 'critical', description: l10n.criticalLogDesc),
      LogDescription(key: 'info', description: l10n.infoLogDesc),
      LogDescription(key: 'debug', description: l10n.debugLogDesc),
      LogDescription(key: 'verbose', description: l10n.verboseLogDesc),
      LogDescription(key: 'warning', description: l10n.warningLogDesc),
      LogDescription(key: 'exception', description: l10n.exceptionLogDesc),
      LogDescription(key: 'good', description: l10n.goodLogDesc),
      LogDescription(key: 'print', description: l10n.printLogDesc),
      LogDescription(key: 'analytics', description: l10n.analyticsLogDesc),
      LogDescription(key: 'http-error', description: l10n.httpErrorLogDesc),
      LogDescription(key: 'http-request', description: l10n.httpRequestLogDesc),
      LogDescription(
        key: 'http-response',
        description: l10n.httpResponseLogDesc,
      ),
      LogDescription(key: 'bloc-event', description: l10n.blocEventLogDesc),
      LogDescription(
        key: 'bloc-transition',
        description: l10n.blocTransitionLogDesc,
      ),
      LogDescription(key: 'bloc-close', description: l10n.blocCloseLogDesc),
      LogDescription(key: 'bloc-create', description: l10n.blocCreateLogDesc),
      LogDescription(key: 'bloc-state', description: l10n.blocStateLogDesc),
      LogDescription(key: 'riverpod-add', description: l10n.riverpodAddLogDesc),
      LogDescription(
        key: 'riverpod-update',
        description: l10n.riverpodUpdateLogDesc,
      ),
      LogDescription(
        key: 'riverpod-dispose',
        description: l10n.riverpodDisposeLogDesc,
      ),
      LogDescription(
        key: 'riverpod-fail',
        description: l10n.riverpodFailLogDesc,
      ),
      LogDescription(key: 'route', description: l10n.routeLogDesc),
    ];
  }
}
