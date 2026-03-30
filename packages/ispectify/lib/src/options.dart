import 'package:ispectify/ispectify.dart';

/// Configuration options for ISpectLogger logging.
///
/// This class allows customization of logging behavior, including
/// enabling/disabling logs, storing log history, and customizing
/// log colors and titles.
///
/// Color customization now uses the [ISpectLogTypeRegistry]
/// for better extensibility. Custom overrides can be provided via
/// the [customColors] parameter.
class ISpectLoggerOptions {
  /// Creates an instance of `ISpectLoggerOptions` with customizable settings.
  ///
  /// - `enabled`: Whether logging is enabled.
  /// - `useHistory`: Whether to store logs in history.
  /// - `useConsoleLogs`: Whether to print logs to the console.
  /// - `maxHistoryItems`: Maximum number of logs to retain in history.
  /// - `logTruncateLength`: Maximum length for log messages in console.
  /// - `customColors`: Custom log colors that override registry defaults.
  ISpectLoggerOptions({
    this.enabled = true,
    bool useHistory = true,
    bool useConsoleLogs = true,
    int maxHistoryItems = 10000,
    int logTruncateLength = kDefaultStringTruncateLimit,
    Map<String, AnsiPen>? customColors,
  })  : assert(maxHistoryItems >= 0, 'maxHistoryItems must be non-negative'),
        assert(
          logTruncateLength >= 0,
          'logTruncateLength must be non-negative',
        ),
        _useHistory = useHistory,
        _useConsoleLogs = useConsoleLogs,
        _maxHistoryItems = maxHistoryItems,
        _logTruncateLength = logTruncateLength,
        _customColors =
            customColors != null ? Map.unmodifiable(customColors) : null;

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
  final bool enabled;

  /// Custom color overrides (immutable after creation).
  final Map<String, AnsiPen>? _customColors;

  /// Retrieves the ANSI color associated with a given log type key.
  ///
  /// First checks custom overrides, then built-in defaults from ISpectLogType,
  /// then provided fallback, finally falls back to default gray.
  AnsiPen penByKey(String? key, {AnsiPen? fallbackPen}) {
    if (key == null) return fallbackPen ?? ConsoleUtils.fallbackPen;

    // 1. Check custom override
    final customPen = _customColors?[key];
    if (customPen != null) return customPen;

    // 2. Check built-in defaults
    final defaultPen = ISpectLogType.fromKey(key)?.defaultPen;
    if (defaultPen != null) return defaultPen;

    // 3. Use provided fallback or default
    return fallbackPen ?? ConsoleUtils.fallbackPen;
  }

  /// Creates a new `ISpectLoggerOptions` instance with modified properties.
  ///
  /// If a parameter is `null`, the existing value is preserved.
  ISpectLoggerOptions copyWith({
    bool? enabled,
    bool? useHistory,
    bool? useConsoleLogs,
    int? maxHistoryItems,
    int? logTruncateLength,
    Map<String, AnsiPen>? customColors,
  }) =>
      ISpectLoggerOptions(
        enabled: enabled ?? this.enabled,
        useHistory: useHistory ?? _useHistory,
        useConsoleLogs: useConsoleLogs ?? _useConsoleLogs,
        maxHistoryItems: maxHistoryItems ?? _maxHistoryItems,
        logTruncateLength: logTruncateLength ?? _logTruncateLength,
        customColors: customColors ?? _customColors,
      );
}
