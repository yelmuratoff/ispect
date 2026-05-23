import 'package:meta/meta.dart';

/// Short enough that a single hitch drops the reading visibly, long enough
/// that one-off blips do not dominate.
const int _kFpsWindow = 10;

/// Smoothed FPS derived from `FrameTiming.totalSpan` — the wall-clock
/// interval from vsync request to raster completion. Averaging *delivered
/// cadence* rather than *work* makes single-frame hitches visible: the
/// previous capacity formula (`1e6 / max(avg(build), avg(raster))`) glued
/// the reading to the refresh ceiling because both averages stayed well
/// under one vsync interval even when one frame missed several vsyncs.
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

/// Raw count of vsync intervals the previous frame stayed on screen beyond
/// its scheduled slot — `ceil(totalSpan/target) − 1`. Any over-target frame
/// counts as at least 1. Used to drive the sustained-jank burst detector
/// (where any over-target streak should alert the developer); the
/// user-facing "drops" UI metric uses [perceptibleDrops] instead.
@internal
int missedVsyncs(int totalSpanUs, int targetUs) {
  if (targetUs <= 0 || totalSpanUs <= targetUs) return 0;
  return (totalSpanUs - 1) ~/ targetUs;
}

/// One 60Hz vsync — the floor of human perception for display stutter.
/// Apple's MetricKit hitch definition uses the same boundary.
const int _kPerceptibleStutterUs = 16667;

/// User-facing drop count — counts only frames where the display gap is long
/// enough for a person to actually notice. On a 120Hz panel a single missed
/// vsync = 8.33 ms of display lag, which is below the ~16.67 ms perception
/// threshold; counting every one of those inflates the metric with events
/// the user never sees and erodes trust in the overlay. The "drops" header
/// reading therefore uses this function while [missedVsyncs] feeds the raw
/// developer-facing burst detector.
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
    // Nearest-rank (NIST): `ceil(P × N) − 1`. The linear form
    // `((n - 1) × P).floor()` undershoots tiny windows — p99 of 2 samples
    // would land on the smaller value.
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
