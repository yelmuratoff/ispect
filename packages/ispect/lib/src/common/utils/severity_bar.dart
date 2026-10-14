import 'package:ispectify/ispectify.dart';

enum LogSeverity { error, warning, normal }

LogSeverity classifySeverity(ISpectLogData data) {
  final captured = captureISpectLogWithoutPayload(data);
  final level = captured.logLevel;
  final isError =
      level == LogLevel.error ||
      level == LogLevel.critical ||
      ISpectLogType.isErrorKey(captured.key) ||
      maskedDiagnosticField(data, TraceKeys.success) == false;
  if (isError) return LogSeverity.error;
  if (level == LogLevel.warning || captured.key == ISpectLogType.warning.key) {
    return LogSeverity.warning;
  }
  return LogSeverity.normal;
}

/// Left accent bar parameters based on log severity.
///
/// Bar is a primary scanning cue, so widths and alphas are bumped to make
/// the row colour-readable at a glance.
///
/// - error/critical → 5 px, full opacity
/// - warning → 4 px
/// - everything else → 3 px
({double width, double alpha}) severityBar(ISpectLogData data) =>
    switch (classifySeverity(data)) {
      LogSeverity.error => (width: 5.0, alpha: 1),
      LogSeverity.warning => (width: 4.0, alpha: 0.9),
      LogSeverity.normal => (width: 3.0, alpha: 0.75),
    };
