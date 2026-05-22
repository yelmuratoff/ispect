import 'package:meta/meta.dart';

/// Computes delivered FPS from monotonic per-frame vsync timestamps over a
/// fixed 1-second window ending at the latest sample.
///
/// Using the full sample buffer would dilute the metric with idle gaps: when
/// the engine has no visual work it skips vsyncs, so "average over N samples"
/// understates the real frame rate during active rendering. Anchoring the
/// window to the latest timestamp instead reflects how many frames the engine
/// actually delivered during the most recent second of activity.
///
/// Returns `null` when fewer than two samples land in the window — signaling
/// "idle / not enough data" to the caller rather than reporting a spurious
/// FPS for a single frame.
///
/// The result is clamped to `[0, refreshRate]` because delivered FPS cannot
/// physically exceed the display refresh rate; values briefly above it would
/// be floating-point noise from the interval math.
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

/// Aggregated metrics for a window of frame durations.
///
/// Internal to the performance overlay; exposed as a top-level class so the
/// pure aggregation logic is unit-testable without spinning up a Flutter
/// widget tree.
@internal
@immutable
class PerformanceChartStats {
  const PerformanceChartStats({
    required this.avg,
    required this.p90,
    required this.p99,
    required this.jankCount,
  });

  /// Computes [avg], [p90], [p99] and [jankCount] over [samples].
  ///
  /// - `avg`: arithmetic mean across all samples.
  /// - `p90` / `p99`: nearest-rank percentile picked from the sorted samples;
  ///   for small windows this collapses toward the worst-frame metric the
  ///   Flutter docs recommend tracking alongside the average.
  /// - `jankCount`: number of samples strictly greater than [target].
  ///
  /// Returns a zero-filled instance when [samples] is empty.
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
    // Nearest-rank percentile (NIST): index = ceil(P * N) − 1, clamped.
    // The linear form `((n - 1) * P).floor()` undershoots small windows
    // (e.g. p99 of 2 samples lands on the smaller value), so this picks the
    // closest real sample at or above the percentile instead.
    final p90Index = ((n * 0.90).ceil() - 1).clamp(0, n - 1);
    final p99Index = ((n * 0.99).ceil() - 1).clamp(0, n - 1);
    return PerformanceChartStats(
      avg: Duration(microseconds: totalUs ~/ n),
      p90: sorted[p90Index],
      p99: sorted[p99Index],
      jankCount: janks,
    );
  }

  /// Average duration across the visible window.
  final Duration avg;

  /// 90th-percentile duration across the visible window.
  final Duration p90;

  /// 99th-percentile duration across the visible window.
  final Duration p99;

  /// Number of frames whose duration strictly exceeded the per-metric target.
  final int jankCount;
}
