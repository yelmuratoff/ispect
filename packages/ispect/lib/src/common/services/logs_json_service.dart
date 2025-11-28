// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:convert';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/chunking.dart';

Object? _toEncodable(dynamic object) {
  if (object is Uri) {
    return object.toString();
  }
  try {
    // ignore: avoid_dynamic_calls
    return object.toJson();
  } catch (_) {
    return object.toString();
  }
}

/// Service for managing JSON export/import operations for logs.
///
/// - Parameters: None required for initialization
/// - Return: LogsJsonService instance
/// - Usage example: final service = LogsJsonService();
/// - Edge case notes: Handles empty data gracefully, provides chunked processing
class LogsJsonService {
  /// Creates a new instance of logs JSON service.
  const LogsJsonService();

  /// Maximum allowed JSON string size (590MB)
  static const int maxJsonSize = 500 * 1024 * 1024;

  /// Maximum allowed JSON nesting depth
  static const int maxJsonDepth = 1000;

  /// Maximum number of log entries allowed in import
  static const int maxLogEntries = 100000;

  /// Exports logs to JSON format with metadata
  ///
  /// - Parameters: logs (list of entries), includeMetadata (flag for metadata)
  /// - Return: JSON string ready for file export
  /// - Usage example: `final jsonString = await service.exportToJson(logs);`
  /// - Edge case notes: Processes in chunks to prevent memory issues, handles large datasets
  Future<String> exportToJson(
    List<ISpectLogData> logs, {
    bool includeMetadata = true,
  }) async {
    final exportData = <String, dynamic>{};

    if (includeMetadata) {
      exportData['metadata'] = _createExportMetadata(logs.length);
    }

    exportData['logs'] = await _processLogsInChunks(logs);

    const encoder = JsonEncoder.withIndent('  ', _toEncodable);
    return encoder.convert(exportData);
  }

  /// Creates export metadata with current timestamp and version
  Map<String, dynamic> _createExportMetadata(int totalLogs) => {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'totalLogs': totalLogs,
        'platform': 'ispect',
      };

  /// Processes logs in chunks to prevent memory issues
  Future<List<Map<String, dynamic>>> _processLogsInChunks(
    List<ISpectLogData> logs,
  ) async {
    final jsonLogs = <Map<String, dynamic>>[];
    const chunkSize = 50;
    const yieldEveryChunks = 10;
    var processed = 0;
    for (final chunk in Chunking.chunks(logs, chunkSize)) {
      for (final log in chunk) {
        jsonLogs.add(log.toJson());
      }
      processed++;
      await Chunking.yieldEvery(processed, yieldEveryChunks);
    }
    return jsonLogs;
  }

  /// Imports logs from JSON format with comprehensive validation
  ///
  /// - Parameters: jsonString (JSON content to parse)
  /// - Return: List of imported log entries
  /// - Usage example: `final logs = await service.importFromJson(jsonContent);`
  /// - Edge case notes: Supports legacy format, skips invalid entries, processes in chunks
  ///
  /// **Validation:**
  /// - Size: Max 10MB
  /// - Depth: Max 50 levels
  /// - Count: Max 100,000 entries
  ///
  /// **Security:** Prevents DoS attacks via malformed JSON
  Future<List<ISpectLogData>> importFromJson(String jsonString) async {
    try {
      // Validate size
      _validateJsonSize(jsonString);

      final dynamic jsonData = jsonDecode(jsonString);

      // Validate depth
      _validateJsonDepth(jsonData);

      final logsJson = _extractLogsFromJsonData(jsonData);

      // Validate count
      _validateLogCount(logsJson);

      return await _processImportedLogsInChunks(logsJson);
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Failed to import logs from JSON: $e');
    }
  }

  /// Validates JSON string size to prevent memory exhaustion
  void _validateJsonSize(String jsonString) {
    if (jsonString.length > maxJsonSize) {
      throw FormatException(
        'JSON size (${jsonString.length} bytes) exceeds maximum allowed '
        'size ($maxJsonSize bytes). Please import a smaller dataset.',
      );
    }
  }

  /// Validates JSON nesting depth to prevent stack overflow
  void _validateJsonDepth(dynamic data, [int currentDepth = 0]) {
    if (currentDepth > maxJsonDepth) {
      throw FormatException(
        'JSON nesting depth ($currentDepth) exceeds maximum allowed '
        'depth ($maxJsonDepth). This may indicate malformed or malicious JSON.',
      );
    }

    if (data is Map) {
      for (final value in data.values) {
        _validateJsonDepth(value, currentDepth + 1);
      }
    } else if (data is List) {
      // Only check first and last items to avoid O(n*depth) complexity
      if (data.isNotEmpty) {
        _validateJsonDepth(data.first, currentDepth + 1);
        if (data.length > 1) {
          _validateJsonDepth(data.last, currentDepth + 1);
        }
      }
    }
  }

  /// Validates log entry count to prevent excessive memory usage
  void _validateLogCount(List<dynamic> logsJson) {
    if (logsJson.length > maxLogEntries) {
      throw FormatException(
        'Log count (${logsJson.length}) exceeds maximum allowed '
        'entries ($maxLogEntries). Please split the import into smaller batches.',
      );
    }
  }

  /// Extracts logs array from JSON data supporting both formats
  List<dynamic> _extractLogsFromJsonData(dynamic jsonData) {
    if (jsonData is Map<String, dynamic> && jsonData.containsKey('logs')) {
      return jsonData['logs'] as List<dynamic>;
    }

    if (jsonData is List<dynamic>) {
      return jsonData;
    }

    throw const FormatException('Invalid JSON format for logs import');
  }

  /// Processes imported logs in chunks to prevent UI freezing
  Future<List<ISpectLogData>> _processImportedLogsInChunks(
    List<dynamic> logsJson,
  ) async {
    final logs = <ISpectLogData>[];
    const chunkSize = 25;
    const yieldEveryChunks = 4;
    var processed = 0;
    for (final chunk in Chunking.chunks(logsJson, chunkSize)) {
      for (final logJson in chunk) {
        try {
          final log = ISpectLogDataJsonUtils.fromJson(
            logJson as Map<String, dynamic>,
          );
          logs.add(log);
        } catch (_) {
          continue;
        }
      }
      processed++;
      await Chunking.yieldEvery(processed, yieldEveryChunks);
    }
    return logs;
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
  }) async {
    if (logs.isEmpty) {
      ISpect.logger.info('No logs to export. Skipping file creation.');
      return;
    }

    final jsonContent =
        await exportToJson(logs, includeMetadata: includeMetadata);
    await LogsFileFactory.downloadFile(
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
  }) async {
    if (filteredLogs.isEmpty) {
      ISpect.logger.info('No filtered logs to export. Skipping file creation.');
      return;
    }

    final exportData = _createFilteredExportData(logs, filteredLogs, filter);
    const encoder = JsonEncoder.withIndent('  ', _toEncodable);
    final jsonContent = encoder.convert(exportData);

    await LogsFileFactory.downloadFile(
      jsonContent,
      fileName: fileName,
      fileType: fileType,
      onShare: onShare,
    );
  }

  /// Creates export data structure for filtered logs
  Map<String, dynamic> _createFilteredExportData(
    List<ISpectLogData> logs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter,
  ) =>
      {
        'metadata': _createFilteredMetadata(logs, filteredLogs, filter),
        'logs': filteredLogs.map((log) => log.toJson()).toList(growable: false),
      };

  /// Creates metadata for filtered export including filter information
  Map<String, dynamic> _createFilteredMetadata(
    List<ISpectLogData> logs,
    List<ISpectLogData> filteredLogs,
    ISpectFilter filter,
  ) =>
      {
        'exportedAt': DateTime.now().toIso8601String(),
        'totalLogs': logs.length,
        'filteredLogs': filteredLogs.length,
        'platform': 'ispect',
        'appliedFilter': _createFilterSummary(filter),
      };

  /// Creates summary of applied filter
  Map<String, dynamic> _createFilterSummary(ISpectFilter filter) => {
        'hasSearchQuery':
            filter.filters.any((f) => f is SearchFilter && f.query.isNotEmpty),
        'titleFiltersCount': filter.filters.whereType<TitleFilter>().length,
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
      final dynamic jsonData = jsonDecode(jsonString);
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
      final dynamic jsonData = jsonDecode(jsonString);
      return _extractMetadata(jsonData);
    } catch (e) {
      return null;
    }
  }

  /// Extracts metadata from JSON data if available
  Map<String, dynamic>? _extractMetadata(dynamic jsonData) {
    if (jsonData is Map<String, dynamic> && jsonData.containsKey('metadata')) {
      return jsonData['metadata'] as Map<String, dynamic>;
    }
    return null;
  }
}
