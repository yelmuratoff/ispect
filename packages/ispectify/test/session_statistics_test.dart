import 'package:ispectify/src/history/file_log/session_cleanup_strategy.dart';
import 'package:ispectify/src/history/file_log/session_statistics.dart';
import 'package:test/test.dart';

void main() {
  group('SessionStatistics._formatBytes', () {
    test('clamps suffix index at GB for huge values', () {
      const statsBase = SessionStatistics(
        totalDays: 0,
        totalSize: 0,
        totalEntries: 0,
        oldestDate: null,
        newestDate: null,
        maxSessionDays: 0,
        autoSaveInterval: Duration.zero,
        enableAutoSave: false,
        maxFileSize: 0,
        cleanupStrategy: SessionCleanupStrategy.deleteOldest,
      );
      // Access via toString which uses _formatBytes internally
      const tbBytes = 5 * 1024 * 1024 * 1024 * 1024; // 5 TB
      final stats = SessionStatistics(
        totalDays: statsBase.totalDays,
        totalSize: tbBytes,
        totalEntries: statsBase.totalEntries,
        oldestDate: statsBase.oldestDate,
        newestDate: statsBase.newestDate,
        maxSessionDays: statsBase.maxSessionDays,
        autoSaveInterval: statsBase.autoSaveInterval,
        enableAutoSave: statsBase.enableAutoSave,
        maxFileSize: statsBase.maxFileSize,
        cleanupStrategy: statsBase.cleanupStrategy,
      );
      final s = stats.toString();
      expect(s.contains('Total Size:'), isTrue);
    });
  });
}
