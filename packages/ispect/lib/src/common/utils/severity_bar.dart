import 'package:ispectify/ispectify.dart';

/// Left accent bar parameters based on log severity.
///
/// - error/critical → 4 px, full opacity
/// - warning → 3 px
/// - everything else → 2 px (subtle)
({double width, double alpha}) severityBar(ISpectLogData data) {
  if (data.isError) return (width: 4.0, alpha: 0.9);

  final level = data.logLevel;
  if (level == LogLevel.warning || data.key == ISpectLogType.warning.key) {
    return (width: 3.0, alpha: 0.7);
  }

  return (width: 2.0, alpha: 0.4);
}
