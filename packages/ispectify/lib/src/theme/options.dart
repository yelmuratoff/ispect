import 'package:ispectify/ispectify.dart';

/// Fallback color for logs without a predefined color.
final AnsiPen _fallbackPen = AnsiPen()..gray();

/// Helper function to get default pen for a log type key.
AnsiPen? _getDefaultPenByKey(String key) {
  try {
    final logType = ISpectifyLogType.values.firstWhere((e) => e.key == key);
    return logType.defaultPen;
  } catch (_) {
    return null;
  }
}

/// Configuration options for ISpectify logging.
///
/// This class allows customization of logging behavior, including
/// enabling/disabling logs, storing log history, and customizing
/// log colors and titles.
///
/// Color and title customization now uses the [ISpectifyLogTypeRegistry]
/// for better extensibility. Custom overrides can be provided via
/// the [customTitles] and [customColors] parameters.
class ISpectifyOptions {
  /// Creates an instance of `ISpectifyOptions` with customizable settings.
  ///
  /// - `enabled`: Whether logging is enabled.
  /// - `useHistory`: Whether to store logs in history.
  /// - `useConsoleLogs`: Whether to print logs to the console.
  /// - `maxHistoryItems`: Maximum number of logs to retain in history.
  /// - `logTruncateLength`: Maximum length for log messages in console.
  /// - `customTitles`: Custom log titles that override registry defaults.
  /// - `customColors`: Custom log colors that override registry defaults.
  ISpectifyOptions({
    this.enabled = true,
    bool useHistory = true,
    bool useConsoleLogs = true,
    int maxHistoryItems = 10000,
    int logTruncateLength = 10000,
    Map<String, String>? customTitles,
    Map<String, AnsiPen>? customColors,
  })  : _useHistory = useHistory,
        _useConsoleLogs = useConsoleLogs,
        _maxHistoryItems = maxHistoryItems,
        _logTruncateLength = logTruncateLength,
        _customTitles =
            customTitles != null ? Map.unmodifiable(customTitles) : null,
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
  bool enabled;

  /// Custom title overrides (immutable after creation).
  final Map<String, String>? _customTitles;

  /// Custom color overrides (immutable after creation).
  final Map<String, AnsiPen>? _customColors;

  /// Retrieves the title associated with a given log type key.
  ///
  /// First checks custom overrides, then falls back to the key itself.
  String titleByKey(String key) {
    // 1. Check custom override
    final customTitle = _customTitles?[key];
    if (customTitle != null) return customTitle;

    // 2. Fallback to key itself
    return key;
  }

  /// Retrieves the ANSI color associated with a given log type key.
  ///
  /// First checks custom overrides, then built-in defaults from ISpectifyLogType,
  /// then provided fallback, finally falls back to default gray.
  AnsiPen penByKey(String? key, {AnsiPen? fallbackPen}) {
    if (key == null) return fallbackPen ?? _fallbackPen;

    // 1. Check custom override
    final customPen = _customColors?[key];
    if (customPen != null) return customPen;

    // 2. Check built-in defaults
    final defaultPen = _getDefaultPenByKey(key);
    if (defaultPen != null) return defaultPen;

    // 3. Use provided fallback or default
    return fallbackPen ?? _fallbackPen;
  }

  /// Creates a new `ISpectifyOptions` instance with modified properties.
  ///
  /// If a parameter is `null`, the existing value is preserved.
  ISpectifyOptions copyWith({
    bool? enabled,
    bool? useHistory,
    bool? useConsoleLogs,
    int? maxHistoryItems,
    int? logTruncateLength,
    Map<String, String>? customTitles,
    Map<String, AnsiPen>? customColors,
  }) =>
      ISpectifyOptions(
        enabled: enabled ?? this.enabled,
        useHistory: useHistory ?? _useHistory,
        useConsoleLogs: useConsoleLogs ?? _useConsoleLogs,
        maxHistoryItems: maxHistoryItems ?? _maxHistoryItems,
        logTruncateLength: logTruncateLength ?? _logTruncateLength,
        customTitles: customTitles ?? _customTitles,
        customColors: customColors ?? _customColors,
      );
}
