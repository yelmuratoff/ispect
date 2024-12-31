import 'package:ispectify/src/logger/src/models/log_level.dart';

abstract class LoggerFilter {
  bool shouldLog(dynamic msg, LogLevel level);
}
