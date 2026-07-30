// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:convert';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/chunking.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:meta/meta.dart';

/// Immutable outcome of a bounded log import.
@immutable
final class LogsImportResult {
  LogsImportResult._({
    required List<ISpectLogData> logs,
    required this.totalEntries,
    required this.skippedEntries,
  })  : assert(totalEntries == logs.length + skippedEntries),
        logs = List<ISpectLogData>.unmodifiable(logs);

  /// Successfully decoded log entries.
  final List<ISpectLogData> logs;

  /// Number of entries found in the imported JSON document.
  final int totalEntries;

  /// Number of entries rejected because they could not be decoded safely.
  final int skippedEntries;

  /// Number of successfully decoded entries.
  int get importedEntries => logs.length;

  /// Whether the caller should disclose a partial import.
  bool get hasSkippedEntries => skippedEntries > 0;
}

/// Service for managing JSON export/import operations for logs.
///
/// - Parameters: None required for initialization
/// - Return: LogsJsonService instance
/// - Usage example: final service = LogsJsonService();
/// - Edge case notes: Handles empty data gracefully, provides chunked processing
class LogsJsonService {
  /// Creates a service that inherits logger policies unless locally overridden.
  const LogsJsonService({
    this.resourceLimits,
    this.processingPolicy,
  });

  final DiagnosticResourceLimits? resourceLimits;
  final DiagnosticProcessingPolicy? processingPolicy;

  /// Balanced default JSON string size in UTF-16 code units.
  static const int maxJsonSize = JsonInputPreflight.maxCharacters;

  /// Balanced default JSON nesting depth.
  static const int maxJsonDepth = JsonInputPreflight.maxNestingDepth;

  /// Balanced default encoded JSON size in bytes.
  static const int maxJsonByteSize = JsonInputPreflight.maxEncodedBytes;

  /// Balanced default number of JSON values and containers.
  static const int maxJsonNodes = JsonInputPreflight.maxApproximateNodes;

  /// Balanced default number of imported log entries.
  static const int maxLogEntries = 100000;

  /// Exports logs to JSON format with metadata.
  ///
  /// Export-time redaction is enabled by default as a defense-in-depth pass.
  /// [redactionService] customizes its policy; when omitted, the global
  /// [ISpectRedaction.service] policy is used. Pass `enableRedaction: false`
  /// for an explicit controlled-debugging opt-out.
  /// Output is compact and capped by the active resource policy.
  /// When the cap is reached, only complete leading records that fit are
  /// emitted. Metadata reports `totalLogs`, `exportedLogs`, and `truncated`.
  ///
  /// - Parameters: logs (list of entries), includeMetadata (flag for metadata),
  ///   redactionService (optional policy override),
  ///   enableRedaction (default: true)
  /// - Return: JSON string ready for file export
  /// - Usage example: `final jsonString = await service.exportToJson(logs);`
  /// - Edge case notes: Processes in chunks to prevent memory issues, handles large datasets
  Future<String> exportToJson(
    List<ISpectLogData> logs, {
    bool includeMetadata = true,
    RedactionService? redactionService,
    bool enableRedaction = true,
    ISpectMetadata? metadata,
  }) async {
    final limits = _resourceLimits;
    final scheduling = _processingPolicy;
    final effectiveRedactor = _effectiveRedactor(
      enableRedaction,
      redactionService,
    );
    final encoder = _JsonExportEncoder(
      includeMetadata: includeMetadata,
      totalLogCount: logs.length,
      sourceLogCount: logs.length,
      metadata: includeMetadata
          ? _prepareJsonValue(
              _createExportMetadata(
                logs.length,
                metadata,
                effectiveRedactor,
                limits,
              ),
              effectiveRedactor,
              limits,
            )
          : null,
      redactor: effectiveRedactor,
      resourceLimits: limits,
    );
    var processed = 0;
    exportLoop:
    for (final chunk in Chunking.chunks(logs, scheduling.exportChunkSize)) {
      for (final log in chunk) {
        if (!encoder.addLog(log)) break exportLoop;
      }
      processed++;
      await Chunking.yieldEvery(
        processed,
        scheduling.yieldEveryExportChunks,
      );
    }
    return encoder.finish();
  }

  /// Creates export metadata with current timestamp and version
  Map<String, dynamic> _createExportMetadata(
    int totalLogs,
    ISpectMetadata? metadata,
    RedactionService? redactor,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final result = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'totalLogs': totalLogs,
      'platform': 'ispect',
    };
    _appendHostMetadata(result, metadata, redactor, resourceLimits);
    return result;
  }

  /// Imports logs from JSON format with comprehensive validation
  ///
  /// Import-time redaction is enabled by default. [redactionService]
  /// customizes its policy; pass `enableRedaction: false` only when bounded
  /// raw diagnostics are explicitly required.
  ///
  /// - Return: List of imported log entries
  /// - Usage example: `final logs = await service.importFromJson(jsonContent);`
  /// - Edge case notes: Supports legacy format, skips invalid entries, processes in chunks
  ///
  /// **Validation:**
  /// - Size: Max 32 MiB characters and 32 MiB encoded
  /// - Depth: Max 64 levels
  /// - Structure: Max 100,000 approximate nodes
  /// - Count: Max 100,000 entries
  ///
  /// **Security:** Prevents DoS attacks via malformed JSON
  Future<List<ISpectLogData>> importFromJson(
    String jsonString, {
    RedactionService? redactionService,
    bool enableRedaction = true,
  }) async =>
      (await importFromJsonWithReport(
        jsonString,
        redactionService: redactionService,
        enableRedaction: enableRedaction,
      ))
          .logs;

  /// Imports logs and reports entries that could not be decoded.
  Future<LogsImportResult> importFromJsonWithReport(
    String jsonString, {
    RedactionService? redactionService,
    bool enableRedaction = true,
  }) async {
    final limits = _resourceLimits;
    final scheduling = _processingPolicy;
    try {
      final dynamic jsonData = _decodeJson(
        jsonString,
        resourceLimits: limits,
      );

      final logsJson = _extractLogsFromJsonData(jsonData);

      _validateLogCount(logsJson);

      return await _processImportedLogsInChunks(
        logsJson,
        _effectiveRedactor(enableRedaction, redactionService),
        resourceLimits: limits,
        processingPolicy: scheduling,
      );
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Failed to import logs from JSON: $e');
    }
  }

  Object? _decodeJson(
    String jsonString, {
    DiagnosticResourceLimits? resourceLimits,
  }) {
    final limits = resourceLimits ?? _resourceLimits;
    return JsonInputPreflight.decode(
      jsonString,
      characterLimit: limits.maxImportCharacters,
      encodedByteLimit: limits.maxImportBytes,
      nestingDepthLimit: limits.maxTraversalDepth,
      approximateNodeLimit: limits.maxImportNodes,
    );
  }

  /// Validates log entry count to prevent excessive memory usage
  void _validateLogCount(List<dynamic> logsJson) {
    final maximum = _resourceLimits.maxImportEntries;
    if (logsJson.length > maximum) {
      throw FormatException(
        'Log count (${logsJson.length}) exceeds maximum allowed '
        'entries ($maximum). Please split the import into smaller batches.',
      );
    }
  }

  /// Extracts logs array from JSON data supporting both formats
  List<dynamic> _extractLogsFromJsonData(dynamic jsonData) {
    if (jsonData is Map<String, dynamic> && jsonData.containsKey('logs')) {
      final logs = jsonData['logs'];
      if (logs is! List<dynamic>) {
        throw const FormatException('Expected "logs" to be a List.');
      }
      return logs;
    }

    if (jsonData is List<dynamic>) {
      return jsonData;
    }

    throw const FormatException('Invalid JSON format for logs import');
  }

  /// Processes imported logs in chunks to prevent UI freezing
  Future<LogsImportResult> _processImportedLogsInChunks(
    List<dynamic> logsJson,
    RedactionService? redactor, {
    DiagnosticResourceLimits? resourceLimits,
    DiagnosticProcessingPolicy? processingPolicy,
  }) async {
    final limits = resourceLimits ?? _resourceLimits;
    final scheduling = processingPolicy ?? _processingPolicy;
    final logs = <ISpectLogData>[];
    var processed = 0;
    for (final chunk in Chunking.chunks(
      logsJson,
      scheduling.importChunkSize,
    )) {
      for (final logJson in chunk) {
        try {
          if (logJson is! Map<String, dynamic>) continue;
          final prepared = _prepareJsonLog(logJson, redactor, limits);
          final log = ISpectLogDataJsonUtils.fromJson(
            prepared,
            resourceLimits: _resourceLimits,
          );
          logs.add(log);
        } catch (_) {
          continue;
        }
      }
      processed++;
      await Chunking.yieldEvery(
        processed,
        scheduling.yieldEveryImportChunks,
      );
    }
    return LogsImportResult._(
      logs: logs,
      totalEntries: logsJson.length,
      skippedEntries: logsJson.length - logs.length,
    );
  }

  /// Creates and downloads a JSON file with logs
  ///
  /// - Parameters: logs (list of entries), fileName (base name), includeMetadata (flag)
  /// - Return: void (triggers file download)
  /// - Usage example: `await service.shareLogsAsJsonFile(logs, fileName: 'my_logs');`
  /// - Edge case notes: Validates non-empty logs, combines export and download operations
  Future<void> shareLogsAsJsonFile(
    List<ISpectLogData> logs, {
    required ISpectShareCallback onShare,
    String fileName = 'ispect_logs',
    bool includeMetadata = true,
    RedactionService? redactionService,
    bool enableRedaction = true,
    ISpectMetadata? metadata,
  }) async {
    if (logs.isEmpty) {
      ISpect.logger.info('No logs to export. Skipping file creation.');
      return;
    }

    final jsonContent = await exportToJson(
      logs,
      includeMetadata: includeMetadata,
      redactionService: redactionService,
      enableRedaction: enableRedaction,
      metadata: metadata,
    );
    await LogsFileFactory.shareFile(
      jsonContent,
      fileName: fileName,
      onShare: onShare,
    );
  }

  /// Exports filtered logs with current filter information
  ///
  /// - Parameters: logs (original list), filteredLogs (filtered list), filter (applied filter), fileName (base name), fileType (extension)
  /// - Return: void (triggers file download)
  /// - Usage example: `await service.shareFilteredLogsAsJsonFile(allLogs, filteredLogs, currentFilter);`
  /// - Edge case notes: Includes filter metadata for context, validates non-empty filtered logs
  Future<void> shareFilteredLogsAsJsonFile(
    List<ISpectLogData> logs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter, {
    required ISpectShareCallback onShare,
    String fileName = 'ispect_filtered_logs',
    String fileType = 'json',
    RedactionService? redactionService,
    bool enableRedaction = true,
    Set<String>? redactKeys,
    ISpectMetadata? metadata,
  }) async {
    if (filteredLogs.isEmpty) {
      ISpect.logger.info('No filtered logs to export. Skipping file creation.');
      return;
    }

    final content = formatFilteredContent(
      logs: logs,
      filteredLogs: filteredLogs,
      filter: filter,
      fileType: fileType,
      redactionService: redactionService,
      enableRedaction: enableRedaction,
      redactKeys: redactKeys,
      metadata: metadata,
    );

    await LogsFileFactory.shareFile(
      content,
      fileName: fileName,
      fileType: fileType,
      onShare: onShare,
    );
  }

  /// Saves filtered logs to device without requiring a share callback.
  ///
  /// Returns the file path (native) or filename (web).
  Future<String> saveFilteredLogsToDevice(
    List<ISpectLogData> logs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter, {
    String fileName = 'ispect_filtered_logs',
    String fileType = 'json',
    RedactionService? redactionService,
    bool enableRedaction = true,
    Set<String>? redactKeys,
    ISpectMetadata? metadata,
  }) async {
    if (filteredLogs.isEmpty) {
      ISpect.logger.info('No filtered logs to export. Skipping file creation.');
      return '';
    }

    final content = formatFilteredContent(
      logs: logs,
      filteredLogs: filteredLogs,
      filter: filter,
      fileType: fileType,
      redactionService: redactionService,
      enableRedaction: enableRedaction,
      redactKeys: redactKeys,
      metadata: metadata,
    );

    return LogsFileFactory.saveToDevice(
      content,
      fileName: fileName,
      fileType: fileType,
    );
  }

  /// Formats filtered logs into [fileType], applying redaction consistently
  /// across every format.
  ///
  /// When [enableRedaction] is true, every format uses [redactionService] when
  /// supplied. Otherwise [redactKeys] derive a local service; when neither is
  /// supplied, every format resolves the global policy.
  @visibleForTesting
  String formatFilteredContent({
    required List<ISpectLogData> logs,
    required List<ISpectLogData> filteredLogs,
    required ISpectFilter filter,
    required String fileType,
    RedactionService? redactionService,
    bool enableRedaction = true,
    Set<String>? redactKeys,
    ISpectMetadata? metadata,
  }) {
    final effectiveService = _effectiveRedactor(
      enableRedaction,
      redactionService,
      sensitiveKeys: redactKeys,
    );

    switch (fileType) {
      case 'txt':
        return LogExporter.toText(
          filteredLogs,
          redactKeys: redactKeys,
          redactionService: effectiveService,
          metadata: metadata,
          enableRedaction: enableRedaction,
          resourceLimits: _resourceLimits,
        );
      case 'md':
        return LogExporter.toMarkdown(
          filteredLogs,
          redactKeys: redactKeys,
          redactionService: effectiveService,
          metadata: metadata,
          enableRedaction: enableRedaction,
          resourceLimits: _resourceLimits,
        );
      case 'csv':
        return LogExporter.toCsv(
          filteredLogs,
          redactKeys: redactKeys,
          redactionService: effectiveService,
          enableRedaction: enableRedaction,
          resourceLimits: _resourceLimits,
        );
      default:
        final limits = _resourceLimits;
        final encoder = _JsonExportEncoder(
          includeMetadata: true,
          totalLogCount: logs.length,
          sourceLogCount: filteredLogs.length,
          metadata: _prepareJsonValue(
            _createFilteredMetadata(
              logs,
              filteredLogs,
              filter,
              metadata,
              effectiveService,
              limits,
            ),
            effectiveService,
            limits,
          ),
          redactor: effectiveService,
          resourceLimits: limits,
        );
        for (final log in filteredLogs) {
          if (!encoder.addLog(log)) break;
        }
        return encoder.finish();
    }
  }

  static Map<String, Object?> _prepareJsonLog(
    Map<String, dynamic> source,
    RedactionService? redactor,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final prepared = LogExportOutput.boundJsonValue(
      source,
      resourceLimits: resourceLimits,
      preserveTypes: redactor != null,
      replaceOversizedStrings: redactor != null,
    );
    final outbound = redactor == null
        ? prepared
        : redactor.redactEnvelopeForExport(
            prepared,
            rootValueKeys: const {'key'},
            resourceLimits: resourceLimits,
          );
    final bounded = LogExportOutput.boundJsonValue(
      outbound,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactor != null,
    );
    return bounded is Map<String, Object?>
        ? bounded
        : const {'message': JsonValueNormalizer.unprintableValue};
  }

  static Object? _prepareJsonValue(
    Object? source,
    RedactionService? redactor,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final prepared = LogExportOutput.boundJsonValue(
      source,
      resourceLimits: resourceLimits,
      preserveTypes: redactor != null,
      replaceOversizedStrings: redactor != null,
    );
    final outbound = redactor == null
        ? prepared
        : redactor.redactForExport(
            prepared,
            resourceLimits: resourceLimits,
          );
    return LogExportOutput.boundJsonValue(
      outbound,
      resourceLimits: resourceLimits,
      replaceOversizedStrings: redactor != null,
    );
  }

  static RedactionService? _effectiveRedactor(
    bool enableRedaction,
    RedactionService? redactionService, {
    Set<String>? sensitiveKeys,
  }) {
    if (!enableRedaction || !ISpectRedaction.enabled) return null;
    return ISpectRedaction.resolveService(
      service: redactionService,
      sensitiveKeys: sensitiveKeys,
    );
  }

  /// Creates metadata for filtered export including filter information
  Map<String, dynamic> _createFilteredMetadata(
    List<ISpectLogData> logs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter,
    ISpectMetadata? metadata,
    RedactionService? redactor,
    DiagnosticResourceLimits resourceLimits,
  ) {
    final result = <String, dynamic>{
      'exportedAt': DateTime.now().toIso8601String(),
      'totalLogs': logs.length,
      'filteredLogs': filteredLogs.length,
      'platform': 'ispect',
      'appliedFilter': _createFilterSummary(filter),
    };
    _appendHostMetadata(result, metadata, redactor, resourceLimits);
    return result;
  }

  static void _appendHostMetadata(
    Map<String, dynamic> result,
    ISpectMetadata? metadata,
    RedactionService? redactor,
    DiagnosticResourceLimits resourceLimits,
  ) {
    if (metadata == null) return;
    final typedFields = <String, Object?>{
      if (metadata.appName != null) 'appName': metadata.appName,
      if (metadata.appVersion != null) 'appVersion': metadata.appVersion,
      if (metadata.buildNumber != null) 'buildNumber': metadata.buildNumber,
      if (metadata.environment != null) 'environment': metadata.environment,
      if (metadata.device != null) 'device': metadata.device,
      if (metadata.os != null) 'os': metadata.os,
      if (metadata.osVersion != null) 'osVersion': metadata.osVersion,
      if (metadata.locale != null) 'locale': metadata.locale,
    };
    for (final entry in typedFields.entries) {
      result.putIfAbsent(entry.key, () => entry.value);
    }

    final boundedExtra = LogExportOutput.boundJsonValue(
      metadata.extra,
      resourceLimits: resourceLimits,
      preserveTypes: redactor != null,
      replaceOversizedStrings: redactor != null,
    );
    if (boundedExtra is! Map<String, Object?>) return;
    for (final entry in boundedExtra.entries) {
      result.putIfAbsent(entry.key, () => entry.value);
    }
  }

  /// Creates summary of applied filter
  Map<String, dynamic> _createFilterSummary(ISpectFilter filter) => {
        'hasSearchQuery':
            filter.filters.any((f) => f is SearchFilter && f.query.isNotEmpty),
        'logTypeKeyFiltersCount':
            filter.filters.whereType<LogTypeKeyFilter>().length,
        'typeFiltersCount': filter.filters.whereType<TypeFilter>().length,
      };

  /// Validates JSON structure for logs import
  ///
  /// - Parameters: jsonString (JSON content to validate)
  /// - Return: True if valid, false otherwise
  /// - Usage example: `final isValid = service.validateJsonStructure(jsonContent);`
  /// - Edge case notes: Checks structure without full parsing for performance
  bool validateJsonStructure(String jsonString) {
    try {
      final dynamic jsonData = _decodeJson(jsonString);
      return _isValidJsonStructure(jsonData);
    } catch (e) {
      return false;
    }
  }

  /// Checks if JSON data has valid structure for logs
  bool _isValidJsonStructure(dynamic jsonData) {
    if (jsonData is Map<String, dynamic> && jsonData.containsKey('logs')) {
      return jsonData['logs'] is List<dynamic>;
    }
    return jsonData is List<dynamic>;
  }

  /// Gets metadata from JSON export if available
  ///
  /// - Parameters: jsonString (JSON content to extract metadata from)
  /// - Return: Metadata map or null if not available
  /// - Usage example: `final metadata = service.getMetadataFromJson(jsonContent);`
  /// - Edge case notes: Returns null for legacy format or invalid JSON
  Map<String, dynamic>? getMetadataFromJson(String jsonString) {
    try {
      final dynamic jsonData = _decodeJson(jsonString);
      return _extractMetadata(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Extracts metadata from JSON data if available
  Map<String, dynamic>? _extractMetadata(dynamic jsonData) {
    if (jsonData is Map<String, dynamic> &&
        jsonData.containsKey(ISpectMetadata.exportKey)) {
      final metadata = jsonData[ISpectMetadata.exportKey];
      if (metadata is Map<String, dynamic>) return metadata;
    }
    return null;
  }

  DiagnosticResourceLimits get _resourceLimits {
    final limits = (resourceLimits ??
        ISpect.loggerIfInitialized?.options.resourceLimits ??
        DiagnosticResourceLimits.balanced)
      ..validate();
    return limits;
  }

  DiagnosticProcessingPolicy get _processingPolicy {
    final policy = (processingPolicy ??
        ISpect.loggerIfInitialized?.options.processingPolicy ??
        DiagnosticProcessingPolicy.balanced)
      ..validate();
    return policy;
  }
}

final class _JsonExportEncoder {
  _JsonExportEncoder({
    required bool includeMetadata,
    required this.totalLogCount,
    required this.sourceLogCount,
    required Object? metadata,
    required this.redactor,
    required this.resourceLimits,
  }) : _output = _JsonDocumentBuffer(resourceLimits.maxExportDocumentBytes) {
    resourceLimits.validate();
    String? encodedMetadata;
    if (includeMetadata) {
      var effectiveMetadata =
          metadata is Map<String, Object?> ? metadata : <String, Object?>{};
      final candidate = _metadataWithStats(
        effectiveMetadata,
        exportedLogs: sourceLogCount,
      );
      encodedMetadata = _encodePreparedValue(candidate);
      var metadataStats = _JsonStructureStats.scan(encodedMetadata);
      final metadataNodes = 1 + metadataStats.nodeContribution;
      final canUseMetadata = metadataStats.maxDepth <=
              resourceLimits.maxTraversalDepth - 1 &&
          _approximateNodes + metadataNodes <= resourceLimits.maxExportNodes;
      if (!canUseMetadata) {
        effectiveMetadata = const <String, Object?>{};
        encodedMetadata = _encodePreparedValue(
          _metadataWithStats(
            effectiveMetadata,
            exportedLogs: sourceLogCount,
          ),
        );
        metadataStats = _JsonStructureStats.scan(encodedMetadata);
      }
      _metadata = effectiveMetadata;
      _approximateNodes += 1 + metadataStats.nodeContribution;
    }
    _metadataSuffixBytes = encodedMetadata == null
        ? 2
        : LogExportOutput.utf8Length(
            '],"${ISpectMetadata.exportKey}":$encodedMetadata}',
          );
    _output.writeAll(
      const ['{"logs":['],
      reservedBytes: _metadataSuffixBytes,
    );
  }

  final int totalLogCount;
  final int sourceLogCount;
  final RedactionService? redactor;
  final DiagnosticResourceLimits resourceLimits;
  final _JsonDocumentBuffer _output;
  Map<String, Object?>? _metadata;
  late final int _metadataSuffixBytes;
  int _approximateNodes = 5;
  int _exportedLogs = 0;
  bool _hasLogs = false;
  bool _finished = false;

  bool addLog(ISpectLogData log) {
    if (_finished) return false;
    final capturedTime = captureISpectLogDataForEgress(log).time;
    final prepared = LogsJsonService._prepareJsonLog(
      log.toExportJson(redactionActive: redactor != null),
      redactor,
      resourceLimits,
    );
    var encoded = _encodeLog(prepared, capturedTime);
    var stats = _JsonStructureStats.scan(encoded);
    if (stats.maxDepth > resourceLimits.maxTraversalDepth - 2) {
      encoded = _fallbackLog(capturedTime);
      stats = _JsonStructureStats.scan(encoded);
    }
    final prefix = _hasLogs ? ',' : '';
    final additionalNodes = stats.nodeContribution + (_hasLogs ? 1 : 0);
    if (_approximateNodes + additionalNodes > resourceLimits.maxExportNodes) {
      return false;
    }
    if (!_output.writeAll(
      [prefix, encoded],
      reservedBytes: _metadataSuffixBytes,
    )) {
      return false;
    }
    _approximateNodes += additionalNodes;
    _hasLogs = true;
    _exportedLogs++;
    return true;
  }

  String finish() {
    if (!_finished) {
      final metadata = _metadata;
      if (metadata == null) {
        _output.writeAll(const [']}']);
      } else {
        final encodedMetadata = _encodePreparedValue(
          _metadataWithStats(metadata, exportedLogs: _exportedLogs),
        );
        _output.writeAll([
          '],"${ISpectMetadata.exportKey}":',
          encodedMetadata,
          '}',
        ]);
      }
      _finished = true;
    }
    return _output.toString();
  }

  Map<String, Object?> _metadataWithStats(
    Map<String, Object?> metadata, {
    required int exportedLogs,
  }) =>
      <String, Object?>{
        ...metadata,
        'totalLogs': totalLogCount,
        'exportedLogs': exportedLogs,
        'truncated': exportedLogs < sourceLogCount,
      };

  String _encodePreparedValue(Object? value) {
    try {
      final encoded = jsonEncode(value);
      return LogExportOutput.utf8Length(
                encoded,
                limit: resourceLimits.maxLogRecordBytes,
              ) <=
              resourceLimits.maxLogRecordBytes
          ? encoded
          : 'null';
    } catch (_) {
      return 'null';
    }
  }

  String _encodeLog(
    Map<String, Object?> prepared,
    DateTime capturedTime,
  ) {
    if (!prepared.containsKey('time') && !prepared.containsKey('message')) {
      return _fallbackLog(capturedTime);
    }
    try {
      final encoded = jsonEncode(prepared);
      if (LogExportOutput.utf8Length(
            encoded,
            limit: resourceLimits.maxLogRecordBytes,
          ) <=
          resourceLimits.maxLogRecordBytes) {
        return encoded;
      }
    } catch (_) {
      return _fallbackLog(capturedTime);
    }
    return _fallbackLog(capturedTime);
  }

  static String _fallbackLog(DateTime capturedTime) => jsonEncode({
        'time': capturedTime.toIso8601String(),
        'message': LogExportOutput.truncatedMarker,
        'export-error': LogExportOutput.truncatedMarker,
      });
}

final class _JsonStructureStats {
  const _JsonStructureStats({
    required this.nodeContribution,
    required this.maxDepth,
  });

  factory _JsonStructureStats.scan(String source) {
    var nodeContribution = 0;
    var depth = 0;
    var maxDepth = 0;
    var inString = false;
    var escaped = false;
    final containers = <int>[];

    for (var index = 0; index < source.length; index++) {
      final codeUnit = source.codeUnitAt(index);
      if (inString) {
        if (escaped) {
          escaped = false;
        } else if (codeUnit == 0x5c) {
          escaped = true;
        } else if (codeUnit == 0x22) {
          inString = false;
        }
        continue;
      }

      if (codeUnit == 0x22) {
        inString = true;
      } else if (codeUnit == 0x7b || codeUnit == 0x5b) {
        containers.add(codeUnit);
        depth++;
        if (depth > maxDepth) maxDepth = depth;
        nodeContribution++;
        if (codeUnit == 0x5b) nodeContribution++;
      } else if (codeUnit == 0x7d || codeUnit == 0x5d) {
        if (containers.isNotEmpty) containers.removeLast();
        if (depth > 0) depth--;
      } else if (codeUnit == 0x3a) {
        nodeContribution++;
      } else if (codeUnit == 0x2c &&
          containers.isNotEmpty &&
          containers.last == 0x5b) {
        nodeContribution++;
      }
    }

    return _JsonStructureStats(
      nodeContribution: nodeContribution,
      maxDepth: maxDepth,
    );
  }

  final int nodeContribution;
  final int maxDepth;
}

final class _JsonDocumentBuffer {
  _JsonDocumentBuffer(this.maxBytes);

  final int maxBytes;
  final StringBuffer _buffer = StringBuffer();
  int _bytes = 0;

  bool writeAll(List<String> values, {int reservedBytes = 0}) {
    var additionalBytes = 0;
    for (final value in values) {
      final remaining = maxBytes - reservedBytes - _bytes - additionalBytes;
      if (remaining < 0) return false;
      final valueBytes = LogExportOutput.utf8Length(value, limit: remaining);
      if (valueBytes > remaining) return false;
      additionalBytes += valueBytes;
    }
    for (final value in values) {
      _buffer.write(value);
    }
    _bytes += additionalBytes;
    return true;
  }

  @override
  String toString() => _buffer.toString();
}
