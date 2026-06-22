import 'package:ispectify/ispectify.dart';

/// Configuration for [ISpectLogger] behavior. Per-type colors can be overridden
/// via [customColors]; defaults come from the [ISpectLogType] registry.
class ISpectLoggerOptions {
  ISpectLoggerOptions({
    this.enabled = true,
    bool useHistory = true,
    bool useConsoleLogs = true,
    bool forwardErrorToConsole = false,
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
        _forwardErrorToConsole = forwardErrorToConsole,
        _maxHistoryItems = maxHistoryItems,
        _logTruncateLength = logTruncateLength,
        _customColors =
            customColors != null ? Map.unmodifiable(customColors) : null;

  bool get useHistory => _useHistory && enabled;
  final bool _useHistory;

  bool get useConsoleLogs => _useConsoleLogs && enabled;
  final bool _useConsoleLogs;

  /// Whether `error` and `stackTrace` are forwarded to the underlying
  /// `dart:developer` log call.
  ///
  /// Disabled by default to avoid duplication: the formatted console message
  /// already renders both fields as text. Enable when separate error/stack
  /// visibility in DevTools or an IDE console is preferred.
  bool get forwardErrorToConsole => _forwardErrorToConsole && enabled;
  final bool _forwardErrorToConsole;

  int get maxHistoryItems => _maxHistoryItems;
  final int _maxHistoryItems;

  int get logTruncateLength => _logTruncateLength;
  final int _logTruncateLength;

  final bool enabled;

  final Map<String, AnsiPen>? _customColors;

  /// Resolves the pen for [key]: custom override → [ISpectLogType] default →
  /// [fallbackPen] → [ConsoleUtils.fallbackPen].
  AnsiPen penByKey(String? key, {AnsiPen? fallbackPen}) {
    if (key == null) return fallbackPen ?? ConsoleUtils.fallbackPen;

    final customPen = _customColors?[key];
    if (customPen != null) return customPen;

    final defaultPen = ISpectLogType.fromKey(key)?.defaultPen;
    if (defaultPen != null) return defaultPen;

    return fallbackPen ?? ConsoleUtils.fallbackPen;
  }

  /// Returns a new instance with the provided fields replaced; `null`
  /// arguments preserve the existing value.
  ISpectLoggerOptions copyWith({
    bool? enabled,
    bool? useHistory,
    bool? useConsoleLogs,
    bool? forwardErrorToConsole,
    int? maxHistoryItems,
    int? logTruncateLength,
    Map<String, AnsiPen>? customColors,
  }) =>
      ISpectLoggerOptions(
        enabled: enabled ?? this.enabled,
        useHistory: useHistory ?? _useHistory,
        useConsoleLogs: useConsoleLogs ?? _useConsoleLogs,
        forwardErrorToConsole: forwardErrorToConsole ?? _forwardErrorToConsole,
        maxHistoryItems: maxHistoryItems ?? _maxHistoryItems,
        logTruncateLength: logTruncateLength ?? _logTruncateLength,
        customColors: customColors ?? _customColors,
      );
}
