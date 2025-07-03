import 'dart:convert';

import 'package:ispect/ispect.dart';

/// Service for managing JSON export/import operations for logs.
///
/// - Parameters: None required for initialization
/// - Return: LogsJsonService instance
/// - Usage example: final service = LogsJsonService();
/// - Edge case notes: Handles empty data gracefully, provides chunked processing
class LogsJsonService {
  /// Creates a new instance of logs JSON service.
  const LogsJsonService();

  /// Exports logs to JSON format with metadata.
  ///
  /// Creates a structured JSON file containing:
  /// - Export metadata (timestamp, version, count)
  /// - Formatted log entries with all available data
  ///
  /// **Parameters:**
  /// - [logs]: List of log entries to export
  /// - [includeMetadata]: Whether to include export metadata (default: true)
  ///
  /// **Returns:** JSON string ready for file export
  ///
  /// **Example:**
  /// ```dart
  /// final service = LogsJsonService();
  /// final jsonString = await service.exportToJson(logs);
  /// ```
  Future<String> exportToJson(
    List<ISpectifyData> logs, {
    bool includeMetadata = true,
  }) async {
    final exportData = <String, dynamic>{};

    // Add metadata if requested
    if (includeMetadata) {
      exportData['metadata'] = {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'totalLogs': logs.length,
        'platform': 'ispect',
      };
    }

    // Process logs in chunks to prevent memory issues
    final jsonLogs = <Map<String, dynamic>>[];
    const chunkSize = 50;

    for (var i = 0; i < logs.length; i += chunkSize) {
      final chunk = logs.skip(i).take(chunkSize);

      for (final log in chunk) {
        jsonLogs.add(log.toJson());
      }

      // Yield control periodically for large datasets
      if (i % (chunkSize * 10) == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    exportData['logs'] = jsonLogs;

    // Use pretty print for better readability
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(exportData);
  }

  /// Imports logs from JSON format.
  ///
  /// Parses JSON file and converts back to ISpectifyData objects.
  /// Supports both legacy format (array of logs) and new format (with metadata).
  ///
  /// **Parameters:**
  /// - [jsonString]: JSON content to parse
  ///
  /// **Returns:** List of imported log entries
  ///
  /// **Example:**
  /// ```dart
  /// final service = LogsJsonService();
  /// final logs = await service.importFromJson(jsonContent);
  /// ```
  Future<List<ISpectifyData>> importFromJson(String jsonString) async {
    try {
      final dynamic jsonData = jsonDecode(jsonString);
      List<dynamic> logsJson;

      // Handle both new format (with metadata) and legacy format
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('logs')) {
        logsJson = jsonData['logs'] as List<dynamic>;
      } else if (jsonData is List<dynamic>) {
        logsJson = jsonData;
      } else {
        throw const FormatException('Invalid JSON format for logs import');
      }

      final logs = <ISpectifyData>[];
      const chunkSize = 25;

      // Process in chunks to prevent UI freezing
      for (var i = 0; i < logsJson.length; i += chunkSize) {
        final chunk = logsJson.skip(i).take(chunkSize);

        for (final logJson in chunk) {
          try {
            final log = ISpectifyDataJsonUtils.fromJson(
              logJson as Map<String, dynamic>,
            );
            logs.add(log);
          } catch (e) {
            // Skip invalid log entries but continue processing
            continue;
          }
        }

        // Yield control
        if (i % (chunkSize * 4) == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }

      return logs;
    } catch (e) {
      throw FormatException('Failed to import logs from JSON: $e');
    }
  }

  /// Creates and downloads a JSON file with logs.
  ///
  /// Combines export and download operations into a single method.
  /// Uses platform-appropriate file handling.
  ///
  /// **Parameters:**
  /// - [logs]: List of log entries to export
  /// - [fileName]: Base name for the file (default: 'ispect_logs')
  /// - [includeMetadata]: Whether to include export metadata
  ///
  /// **Example:**
  /// ```dart
  /// final service = LogsJsonService();
  /// await service.shareLogsAsJsonFile(logs, fileName: 'my_logs');
  /// ```
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

  /// Exports filtered logs with current filter information.
  ///
  /// Includes filter metadata in the export for better context.
  ///
  /// **Parameters:**
  /// - [logs]: Original logs list
  /// - [filteredLogs]: Filtered logs to export
  /// - [filter]: Applied filter for metadata
  /// - [fileName]: Base name for the file
  ///
  /// **Example:**
  /// ```dart
  /// final service = LogsJsonService();
  /// await service.shareFilteredLogsAsJsonFile(
  ///   allLogs,
  ///   filteredLogs,
  ///   currentFilter,
  /// );
  /// ```
  Future<void> shareFilteredLogsAsJsonFile(
    List<ISpectifyData> logs,
    List<ISpectifyData> filteredLogs,
    ISpectifyFilter filter, {
    String fileName = 'ispect_filtered_logs',
  }) async {
    if (filteredLogs.isEmpty) {
      throw ArgumentError('Cannot export empty filtered logs list');
    }

    final exportData = <String, dynamic>{
      'metadata': {
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'totalLogs': logs.length,
        'filteredLogs': filteredLogs.length,
        'platform': 'ispect',
        'appliedFilter': {
          'hasSearchQuery': filter.filters
              .any((f) => f is SearchFilter && f.query.isNotEmpty),
          'titleFiltersCount': filter.filters.whereType<TitleFilter>().length,
          'typeFiltersCount': filter.filters.whereType<TypeFilter>().length,
        },
      },
      'logs': filteredLogs.map((log) => log.toJson()).toList(),
    };

    const encoder = JsonEncoder.withIndent('  ');
    final jsonContent = encoder.convert(exportData);

    await LogsFileFactory.downloadFile(
      jsonContent,
      fileName: fileName,
    );
  }

  /// Validates JSON structure for logs import.
  ///
  /// Checks if the JSON structure is valid for import without full parsing.
  ///
  /// **Parameters:**
  /// - [jsonString]: JSON content to validate
  ///
  /// **Returns:** True if valid, false otherwise
  bool validateJsonStructure(String jsonString) {
    try {
      final dynamic jsonData = jsonDecode(jsonString);

      // Check for new format
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('logs')) {
        return jsonData['logs'] is List<dynamic>;
      }

      // Check for legacy format
      return jsonData is List<dynamic>;
    } catch (e) {
      return false;
    }
  }

  /// Gets metadata from JSON export if available.
  ///
  /// **Parameters:**
  /// - [jsonString]: JSON content to extract metadata from
  ///
  /// **Returns:** Metadata map or null if not available
  Map<String, dynamic>? getMetadataFromJson(String jsonString) {
    try {
      final dynamic jsonData = jsonDecode(jsonString);

      if (jsonData is Map<String, dynamic> &&
          jsonData.containsKey('metadata')) {
        return jsonData['metadata'] as Map<String, dynamic>;
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
