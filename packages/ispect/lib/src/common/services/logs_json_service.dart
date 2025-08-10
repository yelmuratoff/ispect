// ignore_for_file: avoid_annotating_with_dynamic

import 'dart:convert';

import 'package:ispect/ispect.dart';

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

  /// Exports logs to JSON format with metadata
  ///
  /// - Parameters: logs (list of entries), includeMetadata (flag for metadata)
  /// - Return: JSON string ready for file export
  /// - Usage example: `final jsonString = await service.exportToJson(logs);`
  /// - Edge case notes: Processes in chunks to prevent memory issues, handles large datasets
  Future<String> exportToJson(
    List<ISpectifyData> logs, {
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
    List<ISpectifyData> logs,
  ) async {
    final jsonLogs = <Map<String, dynamic>>[];
    const chunkSize = 50;

    for (var i = 0; i < logs.length; i += chunkSize) {
      final chunk = logs.skip(i).take(chunkSize);

      for (final log in chunk) {
        jsonLogs.add(log.toJson());
      }

      if (i % (chunkSize * 10) == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    return jsonLogs;
  }

  /// Imports logs from JSON format
  ///
  /// - Parameters: jsonString (JSON content to parse)
  /// - Return: List of imported log entries
  /// - Usage example: `final logs = await service.importFromJson(jsonContent);`
  /// - Edge case notes: Supports legacy format, skips invalid entries, processes in chunks
  Future<List<ISpectifyData>> importFromJson(String jsonString) async {
    try {
      final dynamic jsonData = jsonDecode(jsonString);
      final logsJson = _extractLogsFromJsonData(jsonData);

      return await _processImportedLogsInChunks(logsJson);
    } catch (e) {
      throw FormatException('Failed to import logs from JSON: $e');
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
  Future<List<ISpectifyData>> _processImportedLogsInChunks(
    List<dynamic> logsJson,
  ) async {
    final logs = <ISpectifyData>[];
    const chunkSize = 25;

    for (var i = 0; i < logsJson.length; i += chunkSize) {
      final chunk = logsJson.skip(i).take(chunkSize);

      for (final logJson in chunk) {
        try {
          final log = ISpectifyDataJsonUtils.fromJson(
            logJson as Map<String, dynamic>,
          );
          logs.add(log);
        } catch (e) {
          continue;
        }
      }

      if (i % (chunkSize * 4) == 0) {
        await Future<void>.delayed(Duration.zero);
      }
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
    List<ISpectifyData> logs, {
    String fileName = 'ispect_logs',
    bool includeMetadata = true,
  }) async {
    if (logs.isEmpty) {
      throw ArgumentError('Cannot export empty logs list');
    }

    final jsonContent =
        await exportToJson(logs, includeMetadata: includeMetadata);
    await LogsFileFactory.downloadFile(
      jsonContent,
      fileName: fileName,
    );
  }

  /// Exports filtered logs with current filter information
  ///
  /// - Parameters: logs (original list), filteredLogs (filtered list), filter (applied filter), fileName (base name), fileType (extension)
  /// - Return: void (triggers file download)
  /// - Usage example: `await service.shareFilteredLogsAsJsonFile(allLogs, filteredLogs, currentFilter);`
  /// - Edge case notes: Includes filter metadata for context, validates non-empty filtered logs
  Future<void> shareFilteredLogsAsJsonFile(
    List<ISpectifyData> logs,
    List<ISpectifyData> filteredLogs,
    ISpectifyFilter filter, {
    String fileName = 'ispect_filtered_logs',
    String fileType = 'json',
  }) async {
    if (filteredLogs.isEmpty) {
      throw ArgumentError('Cannot export empty filtered logs list');
    }

    final exportData = _createFilteredExportData(logs, filteredLogs, filter);
    const encoder = JsonEncoder.withIndent('  ', _toEncodable);
    final jsonContent = encoder.convert(exportData);

    await LogsFileFactory.downloadFile(
      jsonContent,
      fileName: fileName,
      fileType: fileType,
    );
  }

  /// Creates export data structure for filtered logs
  Map<String, dynamic> _createFilteredExportData(
    List<ISpectifyData> logs,
    List<ISpectifyData> filteredLogs,
    ISpectifyFilter filter,
  ) =>
      {
        'metadata': _createFilteredMetadata(logs, filteredLogs, filter),
        'logs': filteredLogs.map((log) => log.toJson()).toList(),
      };

  /// Creates metadata for filtered export including filter information
  Map<String, dynamic> _createFilteredMetadata(
    List<ISpectifyData> logs,
    List<ISpectifyData> filteredLogs,
    ISpectifyFilter filter,
  ) =>
      {
        'exportedAt': DateTime.now().toIso8601String(),
        'totalLogs': logs.length,
        'filteredLogs': filteredLogs.length,
        'platform': 'ispect',
        'appliedFilter': _createFilterSummary(filter),
      };

  /// Creates summary of applied filter
  Map<String, dynamic> _createFilterSummary(ISpectifyFilter filter) => {
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
