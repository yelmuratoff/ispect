import 'dart:collection';

import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/options.dart';
import 'package:ispectify/src/trace/trace_keys.dart';

/// Test double for [ISpectLogger]. Captures all logs for assertions.
///
/// Uses [Queue] (O(1) removeFirst) for FIFO rotation with [maxTraces].
class FakeISpectLogger extends ISpectLogger {
  FakeISpectLogger({
    this.maxTraces = 10000,
  }) : super(
          options: ISpectLoggerOptions(
            useConsoleLogs: false,
            maxHistoryItems: 0,
          ),
        );

  final int maxTraces;
  final _queue = Queue<ISpectLogData>();

  /// Read-only snapshot as List.
  List<ISpectLogData> get traces => _queue.toList();

  Iterable<ISpectLogData> get _traces => _queue;

  @override
  void logData(ISpectLogData log) {
    _queue.add(log);
    while (_queue.length > maxTraces) {
      _queue.removeFirst();
    }
    super.logData(log);
  }

  // ── Query by structured trace fields ───────────────────────────────

  List<ISpectLogData> byCategory(String category) => _traces
      .where((t) => t.additionalData?[TraceKeys.category] == category)
      .toList();

  List<ISpectLogData> bySource(String source) => _traces
      .where((t) => t.additionalData?[TraceKeys.source] == source)
      .toList();

  List<ISpectLogData> byOperation(String operation) => _traces
      .where((t) => t.additionalData?[TraceKeys.operation] == operation)
      .toList();

  List<ISpectLogData> byCorrelationId(String correlationId) => _traces
      .where(
        (t) => t.additionalData?[TraceKeys.correlationId] == correlationId,
      )
      .toList();

  List<ISpectLogData> byTransactionId(String transactionId) => _traces
      .where(
        (t) => t.additionalData?[TraceKeys.transactionId] == transactionId,
      )
      .toList();

  List<ISpectLogData> byLogKey(String logKey) =>
      _traces.where((t) => t.key == logKey).toList();

  List<ISpectLogData> errors() => _traces
      .where((t) => t.additionalData?[TraceKeys.success] == false)
      .toList();

  List<ISpectLogData> slow() =>
      _traces.where((t) => t.additionalData?[TraceKeys.slow] == true).toList();

  List<ISpectLogData> byLogLevel(LogLevel level) =>
      _traces.where((t) => t.logLevel == level).toList();

  // ── Convenience last-accessors ─────────────────────────────────────

  ISpectLogData? lastByCategory(String category) {
    final list = byCategory(category);
    return list.isEmpty ? null : list.last;
  }

  ISpectLogData? get lastTrace => _queue.isEmpty ? null : _queue.last;

  // ── Lifecycle ──────────────────────────────────────────────────────

  void reset() => _queue.clear();
}
