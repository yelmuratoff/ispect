import 'package:ispectify/src/history/file_log/session_cleanup_strategy.dart';

/// Snapshot of session metrics and configuration.
class SessionStatistics {
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

  final int totalDays;
  final int totalSize;
  final int totalEntries;
  final DateTime? oldestDate;
  final DateTime? newestDate;
  final int maxSessionDays;
  final Duration autoSaveInterval;
  final bool enableAutoSave;
  final int maxFileSize;
  final SessionCleanupStrategy cleanupStrategy;

  @override
  String toString() {
    final oldestStr = oldestDate?.toString() ?? 'None';
    final newestStr = newestDate?.toString() ?? 'None';

    return '''
Session Statistics:
- Total Days: $totalDays
- Total Size: ${_formatBytes(totalSize)}
- Total Entries: $totalEntries
- Date Range: $oldestStr to $newestStr
- Max Session Days: $maxSessionDays
- Auto-save: ${enableAutoSave ? 'Enabled (${autoSaveInterval.inSeconds}s)' : 'Disabled'}
- Max File Size: ${_formatBytes(maxFileSize)}
- Cleanup Strategy: ${cleanupStrategy.name}
''';
  }

  String _formatBytes(int bytes) {
    if (bytes == 0) return '0 B';

    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (bytes.bitLength - 1) ~/ 10;
    if (i < 0) i = 0;
    if (i >= suffixes.length) i = suffixes.length - 1;
    final value = bytes / (1 << (i * 10));

    return '${value.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
