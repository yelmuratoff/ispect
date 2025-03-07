import 'package:ansicolor/ansicolor.dart';
import 'package:ispectify/src/logger/src/filter/logger_filter.dart';
import 'package:ispectify/src/logger/src/formatter/formatter.dart';
import 'package:ispectify/src/logger/src/logger/logger_io.dart'
    if (dart.library.html) 'logger_html.dart'
    if (dart.library.js_interop) 'logger_web.dart';
import 'package:ispectify/src/logger/src/models/log_details.dart';
import 'package:ispectify/src/logger/src/models/log_level.dart';
import 'package:ispectify/src/logger/src/settings.dart';

class ISpectifyLogger {
  ISpectifyLogger({
    LoggerSettings? settings,
    this.formatter = const ExtendedLoggerFormatter(),
    ILoggerFilter? filter,
    void Function(String message)? output,
  }) {
    this.settings = settings ?? LoggerSettings();
    _output = output ?? outputLog;
    _filter = filter;
    ansiColorDisabled = false;
  }

  late final LoggerSettings settings;
  final LoggerFormatter formatter;

  late final void Function(String message) _output;
  ILoggerFilter? _filter;

  void log(Object? msg, {LogLevel? level, AnsiPen? pen}) {
    if (!settings.enable) {
      return;
    }
    final selectedLevel = level ?? LogLevel.debug;
    final selectedPen =
        pen ?? settings.colors[selectedLevel] ?? (AnsiPen()..gray());

    if (_filter?.shouldLog(msg, selectedLevel) ?? true) {
      final formattedMsg = formatter.format(
        LogDetails(message: msg, level: selectedLevel, pen: selectedPen),
        settings,
      );
      _output(formattedMsg);
    }
  }

  void critical(Object? msg) => log(msg, level: LogLevel.critical);

  void error(Object? msg) => log(msg, level: LogLevel.error);

  void warning(Object? msg) => log(msg, level: LogLevel.warning);

  void debug(Object? msg) => log(msg);

  void verbose(Object? msg) => log(msg, level: LogLevel.verbose);

  void info(Object? msg) => log(msg, level: LogLevel.info);

  ISpectifyLogger copyWith({
    LoggerSettings? settings,
    LoggerFormatter? formatter,
    ILoggerFilter? filter,
    void Function(String message)? output,
  }) =>
      ISpectifyLogger(
        settings: settings ?? this.settings,
        formatter: formatter ?? this.formatter,
        filter: filter ?? _filter,
        output: output ?? _output,
      );
}
