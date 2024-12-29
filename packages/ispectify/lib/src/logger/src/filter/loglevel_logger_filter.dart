import 'package:ispectify/src/logger/src/filter/logger_filter.dart';
import 'package:ispectify/src/logger/src/models/log_level.dart';

/// This filter checks that current message level
/// is above certain [LogLevel] setting in [ISpectifyLoggerSettings]
class LogLevelFilter implements LoggerFilter {
  const LogLevelFilter(this.logLevel);

  final LogLevel logLevel;

  @override
  bool shouldLog(dynamic msg, LogLevel level) {
    final currLogLevelIndex = logLevelPriorityList.indexOf(logLevel);
    final msgLogLevelIndex = logLevelPriorityList.indexOf(level);
    return currLogLevelIndex >= msgLogLevelIndex;
  }
}
