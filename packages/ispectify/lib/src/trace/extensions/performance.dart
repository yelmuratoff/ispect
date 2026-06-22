import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/trace/trace_categories.dart';
import 'package:ispectify/src/trace/trace_config.dart';
import 'package:ispectify/src/trace/trace_extension.dart';

/// Trace helpers for runtime performance signals (frame jank, slow work).
extension ISpectLoggerPerformance on ISpectLogger {
  /// Logs a jank frame under [performanceCategory].
  ///
  /// [buildDuration], [rasterDuration], and [totalSpan] mirror the matching
  /// `FrameTiming` fields. [targetFrameTime] is the per-frame budget
  /// (typically `1e6 / display.refreshRate` µs).
  ///
  /// [stackTrace] is recorded in `meta['stack_trace']` so it survives both
  /// success and warning log paths. Passing one from the overlay's own
  /// `addTimingsCallback` is **misleading**: by the time the engine fires
  /// timings, the offending frame is done and the current stack points at
  /// engine dispatch code — not the cause. Capture it only when the caller
  /// is the suspected hot spot itself.
  void performanceJank({
    required String source,
    required Duration buildDuration,
    required Duration rasterDuration,
    required Duration totalSpan,
    required Duration targetFrameTime,
    StackTrace? stackTrace,
    Map<String, Object?>? meta,
    ISpectTraceConfig? config,
    String? correlationId,
  }) {
    final targetMs = _formatMs(targetFrameTime);
    final buildMs = _formatMs(buildDuration);
    final rasterMs = _formatMs(rasterDuration);
    final totalMs = _formatMs(totalSpan);
    traceCategory(
      category: performanceCategory,
      source: source,
      operation: 'jank',
      duration: totalSpan,
      meta: <String, Object?>{
        'ui_ms': buildMs,
        'raster_ms': rasterMs,
        'total_ms': totalMs,
        'target_ms': targetMs,
        if (stackTrace != null) 'stack_trace': stackTrace.toString(),
        ...?meta,
      },
      config: config,
      correlationId: correlationId,
      consoleMessage: 'Performance jank: total ${totalMs}ms '
          '(UI ${buildMs}ms · raster ${rasterMs}ms · target ${targetMs}ms)',
    );
  }
}

String _formatMs(Duration d) => (d.inMicroseconds / 1e3).toStringAsFixed(1);
