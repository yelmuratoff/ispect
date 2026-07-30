import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/utils/bounded_json_decoder.dart';
import 'package:ispectify/src/utils/safe_object_description.dart';

final class EncodedLogRecord {
  const EncodedLogRecord({
    required this.id,
    required this.bytes,
    required this.truncated,
  });

  final String id;
  final List<int> bytes;
  final bool truncated;
}

final class FileLogCodec {
  FileLogCodec({
    RedactionService? redactor,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  })  : _redactorOverride = redactor,
        _resourceLimits = resourceLimits {
    resourceLimits.validate();
  }

  static const int defaultMaxInputCharacters =
      BoundedJsonDecoder.defaultMaxCharacters;
  static const int defaultMaxInputBytes =
      BoundedJsonDecoder.defaultMaxEncodedBytes;
  static const int defaultMaxDepth = BoundedJsonDecoder.defaultMaxDepth;
  // JSON map keys are nodes to the decoder, while the normalizer's traversal
  // budget counts only values. This bound accepts every tree the encoder's
  // default normalization budget can emit, including its terminal marker.
  static const int defaultMaxNodes =
      JsonValueNormalizer.defaultMaxNodes * 2 + defaultMaxDepth * 2 + 1;
  static const int defaultMaxCollectionItems =
      BoundedJsonDecoder.defaultMaxCollectionItems;

  static const _schemaVersionKey = 'schema-version';
  static const _schemaVersion = 1;
  static const _maxTruncatedMessageCharacters = 160;
  static const _invalidRecordCause =
      FormatException('Invalid file-log record.');

  final RedactionService? _redactorOverride;
  final DiagnosticResourceLimits _resourceLimits;

  RedactionService get _redactor =>
      ISpectRedaction.resolveService(service: _redactorOverride);

  EncodedLogRecord encode(
    ISpectLogData log, {
    required String sessionId,
    required int maxBytes,
  }) {
    final captured = captureISpectLogDataForEgress(log);
    if (!_canAttemptFullEncode(
      log,
      sessionId: sessionId,
      maxBytes: maxBytes,
    )) {
      return _encodeMinimized(
        log,
        sessionId: sessionId,
        maxBytes: maxBytes,
      );
    }

    final record = _recordFor(log, sessionId: sessionId);
    final encoded = _redactAndEncode(record, maxBytes: maxBytes);
    if (encoded.bytes.length <= maxBytes) {
      return EncodedLogRecord(
        id: captured.id,
        bytes: encoded.bytes,
        truncated: encoded.truncated,
      );
    }

    return _encodeMinimized(
      log,
      sessionId: sessionId,
      maxBytes: maxBytes,
    );
  }

  EncodedLogRecord _encodeMinimized(
    ISpectLogData log, {
    required String sessionId,
    required int maxBytes,
  }) {
    final captured = captureISpectLogDataForEgress(log);
    final minimized = _minimizedRecordFor(log, sessionId: sessionId);
    if (!_canFitJsonValue(minimized, maxBytes: maxBytes)) {
      throw const FileLogLimitException(operation: 'encodeRecord');
    }
    final encodedMinimized = _redactAndEncode(
      minimized,
      maxBytes: maxBytes,
    );
    if (encodedMinimized.bytes.length > maxBytes) {
      throw const FileLogLimitException(operation: 'encodeRecord');
    }

    return EncodedLogRecord(
      id: captured.id,
      bytes: encodedMinimized.bytes,
      truncated: true,
    );
  }

  ISpectLogData decodeLine(
    String line, {
    int maxCharacters = defaultMaxInputCharacters,
    int maxEncodedBytes = defaultMaxInputBytes,
    int maxDepth = defaultMaxDepth,
    int maxNodes = defaultMaxNodes,
    int maxCollectionItems = defaultMaxCollectionItems,
    int? maxRootCollectionItems,
  }) {
    try {
      final decoded = _decodeJson(
        line,
        operation: 'decodeLine',
        maxCharacters: maxCharacters,
        maxEncodedBytes: maxEncodedBytes,
        maxDepth: maxDepth,
        maxNodes: maxNodes,
        maxCollectionItems: maxCollectionItems,
        maxRootCollectionItems: maxRootCollectionItems,
      );
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSONL record must be an object');
      }
      return ISpectLogDataJsonUtils.fromJson(
        decoded,
        resourceLimits: _resourceLimits,
      );
    } on FileLogHistoryException {
      rethrow;
    } on FormatException catch (_, stackTrace) {
      throw FileLogFormatException(
        operation: 'decodeLine',
        cause: _invalidRecordCause,
        stackTrace: stackTrace,
      );
    } catch (_, stackTrace) {
      throw FileLogFormatException(
        operation: 'decodeLine',
        cause: _invalidRecordCause,
        stackTrace: stackTrace,
      );
    }
  }

  List<ISpectLogData> decodeLegacyArray(
    String input, {
    int maxCharacters = defaultMaxInputCharacters,
    int maxEncodedBytes = defaultMaxInputBytes,
    int maxDepth = defaultMaxDepth,
    int maxNodes = defaultMaxNodes,
    int maxCollectionItems = defaultMaxCollectionItems,
    int? maxRootCollectionItems,
  }) {
    final decoded = _decodeJson(
      input,
      operation: 'decodeLegacyArray',
      maxCharacters: maxCharacters,
      maxEncodedBytes: maxEncodedBytes,
      maxDepth: maxDepth,
      maxNodes: maxNodes,
      maxCollectionItems: maxCollectionItems,
      maxRootCollectionItems: maxRootCollectionItems,
    );

    if (decoded is! List<dynamic>) {
      throw const FileLogFormatException(operation: 'decodeLegacyArray');
    }

    final logs = <ISpectLogData>[];
    for (var index = 0; index < decoded.length; index++) {
      final entry = decoded[index];
      try {
        if (entry is! Map<String, dynamic>) {
          throw const FormatException('Legacy record must be an object');
        }
        logs.add(
          ISpectLogDataJsonUtils.fromJson(
            entry,
            resourceLimits: _resourceLimits,
          ),
        );
      } on FileLogHistoryException {
        rethrow;
      } on FormatException catch (_, stackTrace) {
        throw FileLogFormatException(
          operation: 'decodeLegacyArray[$index]',
          cause: _invalidRecordCause,
          stackTrace: stackTrace,
        );
      } catch (_, stackTrace) {
        throw FileLogFormatException(
          operation: 'decodeLegacyArray[$index]',
          cause: _invalidRecordCause,
          stackTrace: stackTrace,
        );
      }
    }
    return logs;
  }

  Object? _decodeJson(
    String input, {
    required String operation,
    required int maxCharacters,
    required int maxEncodedBytes,
    required int maxDepth,
    required int maxNodes,
    required int maxCollectionItems,
    required int? maxRootCollectionItems,
  }) {
    try {
      return BoundedJsonDecoder.decode(
        input,
        maxCharacters: maxCharacters,
        maxEncodedBytes: maxEncodedBytes,
        maxDepth: maxDepth,
        maxNodes: maxNodes,
        maxCollectionItems: maxCollectionItems,
        maxRootCollectionItems: maxRootCollectionItems,
      );
    } on BoundedJsonException catch (error, stackTrace) {
      if (error.isLimit) {
        throw FileLogLimitException(
          operation: operation,
          cause: error,
          stackTrace: stackTrace,
        );
      }
      throw FileLogFormatException(
        operation: operation,
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, Object?> _recordFor(
    ISpectLogData log, {
    required String sessionId,
  }) {
    final captured = captureISpectLogDataForEgress(log);
    final serializedAdditionalData = _safePersistenceValue(
      captured.additionalData,
      rootCollectionLimit: _resourceLimits.maxCollectionItems > 2
          ? _resourceLimits.maxCollectionItems - 2
          : 1,
    );
    final additionalData = <String, Object?>{
      if (serializedAdditionalData is Map<String, Object?>)
        ...serializedAdditionalData,
      TraceKeys.sessionId: sessionId,
    };
    return <String, Object?>{
      'id': captured.id,
      if (captured.key != null) 'key': captured.key,
      'time': captured.time.toIso8601String(),
      if (captured.logLevel != null)
        'log-level': captured.logLevel!.index.toString(),
      if (captured.message != null) 'message': captured.message,
      if (captured.exceptionText != null)
        'exception': _safeDiagnosticSnapshot(captured.exceptionText!),
      if (captured.errorText != null)
        'error': _safeDiagnosticSnapshot(captured.errorText!),
      if (captured.stackTraceText != null)
        'stack-trace': _safeDiagnosticSnapshot(captured.stackTraceText!),
      'additional-data': additionalData,
      _schemaVersionKey: _schemaVersion,
    };
  }

  String _safeDiagnosticSnapshot(Object value) {
    final text = switch (value) {
      final String text => text,
      _ => safeDiagnosticDescriptor(value),
    };
    return String.fromCharCodes(
      text.runes.take(_maxTruncatedMessageCharacters),
    );
  }

  Object? _safePersistenceValue(
    Object? value, {
    int? rootCollectionLimit,
  }) =>
      _safePersistenceNode(
        value,
        depth: 0,
        collectionLimit:
            rootCollectionLimit ?? _resourceLimits.maxCollectionItems,
        ancestors: HashSet<Object>.identity(),
        budget: _SnapshotBudget(_resourceLimits.maxTraversalNodes),
      );

  Object? _safePersistenceNode(
    Object? value, {
    required int depth,
    required int collectionLimit,
    required Set<Object> ancestors,
    required _SnapshotBudget budget,
  }) {
    if (!budget.take()) return JsonValueNormalizer.maxNodesReached;
    if (value == null || value is bool || value is String) return value;
    if (value is num) {
      return value is double && !value.isFinite ? value.toString() : value;
    }
    if (value is DateTime || value is Uri) {
      return JsonValueNormalizer.unprintableValue;
    }
    if (value is Enum) return value.name;
    if (value is TypedData || value is ByteBuffer) return value;
    // The returned value is embedded below the file-record envelope.
    if (depth >= _resourceLimits.maxTraversalDepth - 1) {
      return JsonValueNormalizer.maxDepthReached;
    }

    if (value is Map) {
      if (!ancestors.add(value)) return JsonValueNormalizer.circularReference;
      try {
        final result = <String, Object?>{};
        var count = 0;
        final retainedLimit = collectionLimit - 1;
        try {
          for (final entry in value.entries) {
            if (count >= retainedLimit) {
              result[JsonValueNormalizer.traversalMarkerKey] =
                  JsonValueNormalizer.maxCollectionItemsReached;
              break;
            }
            final key = entry.key;
            if (key is String && key.startsWith('_')) continue;
            if (key is! String) {
              result['<unprintable-key>'] =
                  JsonValueNormalizer.unprintableValue;
            } else {
              result[key] = _safePersistenceNode(
                entry.value,
                depth: depth + 1,
                collectionLimit: _resourceLimits.maxCollectionItems,
                ancestors: ancestors,
                budget: budget,
              );
            }
            count++;
            if (!budget.hasCapacity) {
              result[JsonValueNormalizer.traversalMarkerKey] =
                  JsonValueNormalizer.maxNodesReached;
              break;
            }
          }
        } on Object {
          result[JsonValueNormalizer.traversalMarkerKey] =
              JsonValueNormalizer.unprintableValue;
        }
        return result;
      } finally {
        ancestors.remove(value);
      }
    }
    if (value is Iterable) {
      if (!ancestors.add(value)) return JsonValueNormalizer.circularReference;
      try {
        final result = <Object?>[];
        var count = 0;
        final retainedLimit = collectionLimit - 1;
        try {
          for (final item in value) {
            if (count >= retainedLimit) {
              result.add(JsonValueNormalizer.maxCollectionItemsReached);
              break;
            }
            result.add(
              _safePersistenceNode(
                item,
                depth: depth + 1,
                collectionLimit: _resourceLimits.maxCollectionItems,
                ancestors: ancestors,
                budget: budget,
              ),
            );
            count++;
            if (!budget.hasCapacity) {
              result.add(JsonValueNormalizer.maxNodesReached);
              break;
            }
          }
        } on Object {
          result.add(JsonValueNormalizer.unprintableValue);
        }
        return result;
      } finally {
        ancestors.remove(value);
      }
    }
    return JsonValueNormalizer.unprintableValue;
  }

  Map<String, Object?> _minimizedRecordFor(
    ISpectLogData log, {
    required String sessionId,
  }) {
    final captured = captureISpectLogDataForEgress(log);
    final capturedAdditionalData = captured.additionalData;
    final additionalData = <String, Object?>{
      TraceKeys.sessionId: sessionId,
      if (capturedAdditionalData?[TraceKeys.transactionId] case final value?)
        TraceKeys.transactionId: _minimizedMetadataValue(value),
      if (capturedAdditionalData?[TraceKeys.correlationId] case final value?)
        TraceKeys.correlationId: _minimizedMetadataValue(value),
    };

    return <String, Object?>{
      'id': captured.id,
      'time': captured.time.toIso8601String(),
      if (captured.logLevel != null)
        'log-level': captured.logLevel!.index.toString(),
      if (captured.key != null) 'key': captured.key,
      if (captured.message case final String message)
        'message': String.fromCharCodes(
          message.runes.take(_maxTruncatedMessageCharacters),
        )
      else if (captured.message case final message?)
        'message': message,
      'additional-data': additionalData,
      _schemaVersionKey: _schemaVersion,
      TraceKeys.payloadTruncated: true,
    };
  }

  Object? _minimizedMetadataValue(Object? value) => switch (value) {
        final String text => String.fromCharCodes(
            text.runes.take(_maxTruncatedMessageCharacters),
          ),
        final bool primitive => primitive,
        final num primitive when primitive is! double || primitive.isFinite =>
          primitive,
        _ => JsonValueNormalizer.unprintableValue,
      };

  bool _canAttemptFullEncode(
    ISpectLogData log, {
    required String sessionId,
    required int maxBytes,
  }) {
    final captured = captureISpectLogDataForEgress(log);
    return _canFitJsonValue(
      <String, Object?>{
        'id': captured.id,
        'time': captured.time.toIso8601String(),
        if (captured.logLevel != null)
          'log-level': captured.logLevel!.index.toString(),
        if (captured.key != null) 'key': captured.key,
        if (captured.message != null) 'message': captured.message,
        if (captured.exceptionText != null) 'exception': captured.exceptionText,
        if (captured.errorText != null) 'error': captured.errorText,
        if (captured.stackTraceText != null)
          'stack-trace': captured.stackTraceText,
        if (captured.additionalData != null)
          'additional-data': captured.additionalData,
        TraceKeys.sessionId: sessionId,
        _schemaVersionKey: _schemaVersion,
      },
      maxBytes: maxBytes,
    );
  }

  bool _canFitJsonValue(Object? root, {required int maxBytes}) {
    if (maxBytes < 1) return false;
    final budget = _PreEncodeBudget(maxBytes);
    final pending = <(Object?, int, bool)>[(root, 0, false)];
    final ancestors = HashSet<Object>.identity();
    var nodes = 0;

    while (pending.isNotEmpty) {
      final (value, depth, exiting) = pending.removeLast();
      if (exiting) {
        ancestors.remove(value);
        continue;
      }
      nodes++;
      if (nodes > _resourceLimits.maxTraversalNodes ||
          !budget.take(1) ||
          depth > _resourceLimits.maxTraversalDepth) {
        return false;
      }
      if (value == null) {
        if (!budget.take(3)) return false;
      } else if (value is bool) {
        if (!budget.take(4)) return false;
      } else if (value is num) {
        if (!budget.take(24)) return false;
      } else if (value is String) {
        if (!_takeJsonString(value, budget)) return false;
      } else if (value is Enum) {
        if (!_takeJsonString(value.name, budget)) return false;
      } else if (value is DateTime || value is Uri) {
        if (!_takeJsonString(
          JsonValueNormalizer.unprintableValue,
          budget,
        )) {
          return false;
        }
      } else if (value is TypedData) {
        final estimatedBytes =
            ISpectRedaction.enabled ? 64 : value.lengthInBytes * 4 + 2;
        if (!budget.take(estimatedBytes)) return false;
      } else if (value is ByteBuffer) {
        final estimatedBytes =
            ISpectRedaction.enabled ? 64 : value.lengthInBytes * 4 + 2;
        if (!budget.take(estimatedBytes)) return false;
      } else if (value is Map) {
        if (depth >= _resourceLimits.maxTraversalDepth) return false;
        if (!ancestors.add(value)) {
          if (!budget.take(32)) return false;
          continue;
        }
        pending.add((value, depth, true));
        if (!budget.take(2)) return false;
        var count = 0;
        try {
          for (final entry in value.entries) {
            if (count >= _resourceLimits.maxCollectionItems - 1) {
              if (!budget.take(64)) return false;
              break;
            }
            final key = entry.key;
            if (key is String) {
              if (!_takeJsonString(key, budget)) return false;
            } else if (!budget.take(64)) {
              return false;
            }
            if (!budget.take(2)) {
              return false;
            }
            pending.add((entry.value, depth + 1, false));
            count++;
          }
        } on Object {
          return false;
        }
      } else if (value is Iterable) {
        if (depth >= _resourceLimits.maxTraversalDepth) return false;
        if (!ancestors.add(value)) {
          if (!budget.take(32)) return false;
          continue;
        }
        pending.add((value, depth, true));
        if (!budget.take(2)) return false;
        var count = 0;
        try {
          for (final item in value) {
            if (count >= _resourceLimits.maxCollectionItems - 1) {
              if (!budget.take(64)) return false;
              break;
            }
            if (!budget.take(1)) return false;
            pending.add((item, depth + 1, false));
            count++;
          }
        } on Object {
          return false;
        }
      } else {
        // Do not invoke attacker-controlled formatting during preflight. The
        // normalizer will either emit a bounded marker or the subsequent byte
        // check will fall back to the minimized record.
        if (!budget.take(64)) return false;
      }
    }
    return true;
  }

  bool _takeJsonString(String value, _PreEncodeBudget budget) {
    if (!budget.take(2)) return false;
    for (var index = 0; index < value.length; index++) {
      final codeUnit = value.codeUnitAt(index);
      final bytes = switch (codeUnit) {
        <= 0x1f => 6,
        0x22 || 0x5c => 2,
        <= 0x7f => 1,
        <= 0x7ff => 2,
        >= 0xd800 && <= 0xdbff
            when index + 1 < value.length &&
                value.codeUnitAt(index + 1) >= 0xdc00 &&
                value.codeUnitAt(index + 1) <= 0xdfff =>
          4,
        _ => 3,
      };
      if (!budget.take(bytes)) return false;
      if (bytes == 4 &&
          codeUnit >= 0xd800 &&
          codeUnit <= 0xdbff &&
          index + 1 < value.length &&
          value.codeUnitAt(index + 1) >= 0xdc00 &&
          value.codeUnitAt(index + 1) <= 0xdfff) {
        index++;
      }
    }
    return true;
  }

  ({List<int> bytes, bool truncated}) _redactAndEncode(
    Map<String, Object?> record, {
    required int maxBytes,
  }) {
    final preparationBudget = maxBytes < _resourceLimits.maxCapturedValueBytes
        ? maxBytes
        : _resourceLimits.maxCapturedValueBytes;
    final sourceExceededPreparationBudget = !_canFitJsonValue(
      record,
      maxBytes: preparationBudget,
    );
    final trustedSessionId = (record['additional-data']
        as Map<Object?, Object?>?)?[TraceKeys.sessionId];
    final redacted = _redactor.redactEnvelopeForExport(
      record,
      rootValueKeys: const {'key'},
    );
    final bounded = LogExportOutput.boundJsonValue(
      redacted,
      maxBytes: maxBytes,
      resourceLimits: _resourceLimits,
      replaceOversizedStrings: true,
    );
    final safeRecord = bounded is Map<String, Object?>
        ? bounded
        : bounded is Map
            ? Map<String, Object?>.from(bounded)
            : <String, Object?>{
                'id': record['id'],
                'time': record['time'],
                _schemaVersionKey: _schemaVersion,
                TraceKeys.payloadTruncated: true,
              };
    if (trustedSessionId != null) {
      final additionalData = safeRecord['additional-data'];
      if (additionalData is Map<Object?, Object?>) {
        safeRecord['additional-data'] = <Object?, Object?>{
          ...additionalData,
          TraceKeys.sessionId: trustedSessionId,
        };
      } else {
        safeRecord['additional-data'] = <String, Object?>{
          TraceKeys.sessionId: trustedSessionId,
        };
      }
    }
    final encoded = utf8.encode(jsonEncode(safeRecord));
    return (
      bytes: <int>[...encoded, 0x0A],
      truncated: sourceExceededPreparationBudget ||
          _containsTruncationMarker(safeRecord),
    );
  }

  bool _containsTruncationMarker(Object? root) {
    final pending = <Object?>[root];
    var visited = 0;
    while (pending.isNotEmpty && visited < _resourceLimits.maxTraversalNodes) {
      final value = pending.removeLast();
      visited++;
      if (value == LogExportOutput.truncatedMarker ||
          value == JsonValueNormalizer.maxNodesReached ||
          value == JsonValueNormalizer.maxDepthReached ||
          value == JsonValueNormalizer.maxCollectionItemsReached) {
        return true;
      }
      if (value is Map<String, Object?>) {
        if (value[TraceKeys.payloadTruncated] == true) return true;
        pending.addAll(value.values);
      } else if (value is List<Object?>) {
        pending.addAll(value);
      }
    }
    return pending.isNotEmpty;
  }
}

final class _PreEncodeBudget {
  _PreEncodeBudget(this.remaining);

  int remaining;

  bool take(int bytes) {
    remaining -= bytes;
    return remaining >= 0;
  }
}

final class _SnapshotBudget {
  _SnapshotBudget(this.remaining);

  int remaining;

  bool get hasCapacity => remaining > 0;

  bool take() {
    if (remaining <= 0) return false;
    remaining--;
    return true;
  }
}
