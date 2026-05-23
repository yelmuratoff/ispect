import 'package:meta/meta.dart';

/// Window size for the capacity-based FPS estimate.
const int _kFpsWindow = 10;

/// Capacity-based FPS estimate: the maximum frame rate the engine *could*
/// sustain given recent per-frame work.
///
@internal
double? computeEffectiveFps(
  List<int> buildDurationsUs,
  List<int> rasterDurationsUs,
  double refreshRate,
) {
  final n = buildDurationsUs.length;
  if (n == 0 || rasterDurationsUs.length != n) return null;
  final from = n > _kFpsWindow ? n - _kFpsWindow : 0;
  final count = n - from;
  var totalBuildUs = 0;
  var totalRasterUs = 0;
  for (var i = from; i < n; i++) {
    totalBuildUs += buildDurationsUs[i];
    totalRasterUs += rasterDurationsUs[i];
  }
  final avgBuildUs = totalBuildUs / count;
  final avgRasterUs = totalRasterUs / count;
  final bottleneckUs = avgBuildUs > avgRasterUs ? avgBuildUs : avgRasterUs;
  if (bottleneckUs <= 0) return refreshRate;
  final capacity = 1e6 / bottleneckUs;
  return capacity < refreshRate ? capacity : refreshRate;
}

/// Top-level (not nested) so the aggregation logic is unit-testable without
/// pumping a widget tree.
@internal
@immutable
class PerformanceChartStats {
  const PerformanceChartStats({
    required this.avg,
    required this.p90,
    required this.p99,
    required this.jankCount,
  });

  /// Returns zero-filled stats for an empty window. `jankCount` counts samples
  /// strictly greater than [target].
  factory PerformanceChartStats.from(
    List<Duration> samples,
    Duration target,
  ) {
    if (samples.isEmpty) {
      return const PerformanceChartStats(
        avg: Duration.zero,
        p90: Duration.zero,
        p99: Duration.zero,
        jankCount: 0,
      );
    }
    final sorted = [...samples]..sort();
    var totalUs = 0;
    var janks = 0;
    for (final d in samples) {
      totalUs += d.inMicroseconds;
      if (d > target) janks++;
    }
    final n = sorted.length;
    // Nearest-rank (NIST): `ceil(P × N) − 1`. The linear form
    // `((n - 1) × P).floor()` undershoots tiny windows — p99 of 2 samples
    // would land on the smaller value.
    final p90Index = ((n * 0.90).ceil() - 1).clamp(0, n - 1);
    final p99Index = ((n * 0.99).ceil() - 1).clamp(0, n - 1);
    return PerformanceChartStats(
      avg: Duration(microseconds: totalUs ~/ n),
      p90: sorted[p90Index],
      p99: sorted[p99Index],
      jankCount: janks,
    );
  }

  final Duration avg;
  final Duration p90;
  final Duration p99;
  final int jankCount;
}
