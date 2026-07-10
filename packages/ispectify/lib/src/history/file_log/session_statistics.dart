import 'package:ispectify/src/history/file_log/session_cleanup_strategy.dart';
import 'package:ispectify/src/utils/common_utils.dart';

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
    this.maxTotalSize = 0,
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
  final int maxTotalSize;
  final SessionCleanupStrategy cleanupStrategy;

  @override
  String toString() {
    final oldestStr = oldestDate?.toString() ?? 'None';
    final newestStr = newestDate?.toString() ?? 'None';

    return '''
Session Statistics:
- Total Days: $totalDays
- Total Size: ${formatBytes(totalSize)}
- Total Entries: $totalEntries
- Date Range: $oldestStr to $newestStr
- Max Session Days: $maxSessionDays
- Auto-save: ${enableAutoSave ? 'Enabled (${autoSaveInterval.inSeconds}s)' : 'Disabled'}
- Max File Size: ${formatBytes(maxFileSize)}
- Max Total Size: ${formatBytes(maxTotalSize)}
- Cleanup Strategy: ${cleanupStrategy.name}
''';
  }
}
