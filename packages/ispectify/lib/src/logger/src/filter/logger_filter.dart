import 'package:ispectify/src/logger/src/models/log_level.dart';

abstract class ILoggerFilter {
  const ILoggerFilter();

  bool shouldLog(Object? msg, LogLevel level);
}

class LoggerFilter extends ILoggerFilter {
  const LoggerFilter({
    this.minLevel = LogLevel.debug,
    this.maxLevel = LogLevel.critical,
  });

  final LogLevel minLevel;
  final LogLevel maxLevel;

  @override
  bool shouldLog(Object? msg, LogLevel level) =>
      level.index >= minLevel.index && level.index <= maxLevel.index;
}
