import 'dart:convert';

import 'package:ispectify/src/history/serialization.dart';
import 'package:ispectify/src/models/data.dart';
import 'package:ispectify/src/models/diagnostic_resource_limits.dart';
import 'package:ispectify/src/models/metadata.dart';
import 'package:ispectify/src/redaction/constants/placeholders.dart';
import 'package:ispectify/src/redaction/egress_provenance.dart';
import 'package:ispectify/src/redaction/redaction_service.dart';
import 'package:ispectify/src/redaction/redaction_toggle.dart';
import 'package:ispectify/src/trace/trace_keys.dart';
import 'package:ispectify/src/utils/datetime_formatter.dart';
import 'package:ispectify/src/utils/json_value_normalizer.dart';

/// Utility class for batch export of log data.
///
/// Safety: when more than [defaultMaxLogs] entries are passed,
/// only the last [defaultMaxLogs] are exported to prevent OOM.
/// Each entry and complete document also use [LogExportOutput]'s UTF-8 byte
/// limits; aggregate overflow stops before a partial record is written.
/// Every format redacts with the default sensitive-key set when `redactKeys`
/// is omitted. Pass `enableRedaction: false` only for an explicit local
/// debugging opt-out; the global [ISpectRedaction.enabled] switch is also
/// honored. A supplied [RedactionService] takes precedence over `redactKeys`.
abstract final class LogExporter {
  static const defaultMaxLogs = 5000;

  /// Export as JSON Lines (one line = one log).
  static String toJsonLines(
    List<ISpectLogData> logs, {
    int? maxLogs,
    Set<String>? redactKeys,
    RedactionService? redactionService,
    bool enableRedaction = true,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final limits = resourceLimits;
    final capped = _cap(logs, _resolveMaxLogs(maxLogs, limits));
    final output = _BoundedExportBuffer(limits.maxExportDocumentBytes);
    final effectiveRedactionService = enableRedaction && ISpectRedaction.enabled
        ? _redactor(redactKeys, redactionService)
        : null;
    var hasRecord = false;
    for (final log in capped) {
      final record = _jsonLine(
        log,
        redactKeys: null,
        redactionService: effectiveRedactionService,
        enableRedaction: enableRedaction,
        resourceLimits: limits,
      );
      final prefix = hasRecord ? '\n' : '';
      if (!output.writeAll([prefix, record])) {
        final marker = jsonEncode({
          'message': LogExportOutput.truncatedMarker,
          'export-error': LogExportOutput.truncatedMarker,
        });
        output.writeAll([prefix, marker]);
        break;
      }
      hasRecord = true;
    }
    return output.toString();
  }

  /// Export as plain text.
  static String toText(
    List<ISpectLogData> logs, {
    int? maxLogs,
    Set<String>? redactKeys,
    RedactionService? redactionService,
    ISpectMetadata? metadata,
    bool enableRedaction = true,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final limits = resourceLimits;
    final capped = _cap(logs, _resolveMaxLogs(maxLogs, limits));
    final effectiveRedactionService = enableRedaction && ISpectRedaction.enabled
        ? _redactor(redactKeys, redactionService)
        : null;
    final header = StringBuffer()
      ..writeln('=== ISpect Log Report ===')
      ..writeln('Generated: ${DateTime.now().toIso8601String()}')
      ..writeln(
        'Total entries: ${capped.length}'
        '${capped.length < logs.length ? ' (capped from ${logs.length})' : ''}',
      );
    _writeMetadata(
      header,
      metadata,
      redactionService: effectiveRedactionService,
      enableRedaction: enableRedaction,
      resourceLimits: limits,
    );
    header.writeln('---');
    final output = _BoundedExportBuffer(limits.maxExportDocumentBytes)
      ..writeBounded(header.toString());
    for (final log in capped) {
      final record = log.toText(
        redactionService: effectiveRedactionService,
        enableRedaction: enableRedaction,
        maxOutputBytes: limits.maxLogRecordBytes,
      );
      if (!output.writeAll([record, '\n'])) {
        output.writeAll([LogExportOutput.truncatedMarker, '\n']);
        break;
      }
    }
    return output.toString();
  }

  /// Export as Markdown.
  static String toMarkdown(
    List<ISpectLogData> logs, {
    int? maxLogs,
    Set<String>? redactKeys,
    RedactionService? redactionService,
    ISpectMetadata? metadata,
    bool enableRedaction = true,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final limits = resourceLimits;
    final capped = _cap(logs, _resolveMaxLogs(maxLogs, limits));
    final effectiveRedactionService = enableRedaction && ISpectRedaction.enabled
        ? _redactor(redactKeys, redactionService)
        : null;
    final header = StringBuffer()
      ..writeln('# ISpect Log Report')
      ..writeln()
      ..writeln(
        '> Generated: ${DateTime.now().toIso8601String()} | '
        'Entries: ${capped.length}'
        '${capped.length < logs.length ? ' (capped from ${logs.length})' : ''}',
      );
    _writeMetadata(
      header,
      metadata,
      linePrefix: '> ',
      redactionService: effectiveRedactionService,
      enableRedaction: enableRedaction,
      resourceLimits: limits,
    );
    header.writeln();
    final output = _BoundedExportBuffer(limits.maxExportDocumentBytes)
      ..writeBounded(header.toString());
    for (final log in capped) {
      final record = log.toMarkdown(
        redactionService: effectiveRedactionService,
        enableRedaction: enableRedaction,
        maxOutputBytes: limits.maxLogRecordBytes,
      );
      if (!output.writeAll([record, '---\n'])) {
        output.writeAll([LogExportOutput.truncatedMarker, '\n']);
        break;
      }
    }
    return output.toString();
  }

  /// Export as CSV with formula injection protection.
  ///
  /// Overview format only — exception, error, stackTrace and nested meta
  /// are not included (too long for tabular format). Use JSON Lines or
  /// Text for full details.
  static String toCsv(
    List<ISpectLogData> logs, {
    int? maxLogs,
    Set<String>? redactKeys,
    RedactionService? redactionService,
    bool enableRedaction = true,
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) {
    resourceLimits.validate();
    final limits = resourceLimits;
    final capped = _cap(logs, _resolveMaxLogs(maxLogs, limits));
    final effectiveRedactionService = enableRedaction && ISpectRedaction.enabled
        ? _redactor(redactKeys, redactionService)
        : null;
    final output = _BoundedExportBuffer(limits.maxExportDocumentBytes)
      ..writeAll([
        'time,level,key,category,source,operation,target,durationMs,success,message\n',
      ]);
    for (final log in capped) {
      final captured = captureISpectLogDataForEgress(log);
      final ad = captured.additionalData;
      String scrub(Object? value) => _redactText(
            value,
            null,
            redactionService: effectiveRedactionService,
            enableRedaction: enableRedaction,
            resourceLimits: limits,
          );
      final row = [
        escapeCsvValue(
          ISpectDateTimeFormatter(captured.time).defaultFormat,
        ),
        escapeCsvValue(captured.logLevel?.name ?? ''),
        escapeCsvValue(scrub(captured.key)),
        escapeCsvValue(scrub(ad?[TraceKeys.category])),
        escapeCsvValue(scrub(ad?[TraceKeys.source])),
        escapeCsvValue(scrub(ad?[TraceKeys.operation])),
        escapeCsvValue(scrub(ad?[TraceKeys.target])),
        escapeCsvValue(scrub(ad?[TraceKeys.durationMs])),
        escapeCsvValue(scrub(ad?[TraceKeys.success])),
        escapeCsvValue(scrub(captured.message)),
      ].join(',');
      final safeRow = LogExportOutput.utf8Length(
                row,
                limit: limits.maxLogRecordBytes,
              ) <=
              limits.maxLogRecordBytes
          ? row
          : ',,,,,,,,,"${LogExportOutput.truncatedMarker}"';
      if (!output.writeAll([safeRow, '\n'])) {
        output.writeAll([
          ',,,,,,,,,"${LogExportOutput.truncatedMarker}"\n',
        ]);
        break;
      }
    }
    return output.toString();
  }

  /// Appends each non-null metadata field as a `key: value` line, prefixing
  /// every line with [linePrefix] (e.g. `> ` for Markdown blockquotes).
  static void _writeMetadata(
    StringBuffer buffer,
    ISpectMetadata? metadata, {
    required bool enableRedaction,
    required DiagnosticResourceLimits resourceLimits,
    String linePrefix = '',
    Set<String>? redactKeys,
    RedactionService? redactionService,
  }) {
    if (metadata == null) return;
    final redactionActive = enableRedaction && ISpectRedaction.enabled;
    final prepared = _prepareValue(
      _metadataMap(
        metadata,
        redactionActive: redactionActive,
        resourceLimits: resourceLimits,
      ),
      redactKeys: redactKeys,
      redactionService: redactionService,
      enableRedaction: enableRedaction,
      resourceLimits: resourceLimits,
    );
    if (prepared is! Map) return;
    for (final entry in prepared.entries) {
      final value = _redactText(
        entry.value,
        null,
        redactionService: null,
        enableRedaction: false,
        resourceLimits: resourceLimits,
      );
      final safeKey = linePrefix.isEmpty
          ? entry.key
          : _markdownMetadataText(entry.key.toString());
      final safeValue =
          linePrefix.isEmpty ? value : _markdownMetadataText(value);
      buffer.writeln('$linePrefix$safeKey: $safeValue');
    }
  }

  static String _markdownMetadataText(String value) {
    final escaped = value
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

  static List<ISpectLogData> _cap(List<ISpectLogData> logs, int maxLogs) {
    if (logs.length <= maxLogs) return logs;
    return logs.sublist(logs.length - maxLogs);
  }

  static int _resolveMaxLogs(
    int? maxLogs,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final resolved = maxLogs ?? resourceLimits.maxExportEntries;
    if (resolved < 1 ||
        resolved > DiagnosticResourceLimits.maxAllowedExportEntries) {
      throw ArgumentError.value(
        resolved,
        'maxLogs',
        'must be between 1 and '
            '${DiagnosticResourceLimits.maxAllowedExportEntries}',
      );
    }
    return resolved;
  }

  static String _jsonLine(
    ISpectLogData log, {
    required Set<String>? redactKeys,
    required RedactionService? redactionService,
    required bool enableRedaction,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    try {
      final redactionActive = enableRedaction && ISpectRedaction.enabled;
      final reuseCaptureRedaction = redactionActive &&
          redactKeys == null &&
          redactionService != null &&
          isExportRedacted(
            log,
            service: redactionService,
            resourceLimits: resourceLimits,
          );
      final encoded = jsonEncode(
        reuseCaptureRedaction
            ? log.toExportJson(redactionActive: false)
            : _prepareValue(
                log.toExportJson(redactionActive: redactionActive),
                redactKeys: redactKeys,
                redactionService: redactionService,
                enableRedaction: enableRedaction,
                resourceLimits: resourceLimits,
                rootValueKeys: const {'key'},
              ),
      );
      if (LogExportOutput.utf8Length(
            encoded,
            limit: resourceLimits.maxLogRecordBytes,
          ) <=
          resourceLimits.maxLogRecordBytes) {
        return encoded;
      }
    } catch (_) {
      return _jsonLineFailure(log);
    }
    return _jsonLineFailure(
      log,
      message: LogExportOutput.truncatedMarker,
    );
  }

  static String _jsonLineFailure(
    ISpectLogData log, {
    String message = redactionFailedPlaceholder,
  }) {
    final captured = captureISpectLogDataForEgress(log);
    return jsonEncode({
      'message': message,
      'time': ISpectDateTimeFormatter(captured.time).defaultFormat,
      'export-error': message,
    });
  }

  static Object? _prepareValue(
    Object? value, {
    required Set<String>? redactKeys,
    required RedactionService? redactionService,
    required bool enableRedaction,
    required DiagnosticResourceLimits resourceLimits,
    Set<String>? rootValueKeys,
  }) {
    final redactionActive = enableRedaction && ISpectRedaction.enabled;
    if (!redactionActive) {
      return LogExportOutput.boundJsonValue(
        value,
        resourceLimits: resourceLimits,
      );
    }
    final redactor = _redactor(redactKeys, redactionService);
    return rootValueKeys == null || rootValueKeys.isEmpty
        ? redactor.redactForExport(
            value,
            resourceLimits: resourceLimits,
          )
        : redactor.redactEnvelopeForExport(
            value,
            rootValueKeys: rootValueKeys,
            resourceLimits: resourceLimits,
          );
  }

  static String _redactText(
    Object? value,
    Set<String>? redactKeys, {
    required RedactionService? redactionService,
    required bool enableRedaction,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    final prepared = _prepareValue(
      value,
      redactKeys: redactKeys,
      redactionService: redactionService,
      enableRedaction: enableRedaction,
      resourceLimits: resourceLimits,
    );
    if (prepared == null) return '';
    if (prepared is String) return prepared;
    if (prepared is bool || prepared is num) return prepared.toString();
    try {
      return LogExportOutput.truncateUtf8(
        jsonEncode(prepared),
        maxBytes: resourceLimits.maxCapturedValueBytes,
      );
    } catch (_) {
      return JsonValueNormalizer.unprintableValue;
    }
  }

  static RedactionService _redactor(
    Set<String>? redactKeys,
    RedactionService? redactionService,
  ) =>
      ISpectRedaction.resolveService(
        service: redactionService,
        sensitiveKeys: redactKeys,
      );

  static Map<String, Object?> _metadataMap(
    ISpectMetadata metadata, {
    required bool redactionActive,
    required DiagnosticResourceLimits resourceLimits,
  }) {
    final boundedExtra = LogExportOutput.boundJsonValue(
      metadata.extra,
      resourceLimits: resourceLimits,
      preserveTypes: redactionActive,
      replaceOversizedStrings: redactionActive,
    );
    final result = <String, Object?>{
      if (metadata.appName != null) 'appName': metadata.appName,
      if (metadata.appVersion != null) 'appVersion': metadata.appVersion,
      if (metadata.buildNumber != null) 'buildNumber': metadata.buildNumber,
      if (metadata.environment != null) 'environment': metadata.environment,
      if (metadata.device != null) 'device': metadata.device,
      if (metadata.os != null) 'os': metadata.os,
      if (metadata.osVersion != null) 'osVersion': metadata.osVersion,
      if (metadata.locale != null) 'locale': metadata.locale,
    };
    if (boundedExtra is Map<String, Object?>) {
      for (final entry in boundedExtra.entries) {
        result.putIfAbsent(entry.key, () => entry.value);
      }
    }
    return result;
  }

  /// Escapes one CSV field and neutralizes spreadsheet formulas.
  ///
  /// A leading formula sigil or control character is prefixed with a single
  /// quote before RFC 4180 quoting. This covers formulas hidden behind tab,
  /// carriage-return, or line-feed prefixes as well as direct `=`, `+`, `-`,
  /// and `@` prefixes.
  static String escapeCsvValue(String value) {
    var result = value;
    if (result.isNotEmpty && '=+-@\t\r\n'.contains(result[0])) {
      result = "'$result";
    }
    if (result.contains(',') ||
        result.contains('"') ||
        result.contains('\r') ||
        result.contains('\n') ||
        result.contains('\t')) {
      return '"${result.replaceAll('"', '""')}"';
    }
    return result;
  }
}

final class _BoundedExportBuffer {
  _BoundedExportBuffer(this.maxBytes);

  final int maxBytes;
  final StringBuffer _buffer = StringBuffer();
  int _bytes = 0;

  bool writeAll(List<String> values) {
    var additionalBytes = 0;
    for (final value in values) {
      final remaining = maxBytes - _bytes - additionalBytes;
      final valueBytes = LogExportOutput.utf8Length(value, limit: remaining);
      if (valueBytes > remaining) return false;
      additionalBytes += valueBytes;
    }
    values.forEach(_buffer.write);
    _bytes += additionalBytes;
    return true;
  }

  void writeBounded(String value) {
    final remaining = maxBytes - _bytes;
    if (remaining <= 0) return;
    final bounded = LogExportOutput.truncateUtf8(
      value,
      maxBytes: remaining,
    );
    _buffer.write(bounded);
    _bytes += LogExportOutput.utf8Length(bounded);
  }

  @override
  String toString() => _buffer.toString();
}
