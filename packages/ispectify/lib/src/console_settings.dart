import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/logger/console_utils.dart';
import 'package:ispectify/src/logger/entry_formatter.dart';
import 'package:ispectify/src/models/log_level.dart';

/// Configuration settings for ISpectLogger logger.
///
/// This class defines how logs are formatted, colored, and displayed.
final class ConsoleSettings {
  /// Creates an instance of `ConsoleSettings` with customizable options.
  ///
  /// - `colors`: Custom ANSI colors for different log levels.
  /// - `enable`: Enables or disables logging (default: `true`).
  /// - `defaultTitle`: Default title for logs (default: `'Log'`).
  /// - `level`: Minimum log level to be recorded (default: `LogLevel.verbose`).
  /// - `lineSymbol`: The symbol used for log separators (default: `'─'`).
  /// - `maxLineWidth`: Maximum width for log lines (default: `110`).
  /// - `enableColors`: Enables ANSI colors in console output (default: `true`).
  /// - `fullTimestamp`: When `true`, console timestamps include the full
  ///   ISO-8601 date with timezone; when `false`, only `HH:MM:SS.mmm`
  ///   (default: `false`).
  /// - `truncateTraceIds`: When `true`, 16-character hex trace IDs (the ones
  ///   produced by `generateTraceId`) are shortened to their 8-character
  ///   prefix in the console metadata column; the full value remains in
  ///   `additionalData` for filtering and the in-app viewer. Custom
  ///   user-supplied IDs (`msg-1`, `txn-orders-2`, …) are never trimmed.
  ///   (default: `true`).
  /// - `formatter`: Owns the end-to-end shape of each console line. Defaults to
  ///   the compact [HumanLogEntryFormatter]; pass [BoxedLogEntryFormatter] for
  ///   visually-separated boxed output, or any custom [ILogEntryFormatter].
  ConsoleSettings({
    Map<LogLevel, AnsiPen>? colors,
    this.enabled = true,
    this.defaultTitle = 'Log',
    this.level = LogLevel.verbose,
    this.lineSymbol = '─',
    this.maxLineWidth = 110,
    this.enableColors = true,
    this.fullTimestamp = false,
    this.truncateTraceIds = true,
    this.formatter = const HumanLogEntryFormatter(),
  })  : assert(maxLineWidth > 0, 'maxLineWidth must be positive'),
        colors = Map<LogLevel, AnsiPen>.unmodifiable({
          ...ConsoleUtils.ansiColors,
          if (colors != null) ...colors,
        });

  /// ANSI colors for log levels.
  final Map<LogLevel, AnsiPen> colors;

  /// Whether logging is enabled.
  final bool enabled;

  /// Default log title.
  final String defaultTitle;

  /// Minimum log level required for a log to be recorded.
  final LogLevel level;

  /// Symbol used for log line separators.
  final String lineSymbol;

  /// Maximum width for log messages.
  final int maxLineWidth;

  /// Whether ANSI colors are enabled in logs.
  final bool enableColors;

  /// Whether to render console timestamps in full ISO-8601 form with timezone.
  final bool fullTimestamp;

  /// Whether to shorten auto-generated 16-character hex trace IDs to their
  /// 8-character prefix in the console metadata column.
  final bool truncateTraceIds;

  /// Strategy that renders each [ISpectLogData] entry into its console string.
  final ILogEntryFormatter formatter;

  /// Creates a new instance of `ConsoleSettings` with modified properties.
  ///
  /// If a parameter is `null`, the existing value is preserved.
  ConsoleSettings copyWith({
    Map<LogLevel, AnsiPen>? colors,
    bool? enabled,
    String? defaultTitle,
    LogLevel? level,
    String? lineSymbol,
    int? maxLineWidth,
    bool? enableColors,
    bool? fullTimestamp,
    bool? truncateTraceIds,
    ILogEntryFormatter? formatter,
  }) =>
      ConsoleSettings(
        colors: colors ?? this.colors,
        enabled: enabled ?? this.enabled,
        defaultTitle: defaultTitle ?? this.defaultTitle,
        level: level ?? this.level,
        lineSymbol: lineSymbol ?? this.lineSymbol,
        maxLineWidth: maxLineWidth ?? this.maxLineWidth,
        enableColors: enableColors ?? this.enableColors,
        fullTimestamp: fullTimestamp ?? this.fullTimestamp,
        truncateTraceIds: truncateTraceIds ?? this.truncateTraceIds,
        formatter: formatter ?? this.formatter,
      );
}
