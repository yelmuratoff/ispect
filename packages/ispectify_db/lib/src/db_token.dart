/// Opaque handle returned by [ISpectLoggerDb.dbStart] that captures
/// the operation context and a running [Stopwatch].
///
/// Pass to [ISpectLoggerDb.dbEnd] to finalize the log entry with
/// measured duration and result data.
final class ISpectDbToken {
  ISpectDbToken({
    required Stopwatch stopwatch,
    this.source,
    this.operation,
    this.statement,
    this.target,
    this.table,
    this.key,
    this.args,
    this.namedArgs,
    this.meta,
    this.transactionId,
  }) : _stopwatch = stopwatch;

  final Stopwatch _stopwatch;

  /// Stops the internal stopwatch. Idempotent — safe to call multiple times.
  void stopTiming() => _stopwatch.stop();

  /// Elapsed duration since [dbStart] was called.
  Duration get elapsed => _stopwatch.elapsed;

  final String? source;
  final String? operation;
  final String? statement;
  final String? target;
  final String? table;
  final String? key;
  final List<Object?>? args;
  final Map<String, Object?>? namedArgs;
  final Map<String, Object?>? meta;
  final String? transactionId;

  @override
  String toString() => 'ISpectDbToken('
      'source: $source, '
      'operation: $operation, '
      'elapsed: ${_stopwatch.elapsed})';
}
