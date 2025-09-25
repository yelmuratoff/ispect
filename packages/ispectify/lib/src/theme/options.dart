import 'package:ispectify/ispectify.dart';

/// Default log type titles for ISpectify logging.
final Map<String, String> _defaultTitles = {
  ISpectifyLogType.critical.key: 'critical',
  ISpectifyLogType.warning.key: 'warning',
  ISpectifyLogType.verbose.key: 'verbose',
  ISpectifyLogType.info.key: 'info',
  ISpectifyLogType.debug.key: 'debug',
  ISpectifyLogType.error.key: 'error',
  ISpectifyLogType.exception.key: 'exception',
  ISpectifyLogType.httpError.key: 'http-error',
  ISpectifyLogType.httpRequest.key: 'http-request',
  ISpectifyLogType.httpResponse.key: 'http-response',
  ISpectifyLogType.blocEvent.key: 'bloc-event',
  ISpectifyLogType.blocTransition.key: 'bloc-transition',
  ISpectifyLogType.blocCreate.key: 'bloc-create',
  ISpectifyLogType.blocClose.key: 'bloc-close',
  ISpectifyLogType.blocState.key: 'bloc-state',
  ISpectifyLogType.riverpodAdd.key: 'riverpod-add',
  ISpectifyLogType.riverpodUpdate.key: 'riverpod-update',
  ISpectifyLogType.riverpodDispose.key: 'riverpod-dispose',
  ISpectifyLogType.riverpodFail.key: 'riverpod-fail',
  ISpectifyLogType.route.key: 'route',
  ISpectifyLogType.good.key: 'good',
  ISpectifyLogType.analytics.key: 'analytics',
  ISpectifyLogType.provider.key: 'provider',
  ISpectifyLogType.print.key: 'print',
  ISpectifyLogType.dbQuery.key: 'db-query',
  ISpectifyLogType.dbResult.key: 'db-result',
  ISpectifyLogType.dbError.key: 'db-error',
};

/// Default ANSI colors for ISpectify log types.
final Map<String, AnsiPen> _defaultColors = {
  ISpectifyLogType.critical.key: AnsiPen()..red(),
  ISpectifyLogType.warning.key: AnsiPen()..xterm(172),
  ISpectifyLogType.verbose.key: AnsiPen()..xterm(08),
  ISpectifyLogType.info.key: AnsiPen()..blue(),
  ISpectifyLogType.debug.key: AnsiPen()..gray(),
  ISpectifyLogType.error.key: AnsiPen()..red(),
  ISpectifyLogType.exception.key: AnsiPen()..red(),
  ISpectifyLogType.httpError.key: AnsiPen()..red(),
  ISpectifyLogType.httpRequest.key: AnsiPen()..xterm(207),
  ISpectifyLogType.httpResponse.key: AnsiPen()..xterm(35),
  ISpectifyLogType.blocEvent.key: AnsiPen()..xterm(51),
  ISpectifyLogType.blocTransition.key: AnsiPen()..xterm(49),
  ISpectifyLogType.blocCreate.key: AnsiPen()..xterm(35),
  ISpectifyLogType.blocClose.key: AnsiPen()..xterm(198),
  ISpectifyLogType.blocState.key: AnsiPen()..xterm(33),
  ISpectifyLogType.riverpodAdd.key: AnsiPen()..xterm(51),
  ISpectifyLogType.riverpodUpdate.key: AnsiPen()..xterm(49),
  ISpectifyLogType.riverpodDispose.key: AnsiPen()..xterm(198),
  ISpectifyLogType.riverpodFail.key: AnsiPen()..red(),
  ISpectifyLogType.route.key: AnsiPen()..xterm(135),
  ISpectifyLogType.good.key: AnsiPen()..green(),
  ISpectifyLogType.analytics.key: AnsiPen()..yellow(),
  ISpectifyLogType.provider.key: AnsiPen()..rgb(r: 0.2, g: 0.8, b: 0.9),
  ISpectifyLogType.print.key: AnsiPen()..blue(),
  ISpectifyLogType.dbQuery.key: AnsiPen()..blue(),
  ISpectifyLogType.dbResult.key: AnsiPen()..green(),
  ISpectifyLogType.dbError.key: AnsiPen()..red(),
};

/// Fallback color for logs without a predefined color.
final AnsiPen _fallbackPen = AnsiPen()..gray();

/// Configuration options for ISpectify logging.
///
/// This class allows customization of logging behavior, including
/// enabling/disabling logs, storing log history, and customizing
/// log colors and titles.
class ISpectifyOptions {
  /// Creates an instance of `ISpectifyOptions` with customizable settings.
  ///
  /// - `enabled`: Whether logging is enabled.
  /// - `useHistory`: Whether to store logs in history.
  /// - `useConsoleLogs`: Whether to print logs to the console.
  /// - `maxHistoryItems`: Maximum number of logs to retain in history.
  /// - `logTruncateLength`: Maximum length for log messages in console.
  /// - `titles`: Custom log titles.
  /// - `colors`: Custom log colors.
  ISpectifyOptions({
    this.enabled = true,
    bool useHistory = true,
    bool useConsoleLogs = true,
    int maxHistoryItems = 10000,
    int logTruncateLength = 10000,
    Map<String, String>? titles,
    Map<String, AnsiPen>? colors,
  })  : _useHistory = useHistory,
        _useConsoleLogs = useConsoleLogs,
        _maxHistoryItems = maxHistoryItems,
        _logTruncateLength = logTruncateLength,
        titles = {..._defaultTitles, if (titles != null) ...titles},
        colors = {..._defaultColors, if (colors != null) ...colors};

  /// Whether log history is enabled.
  bool get useHistory => _useHistory && enabled;
  final bool _useHistory;

  /// Whether console logging is enabled.
  bool get useConsoleLogs => _useConsoleLogs && enabled;
  final bool _useConsoleLogs;

  /// Maximum number of stored log history items.
  int get maxHistoryItems => _maxHistoryItems;
  final int _maxHistoryItems;

  /// Truncate length for log messages in console.
  int get logTruncateLength => _logTruncateLength;
  final int _logTruncateLength;

  /// Whether logging is globally enabled.
  bool enabled;

  /// Map of log type keys to custom titles.
  final Map<String, String> titles;

  /// Map of log type keys to ANSI colors.
  final Map<String, AnsiPen> colors;

  /// Retrieves the title associated with a given log type key.
  ///
  /// Returns the default key if no custom title is defined.
  String titleByKey(String key) => titles[key] ?? key;

  /// Retrieves the ANSI color associated with a given log type key.
  ///
  /// If no specific color is assigned, it returns a fallback color.
  AnsiPen penByKey(String? key, {AnsiPen? fallbackPen}) =>
      colors[key] ?? fallbackPen ?? _fallbackPen;

  /// Creates a new `ISpectifyOptions` instance with modified properties.
  ///
  /// If a parameter is `null`, the existing value is preserved.
  ISpectifyOptions copyWith({
    bool? enabled,
    bool? useHistory,
    bool? useConsoleLogs,
    int? maxHistoryItems,
    int? logTruncateLength,
    Map<String, String>? titles,
    Map<String, AnsiPen>? colors,
  }) =>
      ISpectifyOptions(
        enabled: enabled ?? this.enabled,
        useHistory: useHistory ?? _useHistory,
        useConsoleLogs: useConsoleLogs ?? _useConsoleLogs,
        maxHistoryItems: maxHistoryItems ?? _maxHistoryItems,
        logTruncateLength: logTruncateLength ?? _logTruncateLength,
        titles: titles ?? this.titles,
        colors: colors ?? this.colors,
      );
}
