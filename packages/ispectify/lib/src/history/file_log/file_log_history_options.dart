import 'package:ispectify/src/history/file_log/file_log_history_exception.dart';
import 'package:ispectify/src/history/file_log/session_cleanup_strategy.dart';
import 'package:meta/meta.dart';

typedef FileLogDirectoryProvider = Future<String> Function();
typedef FileLogHistoryErrorHandler = void Function(
  FileLogHistoryException error,
);

@immutable
final class FileLogHistoryOptions {
  const FileLogHistoryOptions({
    this.maxSessionDays = 7,
    this.maxFileSize = 5 * 1024 * 1024,
    this.maxTotalSize = 50 * 1024 * 1024,
    this.autoSaveInterval = const Duration(seconds: 1),
    this.maxBatchItems = 100,
    this.enableAutoSave = true,
    this.cleanupStrategy = SessionCleanupStrategy.deleteOldest,
    this.onError,
  });

  final int maxSessionDays;
  final int maxFileSize;
  final int maxTotalSize;
  final Duration autoSaveInterval;
  final int maxBatchItems;
  final bool enableAutoSave;
  final SessionCleanupStrategy cleanupStrategy;
  final FileLogHistoryErrorHandler? onError;

  void validate() {
    if (maxSessionDays <= 0) {
      throw ArgumentError.value(maxSessionDays, 'maxSessionDays');
    }
    if (maxFileSize <= 0) {
      throw ArgumentError.value(maxFileSize, 'maxFileSize');
    }
    if (maxTotalSize < maxFileSize) {
      throw ArgumentError.value(maxTotalSize, 'maxTotalSize');
    }
    if (maxBatchItems <= 0) {
      throw ArgumentError.value(maxBatchItems, 'maxBatchItems');
    }
    if (autoSaveInterval <= Duration.zero) {
      throw ArgumentError.value(autoSaveInterval, 'autoSaveInterval');
    }
  }
}
