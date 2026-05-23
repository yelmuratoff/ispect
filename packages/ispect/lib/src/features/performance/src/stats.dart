import 'package:meta/meta.dart';

const int _kFpsWindow = 10;

@internal
double? computeSmoothFps(List<int> totalSpansUs, double refreshRate) {
  final n = totalSpansUs.length;
  if (n == 0) return null;
  final from = n > _kFpsWindow ? n - _kFpsWindow : 0;
  final count = n - from;
  var total = 0;
  for (var i = from; i < n; i++) {
    total += totalSpansUs[i];
  }
  if (total <= 0) return refreshRate;
  final fps = 1e6 / (total / count);
  return fps < refreshRate ? fps : refreshRate;
}

/// Raw `ceil(totalSpan/target) − 1`. Used by the burst detector; the UI
/// metric uses [perceptibleDrops].
@internal
int missedVsyncs(int totalSpanUs, int targetUs) {
  if (targetUs <= 0 || totalSpanUs <= targetUs) return 0;
  return (totalSpanUs - 1) ~/ targetUs;
}

/// One 60Hz vsync — floor of human perception for display stutter (Apple
/// MetricKit hitch threshold).
const int _kPerceptibleStutterUs = 16667;

/// Drops the user can actually notice: excess display time ≥ one 60Hz frame.
@internal
int perceptibleDrops(int totalSpanUs, int targetUs) {
  if (targetUs <= 0 || totalSpanUs <= targetUs) return 0;
  final missed = (totalSpanUs - 1) ~/ targetUs;
  final excessDisplayUs = missed * targetUs;
  if (excessDisplayUs < _kPerceptibleStutterUs) return 0;
  return excessDisplayUs ~/ _kPerceptibleStutterUs;
}

@internal
@immutable
class PerformanceChartStats {
  const PerformanceChartStats({
    required this.avg,
    required this.p90,
    required this.p99,
    required this.jankCount,
  });

  factory PerformanceChartStats.fromMicroseconds(
    List<int> samplesUs,
    int targetUs,
  ) {
    final n = samplesUs.length;
    if (n == 0) return zero;
    final sorted = List<int>.of(samplesUs)..sort();
    var total = 0;
    var janks = 0;
    for (var i = 0; i < n; i++) {
      final s = samplesUs[i];
      total += s;
      if (s > targetUs) janks++;
    }
    // Nearest-rank (NIST); the linear form undershoots tiny windows.
    final p90Index = ((n * 0.90).ceil() - 1).clamp(0, n - 1);
    final p99Index = ((n * 0.99).ceil() - 1).clamp(0, n - 1);
    return PerformanceChartStats(
      avg: Duration(microseconds: total ~/ n),
      p90: Duration(microseconds: sorted[p90Index]),
      p99: Duration(microseconds: sorted[p99Index]),
      jankCount: janks,
    );
  }

  static const PerformanceChartStats zero = PerformanceChartStats(
    avg: Duration.zero,
    p90: Duration.zero,
    p99: Duration.zero,
    jankCount: 0,
  );

  final Duration avg;
  final Duration p90;
  final Duration p99;
  final int jankCount;
}
