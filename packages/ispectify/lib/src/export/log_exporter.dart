import 'dart:convert';

import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/trace/trace_keys.dart';

/// Utility class for batch export of log data.
///
/// Safety: when more than [defaultMaxLogs] entries are passed,
/// only the last [defaultMaxLogs] are exported to prevent OOM.
abstract final class LogExporter {
  static const defaultMaxLogs = 5000;

  /// Export as JSON Lines (one line = one log).
  static String toJsonLines(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
    Set<String>? redactKeys,
  }) {
    final capped = _cap(logs, maxLogs);
    return capped.map((log) {
      try {
        final json = log.toJson();
        if (redactKeys != null && redactKeys.isNotEmpty) {
          final ex = json['exception'];
          if (ex is String) {
            json['exception'] =
                RedactionService.redactExportString(ex, redactKeys);
          }
          final err = json['error'];
          if (err is String) {
            json['error'] =
                RedactionService.redactExportString(err, redactKeys);
          }
          final ad = json['additional-data'];
          if (ad is Map && ad[TraceKeys.error] is String) {
            ad[TraceKeys.error] = RedactionService.redactExportString(
              ad[TraceKeys.error] as String,
              redactKeys,
            );
          }
        }
        return jsonEncode(json);
      } catch (_) {
        return jsonEncode({
          'message': '${log.message}',
          'key': log.key,
          'time': log.formattedTime,
        });
      }
    }).join('\n');
  }

  /// Export as plain text.
  static String toText(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
    Set<String>? redactKeys,
  }) {
    final capped = _cap(logs, maxLogs);
    final buffer = StringBuffer()
      ..writeln('=== ISpect Log Report ===')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln(
        'Total entries: ${capped.length}'
        '${capped.length < logs.length ? ' (capped from ${logs.length})' : ''}',
      )
      ..writeln('---');
    for (final log in capped) {
      buffer.writeln(log.toText(redactKeys: redactKeys));
    }
    return buffer.toString();
  }

  /// Export as Markdown.
  static String toMarkdown(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
    Set<String>? redactKeys,
  }) {
    final capped = _cap(logs, maxLogs);
    final buffer = StringBuffer()
      ..writeln('# ISpect Log Report')
      ..writeln()
      ..writeln(
        '> Generated: ${DateTime.now().toIso8601String()} | '
        'Entries: ${capped.length}'
        '${capped.length < logs.length ? ' (capped from ${logs.length})' : ''}',
      )
      ..writeln();
    for (final log in capped) {
      buffer
        ..writeln(log.toMarkdown(redactKeys: redactKeys))
        ..writeln('---');
    }
    return buffer.toString();
  }

  /// Export as CSV with formula injection protection.
  ///
  /// Overview format only — exception, error, stackTrace and nested meta
  /// are not included (too long for tabular format). Use JSON Lines or
  /// Text for full details.
  static String toCsv(
    List<ISpectLogData> logs, {
    int? maxLogs = defaultMaxLogs,
    Set<String>? redactKeys,
  }) {
    final capped = _cap(logs, maxLogs);
    final buffer = StringBuffer()
      ..writeln(
        'time,level,key,category,source,operation,target,durationMs,success,message',
      );
    for (final log in capped) {
      final ad = log.additionalData;
      final rawMessage = log.message?.toString() ?? '';
      final safeMessage = redactKeys != null
          ? RedactionService.redactExportString(rawMessage, redactKeys)
          : rawMessage;
      buffer.writeln(
        [
          _csvEscape(log.formattedTime),
          _csvEscape(log.logLevel?.name ?? ''),
          _csvEscape(log.key ?? ''),
          _csvEscape(ad?[TraceKeys.category]?.toString() ?? ''),
          _csvEscape(ad?[TraceKeys.source]?.toString() ?? ''),
          _csvEscape(ad?[TraceKeys.operation]?.toString() ?? ''),
          _csvEscape(ad?[TraceKeys.target]?.toString() ?? ''),
          _csvEscape(ad?[TraceKeys.durationMs]?.toString() ?? ''),
          _csvEscape(ad?[TraceKeys.success]?.toString() ?? ''),
          _csvEscape(safeMessage),
        ].join(','),
      );
    }
    return buffer.toString();
  }

  static List<ISpectLogData> _cap(List<ISpectLogData> logs, int? maxLogs) {
    if (maxLogs == null || logs.length <= maxLogs) return logs;
    return logs.sublist(logs.length - maxLogs);
  }

  /// CSV escape with formula injection protection.
  static String _csvEscape(String value) {
    var result = value;
    if (result.isNotEmpty && '=+-@'.contains(result[0])) {
      result = '\t$result';
    }
    if (result.contains(',') ||
        result.contains('"') ||
        result.contains('\n') ||
        result.contains('\t')) {
      return '"${result.replaceAll('"', '""')}"';
    }
    return result;
  }
}
