/// Defines the interface for logger configuration.
///
/// The [ILoggerConfig] interface specifies the contract for logger settings,
/// including options for displaying timestamps, log levels, and enabling colors.
abstract interface class ILoggerConfig {
  /// Default constructor for [ILoggerConfig].
  const ILoggerConfig();

  /// Determines if the timestamp should be displayed in log messages.
  bool get showTimestamp;

  /// Determines if the log key should be displayed in log messages.
  bool get showKey;

  /// Determines if the name of the logger should be displayed in log messages.
  bool get showName;

  /// Specifies whether colors are enabled for log messages.
  bool get isColorsEnabled;

  /// The symbol used for drawing lines in the log output.
  String get lineSymbol;

  /// The length of the line symbols used for formatting log borders.
  int get symbolLength;
}

/// Default implementation of the [ILoggerConfig] interface.
///
/// The [LoggerConfig] class provides a concrete implementation of logger
/// configuration settings with default values and customization options.
final class LoggerConfig implements ILoggerConfig {
  /// Creates a new instance of [LoggerConfig].
  ///
  /// ### Parameters:
  /// - [showTimestamp]: If `true`, timestamps will be displayed in logs. Defaults to `true`.
  /// - [showKey]: If `true`, log keys will be displayed in logs. Defaults to `true`.
  /// - [showName]: If `true`, logger names will be displayed in logs. Defaults to `true`.
  /// - [isColorsEnabled]: If `true`, colored log messages are enabled. Defaults to `true`.
  /// - [lineSymbol]: The symbol used for drawing lines. Defaults to `'─'`.
  /// - [symbolLength]: The length of line symbols for formatting. Defaults to `110`.
  const LoggerConfig({
    this.showTimestamp = true,
    this.showKey = true,
    this.showName = true,
    this.isColorsEnabled = true,
    this.lineSymbol = '─',
    this.symbolLength = 110,
  });

  /// Determines if the timestamp should be displayed in log messages.
  @override
  final bool showTimestamp;

  /// Determines if the log keys should be displayed in log messages.
  @override
  final bool showKey;

  /// Determines if the name of the logger should be displayed in log messages.
  @override
  final bool showName;

  /// Specifies whether colors are enabled for log messages.
  @override
  final bool isColorsEnabled;

  /// The symbol used for drawing lines in the log output.
  @override
  final String lineSymbol;

  /// The length of the line symbols used for formatting log borders.
  @override
  final int symbolLength;
}
