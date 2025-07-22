import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';

/// Example demonstrating JSON export/import functionality for logs.
///
/// This example shows how to use the new LogsJsonService to export and import
/// logs in JSON format instead of plain text.
class JsonLogsExample extends StatefulWidget {
  const JsonLogsExample({super.key});

  @override
  State<JsonLogsExample> createState() => _JsonLogsExampleState();
}

class _JsonLogsExampleState extends State<JsonLogsExample> {
  final LogsJsonService _jsonService = const LogsJsonService();
  final List<ISpectifyData> _sampleLogs = [];

  @override
  void initState() {
    super.initState();
    _generateSampleLogs();
  }

  /// Generates sample logs for demonstration.
  void _generateSampleLogs() {
    final now = DateTime.now();

    _sampleLogs.addAll([
      ISpectifyData(
        'User logged in successfully',
        time: now.subtract(const Duration(minutes: 5)),
        logLevel: LogLevel.info,
        title: 'Authentication',
        additionalData: {'userId': '12345', 'sessionId': 'abc123'},
      ),
      ISpectifyData(
        'Failed to load user preferences',
        time: now.subtract(const Duration(minutes: 3)),
        logLevel: LogLevel.warning,
        title: 'Settings',
        exception: Exception('Network timeout'),
      ),
      ISpectifyData(
        'Database connection established',
        time: now.subtract(const Duration(minutes: 2)),
        logLevel: LogLevel.debug,
        title: 'Database',
        additionalData: {'connectionPool': 'primary', 'latency': '45ms'},
      ),
      ISpectifyData(
        'Critical error: Payment processing failed',
        time: now.subtract(const Duration(minutes: 1)),
        logLevel: LogLevel.error,
        title: 'Payment',
        error: StateError('Invalid payment method'),
        additionalData: {'orderId': '98765', 'amount': 99.99},
      ),
    ]);
  }

  /// Demonstrates JSON export functionality.
  Future<void> _exportLogsAsJson() async {
    try {
      // Export all logs
      await _jsonService.shareLogsAsJsonFile(
        _sampleLogs,
        fileName: 'sample_logs_export',
        includeMetadata: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs exported as JSON successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Demonstrates filtered JSON export functionality.
  Future<void> _exportFilteredLogsAsJson() async {
    try {
      // Create a filter for error logs only
      final errorFilter = ISpectifyFilter();

      final filteredLogs =
          _sampleLogs.where((log) => log.logLevel == LogLevel.error).toList();

      await _jsonService.shareFilteredLogsAsJsonFile(
        _sampleLogs,
        filteredLogs,
        errorFilter,
        fileName: 'error_logs_only',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error logs exported as JSON successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Filtered export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Demonstrates JSON import functionality.
  Future<void> _importLogsFromJson() async {
    // In a real app, you would get JSON content from a file picker
    // For this example, we'll create a sample JSON
    final sampleJson =
        await _jsonService.exportToJson(_sampleLogs.take(2).toList());

    try {
      final importedLogs = await _jsonService.importFromJson(sampleJson);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${importedLogs.length} logs from JSON!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Demonstrates using the JSON service directly.
  Future<void> _shareLogsViaService() async {
    try {
      // Using the JSON service directly
      await _jsonService.shareLogsAsJsonFile(
        _sampleLogs,
        fileName: 'direct_service_export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logs shared via service as JSON!'),
            backgroundColor: Colors.purple,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Service share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('JSON Logs Export/Import'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sample Logs',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generated ${_sampleLogs.length} sample log entries',
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text(
                              'Info: ${_sampleLogs.where((log) => log.logLevel == LogLevel.info).length}'),
                          backgroundColor: Colors.blue.shade100,
                        ),
                        Chip(
                          label: Text(
                              'Warning: ${_sampleLogs.where((log) => log.logLevel == LogLevel.warning).length}'),
                          backgroundColor: Colors.orange.shade100,
                        ),
                        Chip(
                          label: Text(
                              'Error: ${_sampleLogs.where((log) => log.logLevel == LogLevel.error).length}'),
                          backgroundColor: Colors.red.shade100,
                        ),
                        Chip(
                          label: Text(
                              'Debug: ${_sampleLogs.where((log) => log.logLevel == LogLevel.debug).length}'),
                          backgroundColor: Colors.green.shade100,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'JSON Export/Import Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _exportLogsAsJson,
              icon: const Icon(Icons.file_download),
              label: const Text('Export All Logs as JSON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _exportFilteredLogsAsJson,
              icon: const Icon(Icons.filter_alt),
              label: const Text('Export Error Logs Only (Filtered)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _importLogsFromJson,
              icon: const Icon(Icons.file_upload),
              label: const Text('Import Logs from JSON'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _shareLogsViaService,
              icon: const Icon(Icons.share),
              label: const Text('Share via Service (JSON)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.amber.shade50,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber),
                        SizedBox(width: 8),
                        Text(
                          'JSON Format Benefits',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Structured data with metadata\n'
                      '• Import/export capabilities\n'
                      '• Filter context preservation\n'
                      '• Better for data analysis\n'
                      '• Cross-platform compatibility',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
