import 'package:ispectify/ispectify.dart';

/// Left accent bar parameters based on log severity.
///
/// - error/critical → 5 px, full opacity
/// - warning → 4 px
/// - everything else → 3 px
({double width, double alpha}) severityBar(ISpectLogData data) {
  if (data.isError) return (width: 5.0, alpha: 0.9);

  final level = data.logLevel;
  if (level == LogLevel.warning || data.key == ISpectLogType.warning.key) {
    return (width: 4.0, alpha: 0.7);
  }

  return (width: 3.0, alpha: 0.5);
}
