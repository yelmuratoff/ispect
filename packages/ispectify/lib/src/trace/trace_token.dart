import 'package:ispectify/src/trace/trace_category.dart';
import 'package:ispectify/src/trace/trace_config.dart';

/// Token returned by `traceStart` for manual span timing.
///
/// Always call `traceEnd` after `traceStart`. If `traceEnd` is not called,
/// the [Stopwatch] continues running until GC (bytes-level leak).
/// `traceStart` returns `null` when logger is disabled — calling
/// `traceEnd(null)` is a no-op.
final class ISpectTraceToken {
  ISpectTraceToken({
    required Stopwatch stopwatch,
    required this.category,
    required this.source,
    required this.operation,
    this.target,
    this.key,
    this.meta,
    this.config,
    this.correlationId,
  }) : _stopwatch = stopwatch;

  final Stopwatch _stopwatch;
  final ISpectTraceCategory category;
  final String source;
  final String operation;
  final String? target;
  final String? key;
  final Map<String, Object?>? meta;
  final ISpectTraceConfig? config;
  final String? correlationId;

  void stopTiming() => _stopwatch.stop();
  Duration get elapsed => _stopwatch.elapsed;
}
