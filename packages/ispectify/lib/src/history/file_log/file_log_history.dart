import 'dart:async';

import 'package:ispectify/ispectify.dart';

export 'file_log_history_exception.dart';
export 'file_log_history_options.dart';
export 'rolling_file_log_history.dart';
export 'session_cleanup_strategy.dart';
export 'session_statistics.dart';

/// Extended [ILogHistory] with daily file-based persistence.
///
/// Implementations organize logs into per-day JSON files, support
/// auto-save, cleanup strategies, and import/export.
abstract class FileLogHistory implements ILogHistory {
  /// Persists current history to a daily-organized file.
  Future<void> saveToDailyFile();

  /// Replaces current history with entries from [date].
  /// Returns silently if the file does not exist.
  Future<void> loadFromDate(DateTime date);

  /// Convenience for `loadFromDate(DateTime.now())`.
  Future<void> loadTodayHistory();

  /// Serializes current history to a JSON string.
  Future<String> exportToJson();

  /// Appends entries parsed from [jsonString] to current history.
  Future<void> importFromJson(String jsonString);

  /// Removes all persisted log files.
  Future<void> clearAllFileStorage();

  /// Removes the log file for [date].
  Future<void> clearDateStorage(DateTime date);

  /// Path to the managed history directory.
  String get sessionDirectory;

  /// Path to today's log file.
  String get todaySessionPath;

  /// Sorted list of dates that have persisted log files.
  Future<List<DateTime>> getAvailableLogDates();

  /// File size in bytes for [date]. Returns 0 if the file does not exist.
  Future<int> getDateFileSize(DateTime date);

  /// Whether today's session file exists on disk.
  Future<bool> hasTodaySession();

  /// Reads logs for [date] without modifying current history.
  Future<List<ISpectLogData>> getLogsByDate(DateTime date);

  /// File or directory path for [date]. Returns empty string when absent.
  Future<String> getLogPathByDate(DateTime date);

  /// Reads logs from a managed segment, legacy file, or date-directory path.
  Future<List<ISpectLogData>> getLogsBySession(String sessionPath);

  /// Calculates comprehensive session statistics.
  Future<SessionStatistics> getSessionStatistics();

  /// Reconfigures auto-save at runtime.
  void updateAutoSaveSettings({bool? enabled, Duration? interval});
}
