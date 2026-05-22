import 'package:meta/meta.dart';

/// Delivered FPS over a 1-second window anchored to the latest vsync.
///
/// Anchoring to the latest sample (instead of averaging over the whole
/// buffer) prevents idle vsync gaps from dragging the metric down — when the
/// engine has no visual work it skips vsyncs and the buffer-average would
/// understate the real rate during active rendering.
///
/// Returns `null` when fewer than two samples land in the window — caller
/// renders that as "idle / not enough data" rather than a spurious 1-frame
/// rate. Clamped to `[0, refreshRate]` to discard floating-point noise that
/// would push the value above what vsync allows.
@internal
double? computeDeliveredFpsFromVsyncs(
  List<int> vsyncTimestampsUs,
  double refreshRate,
) {
  if (vsyncTimestampsUs.length < 2) return null;
  final lastUs = vsyncTimestampsUs.last;
  const windowUs = 1000000;
  var firstIdx = vsyncTimestampsUs.length;
  for (var i = vsyncTimestampsUs.length - 1; i >= 0; i--) {
    if (lastUs - vsyncTimestampsUs[i] > windowUs) break;
    firstIdx = i;
  }
  final count = vsyncTimestampsUs.length - firstIdx;
  if (count < 2) return null;
  final spanUs = lastUs - vsyncTimestampsUs[firstIdx];
  if (spanUs <= 0) return null;
  final fps = ((count - 1) * 1e6) / spanUs;
  return fps.clamp(0, refreshRate);
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
