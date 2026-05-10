import 'dart:convert';

import 'package:ispectify/ispectify.dart';

/// Extension for ISpectLogData to add serialization support.
extension ISpectLogDataSerialization on ISpectLogData {
  /// Converts the log data into a JSON representation.
  ///
  /// Omits `null` values for a cleaner output.
  Map<String, dynamic> toJson({
    bool truncated = false,
  }) =>
      {
        'id': id,
        if (key != null) 'key': key,
        'time': time.toIso8601String(),
        if (logLevel != null) 'log-level': logLevel!.index.toString(),
        if (message != null)
          'message': truncated ? message.truncate() : message,
        if (exception != null)
          'exception': truncated
              ? exception.toString().truncate()
              : exception.toString(),
        if (error != null)
          'error': truncated ? error.toString().truncate() : error.toString(),
        if (stackTrace != null)
          'stack-trace': truncated
              ? stackTrace.toString().truncate()
              : stackTrace.toString(),
        if (additionalData != null) 'additional-data': additionalData,
      };

  /// Plain text — for sharing, copying, human reading.
  ///
  /// [redactKeys] enables Layer 3 redaction for exception/error strings.
  String toText({Set<String>? redactKeys}) {
    final buffer = StringBuffer()..writeln('[$formattedTime] [$key] $message');

    if (additionalData != null && additionalData!.isNotEmpty) {
      for (final entry in additionalData!.entries) {
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

    if (exception != null) {
      final exStr = '$exception';
      buffer.writeln(
        '  Exception: ${RedactionService.redactExportString(exStr, redactKeys)}',
      );
    }
    if (error != null) {
      final errStr = '$error';
      buffer.writeln(
        '  Error: ${RedactionService.redactExportString(errStr, redactKeys)}',
      );
    }
    if (stackTrace != null) buffer.writeln('  StackTrace:\n$stackTrace');

    return buffer.toString();
  }

  /// Markdown — for issue trackers, documentation.
  ///
  /// [redactKeys] enables Layer 3 redaction for exception/error strings.
  String toMarkdown({Set<String>? redactKeys}) {
    final buffer = StringBuffer()
      ..writeln(
        '### ${_logLevelIndicator(logLevel)} `$key` — $message',
      )
      ..writeln()
      ..writeln('| Field | Value |')
      ..writeln('|-------|-------|')
      ..writeln('| Time | `$formattedTime` |')
      ..writeln('| Level | `${logLevel?.name ?? 'unknown'}` |');

    if (additionalData != null) {
      final category = additionalData![TraceKeys.category];
      final source = additionalData![TraceKeys.source];
      final operation = additionalData![TraceKeys.operation];
      final duration = additionalData![TraceKeys.durationMs];

      if (category != null) buffer.writeln('| Category | `$category` |');
      if (source != null) buffer.writeln('| Source | `$source` |');
      if (operation != null) buffer.writeln('| Operation | `$operation` |');
      if (duration != null) buffer.writeln('| Duration | `${duration}ms` |');
    }

    if (additionalData != null && additionalData!.isNotEmpty) {
      final safeData = Map<String, dynamic>.of(additionalData!)
        ..remove(TraceKeys.error);
      if (safeData.isNotEmpty) {
        buffer
          ..writeln()
          ..writeln('**Details:**')
          ..writeln('```json');
        try {
          buffer.writeln(const JsonEncoder.withIndent('  ').convert(safeData));
        } catch (_) {
          buffer.writeln(safeData.toString());
        }
        buffer.writeln('```');
      }
    }

    if (exception != null) {
      final exStr = '$exception';
      buffer.writeln(
        '\n**Exception:** `${RedactionService.redactExportString(exStr, redactKeys)}`',
      );
    }
    if (error != null) {
      final errStr = '$error';
      buffer.writeln(
        '\n**Error:** `${RedactionService.redactExportString(errStr, redactKeys)}`',
      );
    }
    if (stackTrace != null) {
      buffer.writeln('\n**Stack trace:**\n```\n$stackTrace\n```');
    }

    return buffer.toString();
  }

  String _logLevelIndicator(LogLevel? level) => switch (level) {
        LogLevel.error || LogLevel.critical => '[ERROR]',
        LogLevel.warning => '[WARN]',
        LogLevel.info => '[INFO]',
        LogLevel.debug => '[DEBUG]',
        _ => '[-]',
      };
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
    if (!json.containsKey('message') && !json.containsKey('time')) {
      throw const FormatException(
        'Invalid log entry: missing both "message" and "time" fields',
      );
    }

    return ISpectLogData(
      json['message']?.toString(),
      time: DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now(),
      logLevel: _parseLogLevel(json['log-level']?.toString()),
      key: json['key']?.toString(),
      additionalData: json['additional-data'] is Map<String, dynamic>
          ? json['additional-data'] as Map<String, dynamic>
          : null,
      // Note: These are reconstructed as strings for JSON compatibility
      exception: json['exception'] != null
          ? _StringException(json['exception'].toString())
          : null,
      error:
          json['error'] != null ? _StringError(json['error'].toString()) : null,
      stackTrace: json['stack-trace'] != null
          ? StackTrace.fromString(json['stack-trace'].toString())
          : null,
      id: json['id']?.toString(),
    );
  }
}

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
