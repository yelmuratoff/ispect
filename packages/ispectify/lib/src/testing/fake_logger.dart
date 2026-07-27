import 'dart:collection';

import 'package:ispectify/src/history/history.dart';
import 'package:ispectify/src/ispectify.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/log_level.dart';
import 'package:ispectify/src/options.dart';
import 'package:ispectify/src/trace/trace_keys.dart';

/// Test double for [ISpectLogger]. Captures all logs for assertions.
///
/// Uses [Queue] (O(1) removeFirst) for FIFO rotation with [maxTraces].
class FakeISpectLogger extends ISpectLogger {
  factory FakeISpectLogger({
    int maxTraces = 10000,
  }) {
    final history = _FakeLogHistory(maxTraces);
    return FakeISpectLogger._(maxTraces, history);
  }

  FakeISpectLogger._(
    this.maxTraces,
    this._captureHistory,
  ) : super.testing(
          options: ISpectLoggerOptions(
            useConsoleLogs: false,
            maxHistoryItems: maxTraces,
          ),
          history: _captureHistory,
        );

  final int maxTraces;
  final _FakeLogHistory _captureHistory;

  /// Read-only snapshot as List.
  List<ISpectLogData> get traces => _captureHistory.history;

  Iterable<ISpectLogData> get _traces => _captureHistory.history;

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

  List<ISpectLogData> errors() => _traces.where((t) => t.isError).toList();

  List<ISpectLogData> slow() =>
      _traces.where((t) => t.additionalData?[TraceKeys.slow] == true).toList();

  List<ISpectLogData> byLogLevel(LogLevel level) =>
      _traces.where((t) => t.logLevel == level).toList();

  // ── Convenience last-accessors ─────────────────────────────────────

  ISpectLogData? lastByCategory(String category) {
    final list = byCategory(category);
    return list.isEmpty ? null : list.last;
  }

  ISpectLogData? get lastTrace =>
      _captureHistory.history.isEmpty ? null : _captureHistory.history.last;

  // ── Lifecycle ──────────────────────────────────────────────────────

  void reset() => _captureHistory.clear();
}

final class _FakeLogHistory implements ILogHistory {
  _FakeLogHistory(this.capacity) {
    if (capacity < 0) {
      throw RangeError.range(capacity, 0, null, 'capacity');
    }
  }

  final int capacity;
  final Queue<ISpectLogData> _entries = Queue<ISpectLogData>();

  @override
  List<ISpectLogData> get history => List<ISpectLogData>.unmodifiable(_entries);

  @override
  void add(ISpectLogData data) {
    if (capacity == 0) return;
    while (_entries.length >= capacity) {
      _entries.removeFirst();
    }
    _entries.addLast(data);
  }

  @override
  void clear() => _entries.clear();

  @override
  void dispose() => _entries.clear();
}
