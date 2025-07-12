// ignore_for_file: avoid_print

import 'package:ispectify/ispectify.dart';
import 'package:ispectify/src/history/file_log/file_log_history.dart';
import 'package:ispectify/src/history/file_log/session_cleanup_strategy.dart';

/// Comprehensive statistics about the current log session.
///
/// - totalDays: Number of days with log files
/// - totalSize: Total size of all log files in bytes
/// - totalEntries: Total number of log entries across all files
/// - oldestDate: Date of the oldest log file
/// - newestDate: Date of the newest log file
/// - maxSessionDays: Configured maximum session days
/// - autoSaveInterval: Current auto-save interval
/// - enableAutoSave: Whether auto-save is currently enabled
/// - maxFileSize: Maximum file size limit
/// - cleanupStrategy: Current cleanup strategy
class SessionStatistics {
  /// Creates session statistics with comprehensive metrics.
  ///
  /// - Parameters: All session-related metrics and configuration
  /// - Return: SessionStatistics instance
  /// - Usage example: Used by getSessionStatistics()
  /// - Edge case notes: Nullable dates when no files exist
  const SessionStatistics({
    required this.totalDays,
    required this.totalSize,
    required this.totalEntries,
    required this.oldestDate,
    required this.newestDate,
    required this.maxSessionDays,
    required this.autoSaveInterval,
    required this.enableAutoSave,
    required this.maxFileSize,
    required this.cleanupStrategy,
  });

  /// Number of days with log files
  final int totalDays;

  /// Total size of all log files in bytes
  final int totalSize;

  /// Total number of log entries across all files
  final int totalEntries;

  /// Date of the oldest log file (null if no files)
  final DateTime? oldestDate;

  /// Date of the newest log file (null if no files)
  final DateTime? newestDate;

  /// Configured maximum session days
  final int maxSessionDays;

  /// Current auto-save interval
  final Duration autoSaveInterval;

  /// Whether auto-save is currently enabled
  final bool enableAutoSave;

  /// Maximum file size limit in bytes
  final int maxFileSize;

  /// Current cleanup strategy
  final SessionCleanupStrategy cleanupStrategy;

  /// Converts statistics to a readable string format.
  ///
  /// - Parameters: None
  /// - Return: String formatted statistics summary
  /// - Usage example: print(stats.toString())
  /// - Edge case notes: Handles null dates gracefully
  @override
  String toString() {
    final oldestStr = oldestDate?.toString() ?? 'None';
    final newestStr = newestDate?.toString() ?? 'None';
    final sizeStr = _formatBytes(totalSize);

    return '''
Session Statistics:
- Total Days: $totalDays
- Total Size: $sizeStr
- Total Entries: $totalEntries
- Date Range: $oldestStr to $newestStr
- Max Session Days: $maxSessionDays
- Auto-save: ${enableAutoSave ? 'Enabled (${autoSaveInterval.inSeconds}s)' : 'Disabled'}
- Max File Size: ${_formatBytes(maxFileSize)}
- Cleanup Strategy: ${cleanupStrategy.name}
''';
  }

  /// Formats bytes into human-readable format.
  ///
  /// - Parameters: bytes - Number of bytes to format
  /// - Return: String formatted size (e.g., "1.5 MB")
  /// - Usage example: Used internally for display formatting
  /// - Edge case notes: Handles zero and large values
  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    final i = (bytes.bitLength - 1) ~/ 10;
    final value = bytes / (1 << (i * 10));

    return '${value.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
