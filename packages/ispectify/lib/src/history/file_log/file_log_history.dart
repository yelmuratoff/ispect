// ignore_for_file: avoid_print

import 'dart:async';

import 'package:ispectify/ispectify.dart';

export 'daily_file_log_history.dart';
export 'session_cleanup_strategy.dart';
export 'session_statistics.dart';

/// Extended interface for log history with daily file system support.
///
/// - Parameters: Extends ILogHistory with file-based persistence
/// - Return: Abstract interface for file-based log management
/// - Usage example: Implement this interface for custom file storage
/// - Edge case notes: All file operations are async and may throw IO exceptions
abstract class FileLogHistory implements ILogHistory {
  /// Saves the current history to daily organized files.
  ///
  /// - Parameters: None
  /// - Return: Future<void> completing when save is done
  /// - Usage example: await fileHistory.saveToDailyFile()
  /// - Edge case notes: Creates directory if not exists, handles concurrent writes
  Future<void> saveToDailyFile();

  /// Loads history from a specific date.
  ///
  /// - Parameters: date - The date to load logs from
  /// - Return: Future<void> completing when load is done
  /// - Usage example: await fileHistory.loadFromDate(DateTime(2024, 1, 1))
  /// - Edge case notes: Replaces current history, returns silently if file missing
  Future<void> loadFromDate(DateTime date);

  /// Loads history from today's file if exists.
  ///
  /// - Parameters: None
  /// - Return: Future<void> completing when load is done
  /// - Usage example: await fileHistory.loadTodayHistory()
  /// - Edge case notes: Convenience method for loadFromDate(DateTime.now())
  Future<void> loadTodayHistory();

  /// Exports history to JSON format.
  ///
  /// - Parameters: None
  /// - Return: Future<String> containing JSON representation
  /// - Usage example: final json = await fileHistory.exportToJson()
  /// - Edge case notes: Uses chunked processing for large datasets
  Future<String> exportToJson();

  /// Imports history from JSON format.
  ///
  /// - Parameters: jsonString - Valid JSON array of log entries
  /// - Return: Future<void> completing when import is done
  /// - Usage example: await fileHistory.importFromJson(jsonData)
  /// - Edge case notes: Adds to current history, validates JSON format
  Future<void> importFromJson(String jsonString);

  /// Clears all file-based storage.
  ///
  /// - Parameters: None
  /// - Return: Future<void> completing when clear is done
  /// - Usage example: await fileHistory.clearAllFileStorage()
  /// - Edge case notes: Removes all .json files in session directory
  Future<void> clearAllFileStorage();

  /// Clears specific date's storage.
  ///
  /// - Parameters: date - The date whose storage to clear
  /// - Return: Future<void> completing when clear is done
  /// - Usage example: await fileHistory.clearDateStorage(DateTime(2024, 1, 1))
  /// - Edge case notes: Silently succeeds if file doesn't exist
  Future<void> clearDateStorage(DateTime date);

  /// Gets the current session directory path.
  ///
  /// - Parameters: None
  /// - Return: String path to session directory
  /// - Usage example: final path = fileHistory.sessionDirectory
  /// - Edge case notes: Throws StateError if not initialized
  String get sessionDirectory;

  /// Gets today's session file path.
  ///
  /// - Parameters: None
  /// - Return: String path to today's log file
  /// - Usage example: final path = fileHistory.todaySessionPath
  /// - Edge case notes: Computed dynamically from current date
  String get todaySessionPath;

  /// Gets available log dates.
  ///
  /// - Parameters: None
  /// - Return: Future<List<DateTime>> of dates with log files
  /// - Usage example: final dates = await fileHistory.getAvailableLogDates()
  /// - Edge case notes: Returns sorted list, empty if no files found
  Future<List<DateTime>> getAvailableLogDates();

  /// Gets file size for a specific date.
  ///
  /// - Parameters: date - The date to check file size for
  /// - Return: Future<int> file size in bytes
  /// - Usage example: final size = await fileHistory.getDateFileSize(date)
  /// - Edge case notes: Returns 0 if file doesn't exist or on error
  Future<int> getDateFileSize(DateTime date);

  /// Checks if today's session file exists.
  ///
  /// - Parameters: None
  /// - Return: Future<bool> true if today's file exists
  /// - Usage example: if (await fileHistory.hasTodaySession()) { ... }
  /// - Edge case notes: Uses file system check, not memory cache
  Future<bool> hasTodaySession();

  /// Gets all logs for a specific date without modifying current history.
  ///
  /// - Parameters: date - The date to get logs for
  /// - Return: Future<List<ISpectifyData>> logs for the date
  /// - Usage example: final logs = await fileHistory.getLogsByDate(date)
  /// - Edge case notes: Read-only operation, returns empty list if no file
  Future<List<ISpectifyData>> getLogsByDate(DateTime date);

  /// Gets all logs for a specific session file without modifying current history.
  ///
  /// - Parameters: sessionPath - Path to the session file
  /// - Return: Future<List<ISpectifyData>> logs from the session
  /// - Usage example: final logs = await fileHistory.getLogsBySession(path)
  /// - Edge case notes: Read-only operation, returns empty list if no file
  Future<List<ISpectifyData>> getLogsBySession(String sessionPath);

  /// Gets comprehensive session statistics.
  ///
  /// - Parameters: None
  /// - Return: Future<SessionStatistics> with detailed session info
  /// - Usage example: final stats = await fileHistory.getSessionStatistics()
  /// - Edge case notes: Calculates total files, sizes, and date ranges
  Future<SessionStatistics> getSessionStatistics();

  /// Updates auto-save settings during runtime.
  ///
  /// - Parameters:
  ///   - enabled: Whether to enable auto-save
  ///   - interval: New auto-save interval (optional)
  /// - Return: void
  /// - Usage example: fileHistory.updateAutoSaveSettings(enabled: true, interval: Duration(minutes: 2))
  /// - Edge case notes: Recreates timer with new settings
  void updateAutoSaveSettings({bool? enabled, Duration? interval});
}
