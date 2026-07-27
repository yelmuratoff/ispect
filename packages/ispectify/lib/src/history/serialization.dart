import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/logger/log_parts.dart';
import 'package:ispectify/src/utils/safe_object_description.dart';

/// Shared byte limits for outbound log documents.
///
/// Limits are measured after UTF-8 encoding. The prepared-value limit keeps a
/// single redaction pass from expanding an arbitrarily large diagnostic tree,
/// the record limit bounds one encoded entry, and the document limit bounds
/// the final in-memory export.
abstract final class LogExportOutput {
  /// Maximum UTF-8 bytes retained while preparing one structured value.
  static const int maxPreparedValueBytes = 256 * 1024;

  /// Maximum UTF-8 bytes emitted for one log entry.
  static const int maxRecordBytes = 1024 * 1024;

  /// Maximum UTF-8 bytes emitted for one complete export.
  static const int maxDocumentBytes = 32 * 1024 * 1024;

  /// Marker used when diagnostic content exceeds an outbound byte budget.
  static const String truncatedMarker = '<export-output-truncated>';

  /// Returns the UTF-8 byte length of [value].
  ///
  /// When [limit] is supplied, scanning stops as soon as the result exceeds
  /// that limit.
  static int utf8Length(String value, {int? limit}) {
    var bytes = 0;
    for (var index = 0; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      if (codeUnit <= 0x7f) {
        bytes++;
      } else if (codeUnit <= 0x7ff) {
        bytes += 2;
      } else if (_isHighSurrogate(codeUnit) &&
          index + 1 < value.length &&
          _isLowSurrogate(value.codeUnitAt(index + 1))) {
        bytes += 4;
        index++;
      } else {
        bytes += 3;
      }
      if (limit != null && bytes > limit) return bytes;
    }
    return bytes;
  }

  /// Truncates [value] without splitting a Unicode scalar.
  ///
  /// The returned string, including [marker], never exceeds [maxBytes].
  static String truncateUtf8(
    String value, {
    required int maxBytes,
    String marker = truncatedMarker,
  }) {
    if (maxBytes < 0) {
      throw RangeError.range(maxBytes, 0, null, 'maxBytes');
    }
    if (maxBytes == 0) return '';
    if (utf8Length(value, limit: maxBytes) <= maxBytes) return value;

    final safeMarker = _prefixWithinBytes(marker, maxBytes);
    final markerBytes = utf8Length(safeMarker);
    final prefixBudget = maxBytes - markerBytes;
    if (prefixBudget == 0) return safeMarker;
    final prefixEnd = _prefixEndWithinBytes(value, prefixBudget);
    return '${value.substring(0, prefixEnd)}$safeMarker';
  }

  /// Creates a JSON-safe snapshot with a cumulative string-byte budget.
  ///
  /// Oversized strings are replaced entirely when
  /// [replaceOversizedStrings] is true. This is used before an active
  /// redaction pass so a partial credential cannot escape solely because its
  /// suffix fell beyond the output boundary. Explicit redaction opt-outs keep
  /// a bounded prefix instead.
  static Object? boundJsonValue(
    Object? value, {
    int maxBytes = maxPreparedValueBytes,
    bool preserveTypes = false,
    bool replaceOversizedStrings = false,
    bool stripPrivateKeys = false,
  }) {
    if (maxBytes < 0) {
      throw RangeError.range(maxBytes, 0, null, 'maxBytes');
    }
    return _BoundedJsonSnapshot(
      maxBytes: maxBytes,
      preserveTypes: preserveTypes,
      replaceOversizedStrings: replaceOversizedStrings,
      stripPrivateKeys: stripPrivateKeys,
    ).convert(value);
  }

  static bool _isHighSurrogate(int codeUnit) =>
      codeUnit >= 0xd800 && codeUnit <= 0xdbff;

  static bool _isLowSurrogate(int codeUnit) =>
      codeUnit >= 0xdc00 && codeUnit <= 0xdfff;

  static int _prefixEndWithinBytes(String value, int maxBytes) {
    var bytes = 0;
    var index = 0;
    while (index < value.length) {
      final codeUnit = value.codeUnitAt(index);
      final int width;
      final int codeUnits;
      if (codeUnit <= 0x7f) {
        width = 1;
        codeUnits = 1;
      } else if (codeUnit <= 0x7ff) {
        width = 2;
        codeUnits = 1;
      } else if (_isHighSurrogate(codeUnit) &&
          index + 1 < value.length &&
          _isLowSurrogate(value.codeUnitAt(index + 1))) {
        width = 4;
        codeUnits = 2;
      } else {
        width = 3;
        codeUnits = 1;
      }
      if (bytes + width > maxBytes) break;
      bytes += width;
      index += codeUnits;
    }
    return index;
  }

  static String _prefixWithinBytes(String value, int maxBytes) =>
      value.substring(0, _prefixEndWithinBytes(value, maxBytes));
}

final class _BoundedJsonSnapshot {
  _BoundedJsonSnapshot({
    required int maxBytes,
    required this.preserveTypes,
    required this.replaceOversizedStrings,
    required this.stripPrivateKeys,
  }) : _remainingBytes = maxBytes;

  final bool preserveTypes;
  final bool replaceOversizedStrings;
  final bool stripPrivateKeys;
  final Set<Object> _ancestors = Set<Object>.identity();
  int _remainingBytes;
  int _remainingNodes = JsonValueNormalizer.defaultMaxNodes;

  Object? convert(Object? value, {int depth = 0}) {
    if (_remainingNodes <= 0) {
      return _boundString(JsonValueNormalizer.maxNodesReached);
    }
    _remainingNodes--;
    if (value == null || value is bool) return value;
    if (value is num) {
      return value is double && !value.isFinite
          ? _boundString(safeScalarText(value)!)
          : value;
    }
    if (preserveTypes && value is Type) return value;
    if (preserveTypes && (value is TypedData || value is ByteBuffer)) {
      final byteLength = value is TypedData
          ? value.lengthInBytes
          : (value as ByteBuffer).lengthInBytes;
      if (byteLength > _remainingBytes) {
        return _boundString(binaryPlaceholder(byteLength));
      }
      _remainingBytes -= byteLength;
      return value;
    }
    if (value is String) return _boundString(value);
    if (value is DateTime || value is Uri) {
      return _boundString(JsonValueNormalizer.unprintableValue);
    }
    if (value is Enum) return _boundString(value.name);
    if (value is Error || value is Exception || value is StackTrace) {
      return _boundString(_safeDiagnosticSnapshot(value));
    }
    if (depth >= 64) {
      return _boundString(JsonValueNormalizer.maxDepthReached);
    }
    if (value is Map) return _boundMap(value, depth);
    if (value is Iterable) return _boundIterable(value, depth);
    return _boundString(JsonValueNormalizer.unprintableValue);
  }

  Map<String, Object?> _boundMap(Map<dynamic, dynamic> value, int depth) {
    if (!_ancestors.add(value)) {
      final result = <String, Object?>{};
      _addTraversalMarker(result, JsonValueNormalizer.circularReference);
      return result;
    }
    final result = <String, Object?>{};
    try {
      final Iterator<dynamic> iterator;
      try {
        iterator = value.entries.iterator;
      } catch (_) {
        _addTraversalMarker(result, JsonValueNormalizer.unprintableValue);
        return result;
      }

      var count = 0;
      while (count < JsonValueNormalizer.defaultMaxCollectionItems) {
        if (_remainingBytes <= 0 || _remainingNodes <= 0) {
          _addTraversalMarker(
            result,
            _remainingNodes <= 0
                ? JsonValueNormalizer.maxNodesReached
                : LogExportOutput.truncatedMarker,
          );
          return result;
        }
        final bool hasNext;
        try {
          hasNext = iterator.moveNext();
        } catch (_) {
          _addTraversalMarker(result, JsonValueNormalizer.unprintableValue);
          return result;
        }
        if (!hasNext) return result;

        final dynamic current;
        try {
          current = iterator.current;
        } catch (_) {
          _addTraversalMarker(result, JsonValueNormalizer.unprintableValue);
          return result;
        }
        if (current is! MapEntry<dynamic, dynamic>) {
          _addTraversalMarker(result, JsonValueNormalizer.unprintableValue);
          return result;
        }
        if (current.key is! String) {
          _addTraversalMarker(result, JsonValueNormalizer.unprintableValue);
        } else {
          final originalKey = current.key! as String;
          if (stripPrivateKeys && originalKey.startsWith('_')) {
            count++;
            continue;
          }
          final key = _boundString(originalKey);
          if (replaceOversizedStrings && key != originalKey) {
            if (key.isNotEmpty) {
              result[key] = _takeTruncationMarker();
            }
            return result;
          }
          result[key] = convert(current.value, depth: depth + 1);
        }
        count++;
      }

      try {
        if (iterator.moveNext()) {
          _addTraversalMarker(
            result,
            JsonValueNormalizer.maxCollectionItemsReached,
          );
        }
      } catch (_) {
        _addTraversalMarker(result, JsonValueNormalizer.unprintableValue);
      }
      return result;
    } finally {
      _ancestors.remove(value);
    }
  }

  List<Object?> _boundIterable(Iterable<dynamic> value, int depth) {
    if (!_ancestors.add(value)) {
      return [_boundString(JsonValueNormalizer.circularReference)];
    }
    final result = <Object?>[];
    try {
      final Iterator<dynamic> iterator;
      try {
        iterator = value.iterator;
      } catch (_) {
        return [_boundString(JsonValueNormalizer.unprintableValue)];
      }

      var count = 0;
      while (count < JsonValueNormalizer.defaultMaxCollectionItems) {
        if (_remainingBytes <= 0 || _remainingNodes <= 0) {
          result.add(
            _boundString(
              _remainingNodes <= 0
                  ? JsonValueNormalizer.maxNodesReached
                  : LogExportOutput.truncatedMarker,
            ),
          );
          return result;
        }
        final bool hasNext;
        try {
          hasNext = iterator.moveNext();
        } catch (_) {
          result.add(_boundString(JsonValueNormalizer.unprintableValue));
          return result;
        }
        if (!hasNext) return result;

        final dynamic current;
        try {
          current = iterator.current;
        } catch (_) {
          result.add(_boundString(JsonValueNormalizer.unprintableValue));
          return result;
        }
        result.add(convert(current, depth: depth + 1));
        count++;
      }

      try {
        if (iterator.moveNext()) {
          result.add(
            _boundString(JsonValueNormalizer.maxCollectionItemsReached),
          );
        }
      } catch (_) {
        result.add(_boundString(JsonValueNormalizer.unprintableValue));
      }
      return result;
    } finally {
      _ancestors.remove(value);
    }
  }

  String _boundString(String value) {
    if (_remainingBytes <= 0) return '';
    final valueBytes = LogExportOutput.utf8Length(
      value,
      limit: _remainingBytes,
    );
    if (valueBytes <= _remainingBytes) {
      _remainingBytes -= valueBytes;
      return value;
    }

    if (replaceOversizedStrings) {
      return _takeTruncationMarker();
    }
    final bounded = LogExportOutput.truncateUtf8(
      value,
      maxBytes: _remainingBytes,
    );
    _remainingBytes -= LogExportOutput.utf8Length(bounded);
    return bounded;
  }

  void _addTraversalMarker(Map<String, Object?> result, String marker) {
    final key = _boundString(JsonValueNormalizer.traversalMarkerKey);
    result[key] = _boundString(marker);
  }

  String _takeTruncationMarker() {
    if (_remainingBytes <= 0) return '';
    final marker = LogExportOutput.truncateUtf8(
      LogExportOutput.truncatedMarker,
      maxBytes: _remainingBytes,
      marker: '',
    );
    _remainingBytes -= LogExportOutput.utf8Length(marker);
    return marker;
  }

  static String _safeDiagnosticSnapshot(Object value) =>
      safeDiagnosticDescriptor(value);
}

/// Extension for ISpectLogData to add serialization support.
extension ISpectLogDataSerialization on ISpectLogData {
  /// Converts the log data into a JSON representation.
  ///
  /// Omits `null` values for a cleaner output. Recursively strips private
  /// presentation hints (keys starting with `_`, by convention) such as the
  /// network renderer's `_render-hints` — these are an internal contract
  /// between log producers and the console renderer and have no place in
  /// exported, shared, or persisted output.
  ///
  /// The snapshot is bounded and never invokes caller-supplied `toJson` or
  /// `toString` implementations. [preserveTypes] is reserved for an in-memory
  /// redaction pass before final JSON encoding and keeps typed binary values
  /// recognizable by the redactor.
  Map<String, dynamic> toJson({
    bool truncated = false,
    bool preserveTypes = false,
  }) =>
      _toJsonSnapshot(
        truncated: truncated,
        preserveTypes: preserveTypes,
      );

  /// Creates a bounded, non-executing snapshot for an outbound export.
  ///
  /// [redactionActive] retains typed binary values for the redactor and
  /// replaces oversized strings before redaction so a partial credential
  /// cannot cross the output boundary. [truncated] applies the legacy
  /// short-field presentation after the safe snapshot is created.
  Map<String, dynamic> toExportJson({
    required bool redactionActive,
    bool truncated = false,
  }) =>
      _toJsonSnapshot(
        truncated: truncated,
        preserveTypes: redactionActive,
        replaceOversizedStrings: redactionActive,
      );

  Map<String, dynamic> _toJsonSnapshot({
    bool truncated = false,
    bool preserveTypes = false,
    bool replaceOversizedStrings = false,
  }) {
    final captured = captureISpectLogDataForEgress(this);
    final raw = <String, Object?>{
      // Retain the trusted required timestamp before caller-controlled fields
      // can exhaust the cumulative preparation budget.
      'time': captured.time.toIso8601String(),
      'id': captured.id,
      if (captured.key != null) 'key': captured.key,
      if (captured.logLevel != null)
        'log-level': captured.logLevel!.index.toString(),
      if (captured.message != null) 'message': captured.message,
      if (captured.exceptionText != null) 'exception': captured.exceptionText,
      if (captured.errorText != null) 'error': captured.errorText,
      if (captured.stackTraceText != null)
        'stack-trace': captured.stackTraceText,
      if (captured.additionalData != null)
        'additional-data': captured.additionalData,
    };
    final normalized = LogExportOutput.boundJsonValue(
      raw,
      preserveTypes: preserveTypes,
      replaceOversizedStrings: replaceOversizedStrings,
      stripPrivateKeys: true,
    );
    final result = normalized is Map<String, Object?>
        ? Map<String, dynamic>.from(normalized)
        : <String, dynamic>{};
    if (result['additional-data'] case final Map<Object?, Object?> data) {
      result['additional-data'] = _stripPrivateMap(data);
    }
    if (truncated) {
      for (final key in const [
        'message',
        'exception',
        'error',
        'stack-trace',
      ]) {
        if (result[key] case final String value) {
          result[key] = value.truncate();
        }
      }
    }
    return result;
  }

  /// Message-oriented text for clipboard and other outbound UI actions.
  ///
  /// Includes the message, error, exception, and stack trace in the same order
  /// as [ISpectLogData.textMessage], while retaining typed binary provenance
  /// until the redaction pass.
  String toExportMessageText({
    Set<String>? redactKeys,
    RedactionService? redactionService,
    bool enableRedaction = true,
    int maxOutputBytes = LogExportOutput.maxRecordBytes,
  }) {
    final captured = captureISpectLogDataForEgress(this);
    final outputBudget = _effectiveRecordBudget(maxOutputBytes);
    final preparedValueBytes = _preparedValueBudget(outputBudget);
    String? safePart(Object? value) => value == null
        ? null
        : _redactExportText(
            value,
            redactKeys,
            redactionService: redactionService,
            enableRedaction: enableRedaction,
            maxBytes: preparedValueBytes,
          ).truncate();

    final safeStack = captured.stackTraceText != null &&
            !identical(captured.stackTrace, StackTrace.empty)
        ? 'StackTrace: ${safePart(captured.stackTraceText)}'.truncate()
        : null;
    return _boundOutput(
      joinLogParts([
        safePart(captured.message),
        safePart(captured.errorText),
        safePart(captured.exceptionText),
        safeStack,
      ]),
      outputBudget,
    );
  }

  /// Plain text — for sharing, copying, human reading.
  ///
  /// Redaction is enabled by default. Pass [enableRedaction] as `false` only
  /// for a deliberate local-debugging export. A null or empty [redactKeys]
  /// uses the library's default sensitive-key set. When supplied,
  /// [redactionService] takes precedence over [redactKeys].
  ///
  /// Output is capped at [LogExportOutput.maxRecordBytes] by default.
  /// [maxOutputBytes] may request a smaller cap.
  String toText({
    Set<String>? redactKeys,
    RedactionService? redactionService,
    bool enableRedaction = true,
    int? maxOutputBytes,
  }) {
    final captured = captureISpectLogDataForEgress(this);
    final outputBudget = _effectiveRecordBudget(maxOutputBytes);
    final preparedValueBytes = _preparedValueBudget(outputBudget);
    final safeMessage = _redactExportText(
      captured.message,
      redactKeys,
      redactionService: redactionService,
      enableRedaction: enableRedaction,
      maxBytes: preparedValueBytes,
    );
    final safeKey = captured.key == null
        ? 'null'
        : _redactExportText(
            captured.key,
            redactKeys,
            redactionService: redactionService,
            enableRedaction: enableRedaction,
            maxBytes: preparedValueBytes,
          );
    final buffer = StringBuffer()
      ..writeln(
        '[${ISpectDateTimeFormatter(captured.time).defaultFormat}] '
        '[$safeKey] $safeMessage',
      );

    if (captured.additionalData case final additionalData?
        when additionalData.isNotEmpty) {
      final sanitized = _redactAdditionalData(
        additionalData,
        redactKeys,
        redactionService: redactionService,
        enableRedaction: enableRedaction,
        maxBytes: preparedValueBytes,
      );
      for (final entry in sanitized.entries) {
        // Skip TraceKeys.error — raw error string may contain PII.
        // Error info printed below in dedicated section with Layer 3 redaction.
        if (entry.key == TraceKeys.error) continue;

        final value = entry.value;
        if (value is Map || value is List) {
          try {
            final json = const JsonEncoder.withIndent('  ').convert(value);
            buffer.writeln('  ${entry.key}: $json');
          } catch (_) {
            buffer.writeln('  ${entry.key}: $value');
          }
        } else {
          buffer.writeln('  ${entry.key}: $value');
        }
      }
    }

    if (captured.exceptionText != null) {
      buffer.writeln(
        '  Exception: ${_redactExportText(
          captured.exceptionText,
          redactKeys,
          redactionService: redactionService,
          enableRedaction: enableRedaction,
          maxBytes: preparedValueBytes,
        )}',
      );
    }
    if (captured.errorText != null) {
      buffer.writeln(
        '  Error: ${_redactExportText(
          captured.errorText,
          redactKeys,
          redactionService: redactionService,
          enableRedaction: enableRedaction,
          maxBytes: preparedValueBytes,
        )}',
      );
    }
    if (captured.stackTraceText != null) {
      final traceStr = _redactExportText(
        captured.stackTraceText,
        redactKeys,
        redactionService: redactionService,
        enableRedaction: enableRedaction,
        maxBytes: preparedValueBytes,
      );
      buffer.writeln('  StackTrace:\n$traceStr');
    }

    return _boundOutput(buffer.toString(), outputBudget);
  }

  /// Markdown — for issue trackers, documentation.
  ///
  /// Redaction is enabled by default. Pass [enableRedaction] as `false` only
  /// for a deliberate local-debugging export. A null or empty [redactKeys]
  /// uses the library's default sensitive-key set. When supplied,
  /// [redactionService] takes precedence over [redactKeys].
  ///
  /// Output is capped at [LogExportOutput.maxRecordBytes] by default.
  /// [maxOutputBytes] may request a smaller cap. Truncated output never leaves
  /// an emitted fenced code block open.
  String toMarkdown({
    Set<String>? redactKeys,
    RedactionService? redactionService,
    bool enableRedaction = true,
    int? maxOutputBytes,
  }) {
    final captured = captureISpectLogDataForEgress(this);
    final outputBudget = _effectiveRecordBudget(maxOutputBytes);
    final preparedValueBytes = _preparedValueBudget(outputBudget);
    final safeMessage = _redactExportText(
      captured.message,
      redactKeys,
      redactionService: redactionService,
      enableRedaction: enableRedaction,
      maxBytes: preparedValueBytes,
    );
    final safeKey = captured.key == null
        ? 'null'
        : _redactExportText(
            captured.key,
            redactKeys,
            redactionService: redactionService,
            enableRedaction: enableRedaction,
            maxBytes: preparedValueBytes,
          );
    final safeAdditionalData = captured.additionalData == null
        ? null
        : _redactAdditionalData(
            captured.additionalData!,
            redactKeys,
            redactionService: redactionService,
            enableRedaction: enableRedaction,
            maxBytes: preparedValueBytes,
          );
    final buffer = StringBuffer()
      ..writeln(
        '### ${_logLevelIndicator(captured.logLevel)} '
        '`${_markdownText(safeKey)}` — ${_markdownText(safeMessage)}',
      )
      ..writeln()
      ..writeln('| Field | Value |')
      ..writeln('|-------|-------|')
      ..writeln(
        '| Time | '
        '`${ISpectDateTimeFormatter(captured.time).defaultFormat}` |',
      )
      ..writeln('| Level | `${captured.logLevel?.name ?? 'unknown'}` |');

    if (safeAdditionalData != null) {
      final category = safeAdditionalData[TraceKeys.category];
      final source = safeAdditionalData[TraceKeys.source];
      final operation = safeAdditionalData[TraceKeys.operation];
      final duration = safeAdditionalData[TraceKeys.durationMs];

      if (category != null) {
        buffer.writeln('| Category | `${_markdownText(category)}` |');
      }
      if (source != null) {
        buffer.writeln('| Source | `${_markdownText(source)}` |');
      }
      if (operation != null) {
        buffer.writeln('| Operation | `${_markdownText(operation)}` |');
      }
      if (duration != null) {
        buffer.writeln('| Duration | `${_markdownText(duration)}ms` |');
      }
    }

    if (safeAdditionalData != null && safeAdditionalData.isNotEmpty) {
      final safeData = Map<String, dynamic>.from(safeAdditionalData)
        ..remove(TraceKeys.error);
      if (safeData.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('**Details:**')
          ..writeln('```json');
        try {
          final json = const JsonEncoder.withIndent('  ').convert(safeData);
          buffer.writeln(json.replaceAll('`', r'\u0060'));
        } catch (_) {
          buffer.writeln(JsonValueNormalizer.unprintableValue);
        }
        buffer.writeln('```');
      }
    }

    if (captured.exceptionText != null) {
      buffer.writeln(
        '\n**Exception:** `${_markdownText(
          _redactExportText(
            captured.exceptionText,
            redactKeys,
            redactionService: redactionService,
            enableRedaction: enableRedaction,
            maxBytes: preparedValueBytes,
          ),
        )}`',
      );
    }
    if (captured.errorText != null) {
      buffer.writeln(
        '\n**Error:** `${_markdownText(
          _redactExportText(
            captured.errorText,
            redactKeys,
            redactionService: redactionService,
            enableRedaction: enableRedaction,
            maxBytes: preparedValueBytes,
          ),
        )}`',
      );
    }
    if (captured.stackTraceText != null) {
      final traceStr = _redactExportText(
        captured.stackTraceText,
        redactKeys,
        redactionService: redactionService,
        enableRedaction: enableRedaction,
        maxBytes: preparedValueBytes,
      );
      buffer.writeln(
        '\n**Stack trace:**\n```\n'
        '${traceStr.replaceAll('`', r'\u0060')}\n```',
      );
    }

    return _boundMarkdownOutput(buffer.toString(), outputBudget);
  }

  String _logLevelIndicator(LogLevel? level) => switch (level) {
        LogLevel.error || LogLevel.critical => '[ERROR]',
        LogLevel.warning => '[WARN]',
        LogLevel.info => '[INFO]',
        LogLevel.debug => '[DEBUG]',
        _ => '[-]',
      };
}

String _redactExportText(
  Object? value,
  Set<String>? redactKeys, {
  required RedactionService? redactionService,
  required bool enableRedaction,
  int? maxBytes,
}) {
  final redactionActive = enableRedaction && ISpectRedaction.enabled;
  final prepared = maxBytes == null
      ? value
      : LogExportOutput.boundJsonValue(
          value,
          maxBytes: maxBytes,
          preserveTypes: redactionActive,
          replaceOversizedStrings: redactionActive,
        );
  final outbound = redactionActive
      ? _exportRedactor(redactKeys, redactionService).redactForExport(prepared)
      : prepared;
  final bounded = maxBytes == null
      ? outbound
      : LogExportOutput.boundJsonValue(
          outbound,
          maxBytes: maxBytes,
          replaceOversizedStrings: redactionActive,
        );
  final text = _normalizedText(bounded);
  return maxBytes == null
      ? text
      : LogExportOutput.truncateUtf8(text, maxBytes: maxBytes);
}

/// Key+pattern-redacts [data] via [RedactionService] so secrets nested in
/// additionalData never reach text / markdown export.
Map<String, dynamic> _redactAdditionalData(
  Map<String, dynamic> data,
  Set<String>? redactKeys, {
  required RedactionService? redactionService,
  required bool enableRedaction,
  int? maxBytes,
}) {
  final redactionActive = enableRedaction && ISpectRedaction.enabled;
  final prepared = maxBytes == null
      ? data
      : LogExportOutput.boundJsonValue(
          data,
          maxBytes: maxBytes,
          preserveTypes: redactionActive,
          replaceOversizedStrings: redactionActive,
          stripPrivateKeys: true,
        );
  final normalized = prepared is Map<String, dynamic>
      ? _stripPrivateKeys(
          prepared,
          preserveTypes: redactionActive,
        )
      : <String, dynamic>{};
  final outbound = redactionActive
      ? _exportRedactor(redactKeys, redactionService)
          .redactForExport(normalized)
      : normalized;
  final safe = maxBytes == null
      ? JsonValueNormalizer.normalize(outbound)
      : LogExportOutput.boundJsonValue(
          outbound,
          maxBytes: maxBytes,
          replaceOversizedStrings: redactionActive,
          stripPrivateKeys: true,
        );
  return safe is Map<String, Object?>
      ? Map<String, dynamic>.from(safe)
      : <String, dynamic>{};
}

int _effectiveRecordBudget(int? requestedBytes) {
  if (requestedBytes == null) return LogExportOutput.maxRecordBytes;
  if (requestedBytes < 0) {
    throw RangeError.range(requestedBytes, 0, null, 'maxOutputBytes');
  }
  return requestedBytes < LogExportOutput.maxRecordBytes
      ? requestedBytes
      : LogExportOutput.maxRecordBytes;
}

int _preparedValueBudget(int outputBytes) =>
    outputBytes < LogExportOutput.maxPreparedValueBytes
        ? outputBytes
        : LogExportOutput.maxPreparedValueBytes;

String _boundOutput(String value, int maxOutputBytes) =>
    LogExportOutput.truncateUtf8(value, maxBytes: maxOutputBytes);

String _boundMarkdownOutput(String value, int maxOutputBytes) {
  if (LogExportOutput.utf8Length(value, limit: maxOutputBytes) <=
      maxOutputBytes) {
    return value;
  }

  final marker = LogExportOutput.truncateUtf8(
    '\n${LogExportOutput.truncatedMarker}\n',
    maxBytes: maxOutputBytes,
    marker: '',
  );
  final remainingBytes = maxOutputBytes - LogExportOutput.utf8Length(marker);
  const closingFence = '\n```\n';
  final closingFenceBytes = LogExportOutput.utf8Length(closingFence);
  if (remainingBytes <= closingFenceBytes) return marker;

  var prefix = LogExportOutput.truncateUtf8(
    value,
    maxBytes: remainingBytes - closingFenceBytes,
    marker: '',
  );
  while (prefix.endsWith('`')) {
    prefix = prefix.substring(0, prefix.length - 1);
  }
  final hasOpenFence = RegExp('```').allMatches(prefix).length.isOdd;
  return '$prefix$marker${hasOpenFence ? closingFence : ''}';
}

String _markdownText(Object? value) {
  final escaped = _normalizedText(value)
      .replaceAll(RegExp(r'[\r\n\u2028\u2029]+'), ' ')
      .replaceAll(r'\', r'\\')
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('@', '&#64;')
      .replaceAll('`', '&#96;')
      .replaceAll('|', r'\|')
      .replaceAll('!', r'\!')
      .replaceAll('[', r'\[')
      .replaceAll(']', r'\]')
      .replaceAll('(', r'\(')
      .replaceAll(')', r'\)');
  return escaped
      .replaceAll(r'\[REDACTED\]', defaultPlaceholder)
      .replaceAll('&lt;redaction-failed&gt;', redactionFailedPlaceholder)
      .replaceAll(
        '&lt;export-output-truncated&gt;',
        LogExportOutput.truncatedMarker,
      );
}

RedactionService _exportRedactor(
  Set<String>? redactKeys,
  RedactionService? redactionService,
) =>
    ISpectRedaction.resolveService(
      service: redactionService,
      sensitiveKeys: redactKeys,
    );

String _normalizedText(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is bool || value is num) return value.toString();
  if (value is List<Object?> && value.length <= 128) {
    final bytes = <int>[];
    for (final element in value) {
      if (element is! int || element < 0 || element > 255) {
        bytes.clear();
        break;
      }
      bytes.add(element);
    }
    if (bytes.isNotEmpty) {
      try {
        final decoded = utf8.decode(bytes);
        if (_binaryPlaceholderTextPattern.hasMatch(decoded)) return decoded;
      } on FormatException {
        // Fall through to normalized JSON text.
      }
    }
  }
  try {
    return jsonEncode(JsonValueNormalizer.normalize(value));
  } catch (_) {
    return defaultPlaceholder;
  }
}

final RegExp _binaryPlaceholderTextPattern = RegExp(r'^\[binary \d+ bytes\]$');

/// Recursively drops `_`-prefixed keys from [data] and any nested maps.
/// Keeps internal presentation hints (e.g. the network renderer's
/// `_render-hints`) out of exported JSON / text / markdown — those keys are
/// a private contract between log producers and the console renderer.
Map<String, dynamic> _stripPrivateKeys(
  Map<String, dynamic> data, {
  bool preserveTypes = false,
}) {
  final normalized = JsonValueNormalizer.normalize(
    data,
    preserveTypes: preserveTypes,
  );
  return normalized is Map<String, Object?>
      ? _stripPrivateMap(normalized)
      : <String, dynamic>{};
}

Map<String, dynamic> _stripPrivateMap(Map<Object?, Object?> data) {
  final out = <String, dynamic>{};
  for (final entry in data.entries) {
    final key = entry.key is String
        ? entry.key! as String
        : JsonValueNormalizer.unprintableValue;
    if (key.startsWith('_')) continue;
    out[key] = _stripPrivateValue(entry.value);
  }
  return out;
}

/// Recurses into maps and lists so `_`-prefixed keys are stripped even when
/// nested inside a list element.
Object? _stripPrivateValue(Object? value) {
  if (value is Map<Object?, Object?>) return _stripPrivateMap(value);
  if (value is TypedData || value is ByteBuffer) return value;
  if (value is List<Object?>) {
    return value.map(_stripPrivateValue).toList(growable: false);
  }
  return value;
}

/// Utility class for ISpectLogData JSON operations.
class ISpectLogDataJsonUtils {
  /// Creates ISpectLogData from JSON Map.
  ///
  /// Throws [FormatException] if the JSON is missing required fields
  /// (`message` or `time`).
  ///
  /// **Lossy reconstruction:** Exception and Error are wrapped in lightweight
  /// string wrappers ([_StringException], [_StringError]) and StackTrace is
  /// rebuilt from its string form. Original type information, file/line data,
  /// and causal chains are lost. Treat deserialized entries as display-only
  /// snapshots, not as re-throwable originals.
  static ISpectLogData fromJson(Map<String, dynamic> json) {
    final bounded = LogExportOutput.boundJsonValue(
      json,
      maxBytes: LogExportOutput.maxRecordBytes,
      replaceOversizedStrings: true,
    );
    if (bounded is! Map<String, Object?>) {
      throw const FormatException('Invalid log entry: expected an object');
    }
    if (!bounded.containsKey('message') && !bounded.containsKey('time')) {
      throw const FormatException(
        'Invalid log entry: missing both "message" and "time" fields',
      );
    }

    final message = _jsonScalarText(bounded['message']);
    final time = _jsonScalarText(bounded['time']);
    final logLevel = _jsonScalarText(bounded['log-level']);
    final key = _jsonScalarText(bounded['key']);
    final exception = _jsonScalarText(bounded['exception']);
    final error = _jsonScalarText(bounded['error']);
    final stackTrace = _jsonScalarText(bounded['stack-trace']);
    final id = _jsonScalarText(bounded['id']);
    final rawAdditionalData = bounded['additional-data'];

    return ISpectLogData(
      message,
      time: DateTime.tryParse(time ?? '') ?? DateTime.now(),
      logLevel: _parseLogLevel(logLevel),
      key: key,
      additionalData: rawAdditionalData is Map<String, Object?>
          ? Map<String, dynamic>.from(rawAdditionalData)
          : null,
      // Note: These are reconstructed as strings for JSON compatibility
      exception: exception == null ? null : _StringException(exception),
      error: error == null ? null : _StringError(error),
      stackTrace: stackTrace == null ? null : StackTrace.fromString(stackTrace),
      id: id,
    );
  }
}

String? _jsonScalarText(Object? value) => switch (value) {
      null => null,
      final String text => text,
      final bool primitive => primitive.toString(),
      final num primitive when primitive is! double || primitive.isFinite =>
        primitive.toString(),
      _ => null,
    };

LogLevel? _parseLogLevel(String? value) {
  if (value == null) return null;
  final index = int.tryParse(value);
  if (index == null || index < 0 || index >= LogLevel.values.length) {
    return null;
  }
  return LogLevel.values[index];
}

/// Helper class to represent exceptions deserialized from JSON.
class _StringException implements Exception {
  const _StringException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Helper class to represent errors deserialized from JSON.
///
/// Overrides [stackTrace] with [StackTrace.empty] to avoid capturing a
/// spurious stack trace at construction time, since these are reconstructed
/// from serialized data and do not represent real throw sites.
class _StringError extends Error {
  _StringError(this.message);

  final String message;

  @override
  StackTrace get stackTrace => StackTrace.empty;

  @override
  String toString() => message;
}
