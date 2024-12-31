import 'package:ispectify/src/logger/src/models/log_details.dart';
import 'package:ispectify/src/logger/src/settings.dart';

abstract class LoggerFormatter {
  String format(
    LogDetails details,
    ISpectifyLoggerSettings settings,
  );
}
