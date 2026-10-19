import 'dart:convert';

import 'package:ispectify/ispectify.dart';

/// Thrown when a [LogQuery] argument cannot be answered, with a message that
/// tells the caller how to correct the request.
final class InvalidLogQuery implements Exception {
  const InvalidLogQuery(this.message);

  final String message;

  @override
  String toString() => 'InvalidLogQuery: $message';
}

/// Read-only queries over the history of one [ISpectLogger].
///
/// Results are JSON-encodable maps. Every log record is projected from
/// [LogExporter.toJsonLines], so results carry its redaction and size limits.
final class LogQuery {
  const LogQuery(this._logger);

  final ISpectLogger _logger;

  static const _recentErrorCount = 5;
  static const _topKeyCount = 20;
  static const _maxTextBytes = 512;
  static const _maxFieldBytes = 256;
  static const _compactTraceFields = [
    TraceKeys.category,
    TraceKeys.source,
    TraceKeys.operation,
    TraceKeys.target,
    TraceKeys.durationMs,
    TraceKeys.success,
    TraceKeys.correlationId,
    TraceKeys.transactionId,
  ];

  DiagnosticResourceLimits get _limits => _logger.options.resourceLimits;

  Map<String, Object?> summary({required int protocolVersion}) {
    final history = _logger.history;
    final redactor = _redactor();
    final levels = <String, int>{};
    final rawKeys = <String, int>{};
    final recentErrors = <ISpectLogData>[];
    var errorCount = 0;
    for (final log in history) {
      final captured = captureISpectLogWithoutPayload(log);
      final level = captured.logLevel;
      if (level != null) {
        levels.update(level.name, (count) => count + 1, ifAbsent: () => 1);
      }
      if (log.isError) errorCount++;
      final key = captured.key;
      if (key != null) {
        rawKeys.update(key, (count) => count + 1, ifAbsent: () => 1);
      }
    }
    for (final log in history.reversed) {
      if (recentErrors.length == _recentErrorCount) break;
      if (log.isError) recentErrors.add(log);
    }

    final keys = <String, int>{};
    for (final entry in rawKeys.entries) {
      keys.update(
        _safeKey(entry.key, redactor),
        (count) => count + entry.value,
        ifAbsent: () => entry.value,
      );
    }
    final topKeys = keys.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return {
      'protocolVersion': protocolVersion,
      'entries': history.length,
      'capacity': _logger.options.maxHistoryItems,
      if (history.isNotEmpty) ...{
        'firstTime': _time(history.first),
        'lastTime': _time(history.last),
      },
      'levels': levels,
      'errorCount': errorCount,
      'topKeys': {
        for (final entry in topKeys.take(_topKeyCount)) entry.key: entry.value,
      },
      'recentErrors': [for (final log in recentErrors.reversed) _compact(log)],
    };
  }

  /// Throws [InvalidLogQuery] when both cursors are set or a cursor entry
  /// left the history.
  Map<String, Object?> logs({
    required int limit,
    LogLevel? minLevel,
    Set<String> keys = const {},
    String? query,
    String? afterId,
    String? beforeId,
  }) {
    if (afterId != null && beforeId != null) {
      throw const InvalidLogQuery(
        'Pass afterId to page forward or beforeId to page back, not both.',
      );
    }
    final filters = <Filter<ISpectLogData>>[
      if (minLevel != null) _MinLevelFilter(minLevel),
      if (keys.isNotEmpty) LogTypeKeyFilter.fromSet(keys),
      if (query != null && query.isNotEmpty)
        SearchFilter(query, resourceLimits: _limits),
    ];
    bool matches(ISpectLogData log) => filters.every((f) => f.apply(log));

    final history = _logger.history;
    final List<ISpectLogData> page;
    final bool hasMore;
    if (afterId != null) {
      final start = _indexOf(history, afterId, 'afterId');
      (page, hasMore) = _take(history.skip(start + 1), matches, limit);
    } else {
      final end = beforeId == null
          ? history.length
          : _indexOf(history, beforeId, 'beforeId');
      final (newestFirst, more) = _take(
        history.sublist(0, end).reversed,
        matches,
        limit,
      );
      page = newestFirst.reversed.toList();
      hasMore = more;
    }

    final cursorLog =
        afterId != null && hasMore ? page.last : history.lastOrNull;
    return {
      'logs': [for (final log in page) _compact(log)],
      'hasMore': hasMore,
      if (cursorLog != null) 'cursor': _id(cursorLog),
    };
  }

  /// Throws [InvalidLogQuery] when no entry with [id] is in the history.
  Map<String, Object?> log(String id) {
    final history = _logger.history;
    final index = history.lastIndexWhere((log) => _id(log) == id);
    if (index < 0) {
      throw InvalidLogQuery(
        'No log with id $id in history; '
        'take ids from getLogs, getTrace, or getSummary.',
      );
    }
    final log = history[index];
    return {
      if (captureISpectLogWithoutPayload(log).logLevel case final level?)
        'level': level.name,
      'log': _redactedRecord(log),
    };
  }

  Map<String, Object?> trace(String id, {required int limit}) {
    final correlation = CorrelationFilter(id);
    final transaction = TransactionFilter(id);
    final (page, hasMore) = _take(
      _logger.history,
      (log) => correlation.apply(log) || transaction.apply(log),
      limit,
    );
    return {
      'logs': [for (final log in page) _compact(log)],
      'hasMore': hasMore,
    };
  }

  Map<String, Object?> _compact(ISpectLogData log) {
    final record = _redactedRecord(log);
    final data = record['additional-data'];
    final failure = record['exception'] ?? record['error'];
    return {
      'id': _id(log),
      'time': _time(log),
      if (captureISpectLogWithoutPayload(log).logLevel case final level?)
        'level': level.name,
      if (record['key'] case final String key)
        'key': _truncate(key, _maxFieldBytes),
      if (record['message'] case final String message)
        'message': _truncate(message, _maxTextBytes),
      if (failure is String) 'error': _truncate(failure, _maxTextBytes),
      if (record['export-error'] case final String exportError)
        'exportError': exportError,
      if (data is Map<String, Object?>)
        for (final field in _compactTraceFields)
          if (_scalar(data[field]) case final value?) field: value,
    };
  }

  Map<String, Object?> _redactedRecord(ISpectLogData log) {
    final line = LogExporter.toJsonLines(
      [log],
      maxLogs: 1,
      resourceLimits: _limits,
    );
    final decoded = jsonDecode(line);
    return decoded is Map<String, Object?> ? decoded : const {};
  }

  String _safeKey(String key, RedactionService? redactor) {
    final bounded = _truncate(key, _maxFieldBytes);
    if (redactor == null) return bounded;
    final redacted = redactor.redactEnvelopeForExport(
      {'key': bounded},
      rootValueKeys: const {'key'},
      resourceLimits: _limits,
    );
    return switch (redacted) {
      {'key': final String value} => value,
      _ => defaultPlaceholder,
    };
  }

  static int _indexOf(List<ISpectLogData> history, String id, String name) {
    final index = history.lastIndexWhere((log) => _id(log) == id);
    if (index < 0) {
      throw InvalidLogQuery(
        '$name $id is no longer in history (evicted or cleared); '
        'call getLogs without $name to restart from the newest logs.',
      );
    }
    return index;
  }

  static (List<ISpectLogData>, bool) _take(
    Iterable<ISpectLogData> candidates,
    bool Function(ISpectLogData log) matches,
    int limit,
  ) {
    final page = <ISpectLogData>[];
    for (final log in candidates) {
      if (!matches(log)) continue;
      if (page.length == limit) return (page, true);
      page.add(log);
    }
    return (page, false);
  }

  static Object? _scalar(Object? value) => switch (value) {
        final String text => _truncate(text, _maxFieldBytes),
        final num number => number,
        final bool flag => flag,
        _ => null,
      };

  static RedactionService? _redactor() =>
      ISpectRedaction.enabled ? ISpectRedaction.resolveService() : null;

  static String _id(ISpectLogData log) => captureISpectLogDataForEgress(log).id;

  static String _time(ISpectLogData log) =>
      captureISpectLogWithoutPayload(log).time.toIso8601String();

  static String _truncate(String value, int maxBytes) =>
      LogExportOutput.truncateUtf8(value, maxBytes: maxBytes);
}

final class _MinLevelFilter implements Filter<ISpectLogData> {
  const _MinLevelFilter(this.minLevel);

  final LogLevel minLevel;

  @override
  bool apply(ISpectLogData item) {
    final level = captureISpectLogWithoutPayload(item).logLevel;
    return level != null && level.index <= minLevel.index;
  }
}
