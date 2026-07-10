import 'dart:convert';

import 'package:ispectify/ispectify.dart';

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
  FileLogCodec({required RedactionService redactor}) : _redactor = redactor;

  static const _schemaVersionKey = 'schema-version';
  static const _schemaVersion = 1;
  static const _maxTruncatedMessageCharacters = 160;

  final RedactionService _redactor;

  EncodedLogRecord encode(
    ISpectLogData log, {
    required String sessionId,
    required int maxBytes,
  }) {
    final record = _recordFor(log, sessionId: sessionId);
    final bytes = _redactAndEncode(record);
    if (bytes.length <= maxBytes) {
      return EncodedLogRecord(
        id: log.id,
        bytes: bytes,
        truncated: false,
      );
    }

    final minimized = _minimizedRecordFor(log, sessionId: sessionId);
    final minimizedBytes = _redactAndEncode(minimized);
    if (minimizedBytes.length > maxBytes) {
      throw const FileLogLimitException(operation: 'encodeRecord');
    }

    return EncodedLogRecord(
      id: log.id,
      bytes: minimizedBytes,
      truncated: true,
    );
  }

  ISpectLogData decodeLine(String line) {
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('JSONL record must be an object');
      }
      return ISpectLogDataJsonUtils.fromJson(decoded);
    } on FileLogHistoryException {
      rethrow;
    } catch (error, stackTrace) {
      throw FileLogFormatException(
        operation: 'decodeLine',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  List<ISpectLogData> decodeLegacyArray(String input) {
    Object? decoded;
    try {
      decoded = jsonDecode(input);
    } catch (error, stackTrace) {
      throw FileLogFormatException(
        operation: 'decodeLegacyArray',
        cause: error,
        stackTrace: stackTrace,
      );
    }

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
        logs.add(ISpectLogDataJsonUtils.fromJson(entry));
      } catch (error, stackTrace) {
        throw FileLogFormatException(
          operation: 'decodeLegacyArray[$index]',
          cause: error,
          stackTrace: stackTrace,
        );
      }
    }
    return logs;
  }

  Map<String, Object?> _recordFor(
    ISpectLogData log, {
    required String sessionId,
  }) {
    final record = Map<String, Object?>.from(log.toJson());
    final serializedAdditionalData = record['additional-data'];
    final additionalData = <String, Object?>{
      if (serializedAdditionalData is Map<String, dynamic>)
        ...serializedAdditionalData,
      TraceKeys.sessionId: sessionId,
    };
    record
      ..['additional-data'] = additionalData
      ..[_schemaVersionKey] = _schemaVersion;
    return record;
  }

  Map<String, Object?> _minimizedRecordFor(
    ISpectLogData log, {
    required String sessionId,
  }) {
    final additionalData = <String, Object?>{
      TraceKeys.sessionId: sessionId,
      if (log.additionalData?[TraceKeys.transactionId] case final value?)
        TraceKeys.transactionId: value,
      if (log.additionalData?[TraceKeys.correlationId] case final value?)
        TraceKeys.correlationId: value,
    };

    return <String, Object?>{
      'id': log.id,
      'time': log.time.toIso8601String(),
      if (log.logLevel != null) 'log-level': log.logLevel!.index.toString(),
      if (log.key != null) 'key': log.key,
      if (log.message != null)
        'message': String.fromCharCodes(
          log.message!.runes.take(_maxTruncatedMessageCharacters),
        ),
      'additional-data': additionalData,
      _schemaVersionKey: _schemaVersion,
      TraceKeys.payloadTruncated: true,
    };
  }

  List<int> _redactAndEncode(Map<String, Object?> record) {
    final safeRecord = _jsonSafe(record);
    final redacted = _redactor.redact(
      safeRecord,
      ignoredKeys: const {TraceKeys.sessionId},
    );
    final encoded = utf8.encode(jsonEncode(redacted));
    return <int>[...encoded, 0x0A];
  }

  Object? _jsonSafe(Object? value) {
    if (value == null || value is bool || value is String) return value;
    if (value is num) {
      return value is double && !value.isFinite ? value.toString() : value;
    }
    if (value is Map<Object?, Object?>) {
      return <String, Object?>{
        for (final entry in value.entries)
          entry.key.toString(): _jsonSafe(entry.value),
      };
    }
    if (value is Iterable<Object?>) {
      return value.map(_jsonSafe).toList(growable: false);
    }
    return value.toString();
  }
}
