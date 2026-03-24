import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/console_settings.dart';
import 'package:ispectify/src/filter/filter.dart';
import 'package:ispectify/src/logger/console_utils.dart';
import 'package:ispectify/src/logger/formatter.dart';
import 'package:ispectify/src/logger/logger_io.dart'
    if (dart.library.js_interop) 'logger_web.dart';
import 'package:ispectify/src/models/log_details.dart';
import 'package:ispectify/src/models/log_level.dart';

/// Callback signature for custom log output.
typedef LoggerOutput = void Function(
  String message, {
  LogLevel? logLevel,
  Object? error,
  StackTrace? stackTrace,
  DateTime? time,
});

/// Console logger: formats messages via [ILoggerFormatter] and writes
/// them through a [LoggerOutput] function.
///
/// Supports log-level filtering via [ConsoleSettings] and [ILoggerFilter],
/// plus ANSI colorization.
class ISpectBaseLogger {
  ISpectBaseLogger({
    ConsoleSettings? settings,
    this.formatter = const ExtendedLoggerFormatter(),
    ILoggerFilter? filter,
    LoggerOutput? output,
  })  : settings = settings ?? ConsoleSettings(),
        _filter = filter,
        _output = output ?? outputLog {
    ansiColorDisabled = false;
  }

  final ConsoleSettings settings;
  final ILoggerFormatter formatter;
  final LoggerOutput _output;
  final ILoggerFilter? _filter;

  void log(
    Object? msg, {
    LogLevel? level,
    AnsiPen? pen,
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
  }) {
    final selectedLevel = level ?? LogLevel.debug;

    if (!settings.enabled ||
        selectedLevel.index > settings.level.index ||
        !(_filter?.shouldLog(msg, selectedLevel) ?? true)) {
      return;
    }

    final selectedPen =
        pen ?? settings.colors[selectedLevel] ?? ConsoleUtils.fallbackPen;

    final formattedMsg = formatter.format(
      LogDetails(message: msg, level: selectedLevel, pen: selectedPen),
      settings,
    );
    _output(
      formattedMsg,
      logLevel: selectedLevel,
      error: error,
      stackTrace: stackTrace,
      time: time,
    );
  }

  void critical(Object? msg) => log(msg, level: LogLevel.critical);
  void error(Object? msg) => log(msg, level: LogLevel.error);
  void warning(Object? msg) => log(msg, level: LogLevel.warning);
  void debug(Object? msg) => log(msg, level: LogLevel.debug);
  void verbose(Object? msg) => log(msg, level: LogLevel.verbose);
  void info(Object? msg) => log(msg, level: LogLevel.info);

  ISpectBaseLogger copyWith({
    ConsoleSettings? settings,
    ILoggerFormatter? formatter,
    ILoggerFilter? filter,
    LoggerOutput? output,
  }) =>
      ISpectBaseLogger(
        settings: settings ?? this.settings,
        formatter: formatter ?? this.formatter,
        filter: filter ?? _filter,
        output: output ?? _output,
      );

  @override
  String toString() =>
      'ISpectBaseLogger(enabled: ${settings.enabled}, level: ${settings.level})';
}
