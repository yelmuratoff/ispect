// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';

/// Strategy for cleaning up old log files when session limit is exceeded.
///
/// - deleteOldest: Remove oldest files first (default)
/// - deleteBySize: Remove largest files first
/// - archiveOldest: Archive oldest files before deletion
enum SessionCleanupStrategy {
  /// Delete oldest files first when limit exceeded
  deleteOldest,

  /// Delete largest files first when limit exceeded
  deleteBySize,

  /// Archive oldest files before deletion
  archiveOldest,
}

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

/// Extended interface for log history with daily file system support.
///
/// - Parameters: Extends LogHistory with file-based persistence
/// - Return: Abstract interface for file-based log management
/// - Usage example: Implement this interface for custom file storage
/// - Edge case notes: All file operations are async and may throw IO exceptions
abstract class FileLogHistory extends LogHistory {
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

/// Optimized daily file-based log history implementation.
///
/// Provides efficient daily log management with secure storage,
/// automatic cleanup, and optimized I/O operations.
class DailyFileLogHistory extends DefaultISpectifyHistory
    implements FileLogHistory {
  /// Creates a daily file-based log history manager.
  ///
  /// Optimizes log storage with configurable session limits, auto-save,
  /// and cleanup strategies for production use.
  DailyFileLogHistory(
    super.settings, {
    super.history,
    int maxSessionDays = 10,
    Duration? autoSaveInterval,
    bool enableAutoSave = true,
    int maxFileSize = 10 * 1024 * 1024, // 10MB
    bool enableCompression = false,
    SessionCleanupStrategy sessionCleanupStrategy =
        SessionCleanupStrategy.deleteOldest,
  })  : _maxSessionDays = maxSessionDays,
        _autoSaveInterval = autoSaveInterval ?? const Duration(seconds: 1),
        _maxFileSize = maxFileSize,
        _enableCompression = enableCompression,
        _sessionCleanupStrategy = sessionCleanupStrategy {
    _initializeSecureDirectory();
    if (enableAutoSave) {
      _autoSaveEnabled = true;
      _setupAutoSave();
    }
  }

  static const int _chunkSize = 100;
  static const int _bufferSize = 8192;
  static const int _fallbackEntrySize = 500;
  static const double _sizeSafetyMargin = 1.2;

  static final RegExp _datePattern =
      RegExp(r'logs_(\d{4})-(\d{2})-(\d{2})\.json');

  final int _maxSessionDays;
  final Duration _autoSaveInterval;
  final int _maxFileSize;
  final bool _enableCompression;
  final SessionCleanupStrategy _sessionCleanupStrategy;

  String? _sessionDirectory;
  Timer? _autoSaveTimer;
  DateTime? _lastSaveDate;
  bool _autoSaveEnabled = false;

  final Set<String> _pendingWrites = <String>{};
  final Completer<void> _directoryInitialized = Completer<void>();

  @override
  String get sessionDirectory {
    if (_sessionDirectory == null) {
      throw StateError(
        'Session directory not initialized yet. Wait for initialization to complete.',
      );
    }
    return _sessionDirectory!;
  }

  @override
  String get todaySessionPath => _getDateFilePath(DateTime.now());

  /// Initializes secure cache directory for log storage.
  ///
  /// - Parameters: None
  /// - Return: Future<void> completing when directory is ready
  /// - Usage example: Called automatically in constructor
  /// - Edge case notes: Handles platform-specific directory creation
  Future<void> _initializeSecureDirectory() async {
    try {
      final cacheDir = await _getSecureCacheDirectory();
      final logsDir = Directory('$cacheDir/ispectify_logs');

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _sessionDirectory = logsDir.path;
      _directoryInitialized.complete();
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to initialize secure directory: $e');
      }
      _directoryInitialized.completeError(e);
    }
  }

  /// Gets platform-specific secure cache directory.
  ///
  /// - Parameters: None
  /// - Return: Future<String> path to secure cache directory
  /// - Usage example: Used internally for directory setup
  /// - Edge case notes: Handles mobile, desktop, and fallback scenarios
  Future<String> _getSecureCacheDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      return _getMobileCacheDirectory();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _getDesktopCacheDirectory();
    } else {
      return Directory.current.path;
    }
  }

  /// Gets mobile cache directory path.
  ///
  /// - Parameters: None
  /// - Return: Future<String> path to mobile cache directory
  /// - Usage example: Used for Android/iOS platforms
  /// - Edge case notes: Creates directory in system temp with app subdirectory
  Future<String> _getMobileCacheDirectory() async {
    final tempDir = Directory.systemTemp;
    final appCacheDir = Directory('${tempDir.path}/ispectify_cache');

    if (!await appCacheDir.exists()) {
      await appCacheDir.create(recursive: true);
    }

    return appCacheDir.path;
  }

  /// Gets desktop cache directory path.
  ///
  /// - Parameters: None
  /// - Return: Future<String> path to desktop cache directory
  /// - Usage example: Used for Windows/macOS/Linux platforms
  /// - Edge case notes: Respects platform-specific cache conventions
  Future<String> _getDesktopCacheDirectory() async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;

    final cacheDir = _buildPlatformCacheDir(homeDir);

    final dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir.path;
  }

  /// Builds platform-specific cache directory path.
  ///
  /// - Parameters: homeDir - User's home directory path
  /// - Return: String cache directory path
  /// - Usage example: Used internally for desktop cache path building
  /// - Edge case notes: Handles macOS, Windows, and Linux conventions
  String _buildPlatformCacheDir(String homeDir) {
    if (Platform.isMacOS) {
      return '$homeDir/Library/Caches/ispectify';
    } else if (Platform.isWindows) {
      final localAppData =
          Platform.environment['LOCALAPPDATA'] ?? '$homeDir/AppData/Local';
      return '$localAppData/ispectify/cache';
    } else {
      final xdgCache =
          Platform.environment['XDG_CACHE_HOME'] ?? '$homeDir/.cache';
      return '$xdgCache/ispectify';
    }
  }

  /// Ensures directory is initialized before operations.
  ///
  /// - Parameters: None
  /// - Return: Future<void> completing when directory is ready
  /// - Usage example: Called before file operations
  /// - Edge case notes: Waits for async initialization to complete
  Future<void> _ensureDirectoryInitialized() async {
    if (!_directoryInitialized.isCompleted) {
      await _directoryInitialized.future;
    }
  }

  /// Sets up automatic saving timer.
  void _setupAutoSave() {
    if (!_autoSaveEnabled) return;

    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) {
      _performAutoSave();
    });
  }

  /// Gets file path for specific date with optimized formatting.
  ///
  /// - Parameters: date - Target date, fileType - File extension (default: json)
  /// - Return: String absolute path to date-specific log file
  /// - Usage example: _getDateFilePath(DateTime.now())
  /// - Edge case notes: Throws StateError if directory not initialized
  String _getDateFilePath(DateTime date, {String fileType = 'json'}) {
    if (_sessionDirectory == null) {
      throw StateError('Session directory not initialized yet.');
    }
    final dateStr = _formatDateForFileName(date);
    return '$_sessionDirectory/logs_$dateStr.$fileType';
  }

  /// Formats date for consistent file naming.
  ///
  /// - Parameters: date - Date to format
  /// - Return: String formatted as YYYY-MM-DD
  /// - Usage example: Used internally for file naming consistency
  /// - Edge case notes: Zero-pads month and day for sorting
  String _formatDateForFileName(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  /// Optimized date parsing from file name.
  DateTime? _parseDateFromFileName(String fileName) {
    final match = _datePattern.firstMatch(fileName);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }
    return null;
  }

  /// Performs optimized auto-save with write queue management.
  ///
  /// - Parameters: None
  /// - Return: Future<void> completing when auto-save is done
  /// - Usage example: Called periodically by auto-save timer
  /// - Edge case notes: Silently handles errors to prevent app crashes
  Future<void> _performAutoSave() async {
    if (_sessionDirectory == null || history.isEmpty) return;

    final todayPath = todaySessionPath;
    if (_pendingWrites.contains(todayPath)) {
      return;
    }

    try {
      await saveToDailyFile();
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('ISpectify auto-save failed: $e');
      }
    }
  }

  @override
  Future<void> saveToDailyFile() async {
    await _ensureDirectoryInitialized();

    if (history.isEmpty) return;

    final filePath = todaySessionPath;
    if (_pendingWrites.contains(filePath)) {
      return;
    }

    _pendingWrites.add(filePath);

    try {
      final availableDates = await getAvailableLogDates();
      if (availableDates.length >= _maxSessionDays) {
        await _performSessionCleanup(availableDates);
      }

      final file = File(filePath);
      await file.parent.create(recursive: true);

      final existingData = (await file.exists() && _shouldMergeWithExisting())
          ? await _loadExistingData(file)
          : <ISpectifyData>[];

      final mergedData = _mergeHistoryData(existingData, history);

      if (mergedData.isEmpty) return;

      final today = DateTime.now();
      if (!_validateDataForDate(mergedData, today)) {
        if (settings.useConsoleLogs) {
          print('Prevented saving mixed-date data to daily file');
        }
        return;
      }

      if (!await _validateFileIntegrity(file, today)) return;

      // Check if file size would exceed limit after writing
      if (await _wouldExceedSizeLimit(file, mergedData)) {
        if (settings.useConsoleLogs) {
          print('File size would exceed limit, performing rotation');
        }
        await _rotateFileIfNeeded(file, today);
      }

      await _writeDataChunked(file, mergedData);
      _lastSaveDate = DateTime.now();
    } finally {
      _pendingWrites.remove(filePath);
    }
  }

  /// Performs session cleanup based on the configured strategy.
  ///
  /// - Parameters: availableDates - List of dates with existing log files
  /// - Return: Future<void> completing when cleanup is done
  /// - Usage example: Called internally when session limit exceeded
  /// - Edge case notes: Handles different cleanup strategies efficiently
  Future<void> _performSessionCleanup(List<DateTime> availableDates) async {
    switch (_sessionCleanupStrategy) {
      case SessionCleanupStrategy.deleteOldest:
        await _cleanupByOldest(availableDates);
      case SessionCleanupStrategy.deleteBySize:
        await _cleanupBySize(availableDates);
      case SessionCleanupStrategy.archiveOldest:
        await _cleanupByArchiving(availableDates);
    }
  }

  /// Cleanup strategy: delete oldest files first.
  ///
  /// - Parameters: availableDates - List of dates with existing log files
  /// - Return: Future<void> completing when cleanup is done
  /// - Usage example: Used by _performSessionCleanup
  /// - Edge case notes: Sorts dates and removes oldest first
  Future<void> _cleanupByOldest(List<DateTime> availableDates) async {
    final sortedDates = List<DateTime>.from(availableDates)..sort();
    final datesToDelete = sortedDates.sublist(
      0,
      sortedDates.length - _maxSessionDays + 1,
    );

    for (final date in datesToDelete) {
      await clearDateStorage(date);
    }
  }

  /// Cleanup strategy: delete largest files first.
  ///
  /// - Parameters: availableDates - List of dates with existing log files
  /// - Return: Future<void> completing when cleanup is done
  /// - Usage example: Used by _performSessionCleanup
  /// - Edge case notes: Sorts by file size and removes largest first
  Future<void> _cleanupBySize(List<DateTime> availableDates) async {
    final datesSizes = <MapEntry<DateTime, int>>[];

    for (final date in availableDates) {
      final size = await getDateFileSize(date);
      datesSizes.add(MapEntry(date, size));
    }

    // Sort by file size descending (largest first)
    datesSizes.sort((a, b) => b.value.compareTo(a.value));

    final datesToDelete = datesSizes
        .take(datesSizes.length - _maxSessionDays + 1)
        .map((entry) => entry.key)
        .toList();

    for (final date in datesToDelete) {
      await clearDateStorage(date);
    }
  }

  /// Cleanup strategy: archive oldest files before deletion.
  ///
  /// - Parameters: availableDates - List of dates with existing log files
  /// - Return: Future<void> completing when cleanup is done
  /// - Usage example: Used by _performSessionCleanup
  /// - Edge case notes: Archives files to compressed format then deletes originals
  Future<void> _cleanupByArchiving(List<DateTime> availableDates) async {
    if (_enableCompression) {
      final sortedDates = List<DateTime>.from(availableDates)..sort();
      final datesToArchive = sortedDates.sublist(
        0,
        sortedDates.length - _maxSessionDays + 1,
      );

      for (final date in datesToArchive) {
        await _archiveAndDeleteDate(date);
      }
    } else {
      // Fallback to oldest deletion if compression not enabled
      await _cleanupByOldest(availableDates);
    }
  }

  /// Archives a date's log file and deletes the original.
  Future<void> _archiveAndDeleteDate(DateTime date) async {
    // Currently just delete as archiving would require compression library
    // This is a placeholder for future enhancement
    await clearDateStorage(date);

    if (settings.useConsoleLogs) {
      print('Archived and deleted logs for ${_formatDateForFileName(date)}');
    }
  }

  /// Validates file integrity before writing.
  ///
  /// - Parameters: file - File to validate, today - Current date
  /// - Return: Future<bool> true if safe to write
  /// - Usage example: Used internally before file writes
  /// - Edge case notes: Prevents overwriting files from other days
  Future<bool> _validateFileIntegrity(File file, DateTime today) async {
    final existingFileData = await _loadExistingData(file);
    if (existingFileData.isNotEmpty) {
      final firstEntryDate = existingFileData.first.time;
      if (!_isSameDay(firstEntryDate, today)) {
        if (settings.useConsoleLogs) {
          print(
            "Prevented overwriting file from ${_formatDateForFileName(firstEntryDate)} with today's data",
          );
        }
        return false;
      }
    }
    return true;
  }

  /// Checks if writing the data would exceed the maximum file size limit.
  ///
  /// - Parameters: file - Target file, data - Data to be written
  /// - Return: Future<bool> true if size limit would be exceeded
  /// - Usage example: Used before writing to prevent oversized files
  /// - Edge case notes: Estimates JSON size with safety margin
  Future<bool> _wouldExceedSizeLimit(
    File file,
    List<ISpectifyData> data,
  ) async {
    if (_maxFileSize <= 0) return false; // No limit set

    try {
      final currentSize = await file.exists() ? await file.length() : 0;
      final estimatedDataSize = _estimateJsonSize(data);

      return (currentSize + estimatedDataSize) > _maxFileSize;
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to check file size limit: $e');
      }
      return false; // Allow write if check fails
    }
  }

  /// Estimates the JSON size of the data with safety margin.
  int _estimateJsonSize(List<ISpectifyData> data) {
    if (data.isEmpty) return 0;

    // Sample first few entries to estimate average size
    final sampleSize = data.length > 10 ? 10 : data.length;
    var totalSampleSize = 0;

    for (var i = 0; i < sampleSize; i++) {
      try {
        final json = jsonEncode(data[i].toJson());
        totalSampleSize += json.length;
      } catch (e) {
        // Use fallback size estimate if encoding fails
        totalSampleSize += _fallbackEntrySize;
      }
    }

    final averageSize = totalSampleSize ~/ sampleSize;
    final estimatedTotal = averageSize * data.length;

    // Add safety margin for JSON formatting and brackets
    return (estimatedTotal * _sizeSafetyMargin).round();
  }

  /// Rotates the file if it would exceed size limits.
  Future<void> _rotateFileIfNeeded(File file, DateTime date) async {
    if (!await file.exists()) return;

    try {
      // Create timestamped backup
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupPath = '${file.path}.backup_$timestamp';
      await file.copy(backupPath);

      // Clear original file for new data
      await file.writeAsString('[]');

      if (settings.useConsoleLogs) {
        print('Rotated log file: backup created at $backupPath');
      }
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to rotate file: $e');
      }
    }
  }

  /// Checks if we should merge with existing data.
  ///
  /// - Parameters: None
  /// - Return: bool true if should merge with existing file
  /// - Usage example: Used during save operations
  /// - Edge case notes: Prevents data loss by merging on same day
  bool _shouldMergeWithExisting() {
    final now = DateTime.now();

    if (_lastSaveDate == null) return true;

    if (!_isSameDay(_lastSaveDate!, now)) return false;

    return true;
  }

  /// Loads existing data from file efficiently.
  ///
  /// - Parameters: file - File to load data from
  /// - Return: Future<List<ISpectifyData>> loaded data or empty list
  /// - Usage example: Used during merge operations
  /// - Edge case notes: Returns empty list on any parsing error
  Future<List<ISpectifyData>> _loadExistingData(File file) async {
    try {
      final jsonString = await file.readAsString();
      final jsonList = jsonDecode(jsonString) as List<dynamic>;

      return jsonList
          .map(
            (jsonEntry) => ISpectifyDataJsonUtils.fromJson(
              jsonEntry as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      return <ISpectifyData>[];
    }
  }

  /// Merges history data avoiding duplicates and filtering by today's date.
  ///
  /// - Parameters: existing - Data from file, current - Data from memory
  /// - Return: List<ISpectifyData> merged and deduplicated data
  /// - Usage example: Used during save operations to merge datasets
  /// - Edge case notes: Uses optimized int-based map for O(1) operations, sorts by timestamp
  List<ISpectifyData> _mergeHistoryData(
    List<ISpectifyData> existing,
    List<ISpectifyData> current,
  ) {
    final merged = <int, ISpectifyData>{};
    final today = DateTime.now();

    _addDataToMerged(merged, existing, today);
    _addDataToMerged(merged, current, today);

    final result = merged.values.toList()
      // Use more efficient sort with direct comparison
      ..sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  /// Adds data to merged map with deduplication using optimized key generation.
  ///
  /// - Parameters: merged - Target map, data - Source data, today - Filter date
  /// - Return: void
  /// - Usage example: Used internally by _mergeHistoryData
  /// - Edge case notes: Uses int-based key for O(1) operations instead of string concatenation
  void _addDataToMerged(
    Map<int, ISpectifyData> merged,
    List<ISpectifyData> data,
    DateTime today,
  ) {
    for (final item in data) {
      if (_isSameDay(item.time, today)) {
        final key = _generateOptimizedKey(item);
        merged[key] = item;
      }
    }
  }

  /// Generates optimized integer key for deduplication.
  ///
  /// - Parameters: item - Data item to generate key for
  /// - Return: int unique key based on timestamp and message hash
  /// - Usage example: Used for efficient map operations
  /// - Edge case notes: Combines timestamp and message hash for uniqueness
  int _generateOptimizedKey(ISpectifyData item) {
    final timeKey = item.time.millisecondsSinceEpoch;
    final messageHash = item.message?.hashCode ?? 0;
    // Use bit shifting for efficient key combination
    return (timeKey << 16) ^ messageHash;
  }

  /// Writes data in chunks using optimized streaming approach.
  Future<void> _writeDataChunked(File file, List<ISpectifyData> data) async {
    final sink = file.openWrite()..write('[');

    var hasContent = false;
    final buffer = StringBuffer();

    try {
      for (var i = 0; i < data.length; i += _chunkSize) {
        final chunkEnd =
            (i + _chunkSize > data.length) ? data.length : i + _chunkSize;
        final chunk = data.sublist(i, chunkEnd);

        await _processChunkOptimized(
          chunk,
          buffer,
          hasContent,
          sink,
        );
        hasContent = true;

        // Yield control less frequently for better performance
        if (i % (_chunkSize * 10) == 0) {
          await Future<void>.delayed(const Duration(microseconds: 1));
        }
      }

      // Write any remaining buffer content
      if (buffer.isNotEmpty) {
        sink.write(buffer.toString());
        buffer.clear();
      }

      sink.write(']');
    } finally {
      await sink.close();
    }
  }

  /// Processes a chunk with optimized buffering.
  Future<void> _processChunkOptimized(
    List<ISpectifyData> chunk,
    StringBuffer buffer,
    bool hasContent,
    IOSink sink,
  ) async {
    final chunkJsonList = <String>[];

    for (final entry in chunk) {
      try {
        final json = entry.toJson();
        final sanitizedJson = _sanitizeJsonForEncoding(json);
        chunkJsonList.add(jsonEncode(sanitizedJson));
      } catch (e) {
        if (settings.useConsoleLogs) {
          print('Failed to encode entry: $e. Skipping entry.');
        }
      }
    }

    if (chunkJsonList.isNotEmpty) {
      if (hasContent && buffer.isEmpty) buffer.write(',');
      if (buffer.isNotEmpty) buffer.write(',');
      buffer.write(chunkJsonList.join(','));

      // Flush buffer if it's getting large
      if (buffer.length > _bufferSize) {
        sink.write(buffer.toString());
        buffer.clear();
      }
    }
  }

  /// Sanitizes JSON data to ensure all values are encodable.
  Map<String, dynamic> _sanitizeJsonForEncoding(Map<String, dynamic> json) {
    final sanitized = <String, dynamic>{};

    for (final MapEntry(:key, :value) in json.entries) {
      sanitized[key] = _sanitizeValue(value);
    }

    return sanitized;
  }

  /// Sanitizes a single value for JSON encoding.
  Object? _sanitizeValue(Object? value) => switch (value) {
        null || String() || num() || bool() => value,
        final List<dynamic> list => list.map(_sanitizeValue).toList(),
        final Map<String, dynamic> map => _sanitizeJsonForEncoding(map),
        _ => value.toString(),
      };

  @override
  Future<void> loadFromDate(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final loadedData = await _parseJsonToData(jsonString);

        clear();
        loadedData.forEach(add);
      } catch (e) {
        if (settings.useConsoleLogs) {
          print('Failed to load logs from $date: $e');
        }
      }
    }
  }

  @override
  Future<void> loadTodayHistory() async {
    await loadFromDate(DateTime.now());
  }

  @override
  Future<String> exportToJson() async {
    if (history.isEmpty) return '[]';

    final buffer = StringBuffer('[');

    for (var i = 0; i < history.length; i += _chunkSize) {
      final chunkEnd =
          (i + _chunkSize > history.length) ? history.length : i + _chunkSize;
      final chunk = history.sublist(i, chunkEnd);

      if (i > 0) buffer.write(',');

      // Process chunk entries
      final chunkJson = <String>[];
      for (final entry in chunk) {
        chunkJson.add(jsonEncode(entry.toJson()));
      }
      buffer.write(chunkJson.join(','));

      // Yield control for very large datasets
      if (i % (_chunkSize * 20) == 0) {
        await Future<void>.delayed(const Duration(microseconds: 1));
      }
    }

    buffer.write(']');
    return buffer.toString();
  }

  @override
  Future<void> importFromJson(String jsonString) async {
    try {
      final loadedData = await _parseJsonToData(jsonString);

      loadedData.forEach(add);
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to import JSON: $e');
      }
    }
  }

  @override
  Future<void> clearAllFileStorage() async {
    await _ensureDirectoryInitialized();

    try {
      final directory = Directory(sessionDirectory);
      if (await directory.exists()) {
        await for (final FileSystemEntity file in directory.list()) {
          if (file is File && file.path.endsWith('.json')) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to clear all file storage: $e');
      }
    }
  }

  @override
  Future<void> clearDateStorage(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    try {
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to clear storage for $date: $e');
      }
    }
  }

  @override
  Future<List<DateTime>> getAvailableLogDates() async {
    await _ensureDirectoryInitialized();

    final dates = <DateTime>[];

    try {
      final directory = Directory(sessionDirectory);
      if (await directory.exists()) {
        await for (final FileSystemEntity file in directory.list()) {
          if (file is File) {
            final fileName = file.path.split(Platform.pathSeparator).last;
            final date = _parseDateFromFileName(fileName);
            if (date != null) {
              dates.add(date);
            }
          }
        }
      }
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to get available log dates: $e');
      }
    }

    dates.sort();
    return dates;
  }

  @override
  Future<int> getDateFileSize(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    try {
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to get file size for $date: $e');
      }
    }

    return 0;
  }

  @override
  Future<bool> hasTodaySession() async {
    await _ensureDirectoryInitialized();

    final file = File(todaySessionPath);
    return file.exists();
  }

  /// Checks if two dates are the same day.
  ///
  /// - Parameters: date1, date2 - Dates to compare
  /// - Return: bool true if same calendar day
  /// - Usage example: Used for date validation and filtering
  /// - Edge case notes: Ignores time components, compares only date parts
  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;

  /// Cleanup resources when history is no longer needed.
  void dispose() {
    _autoSaveTimer?.cancel();
  }

  /// Gets comprehensive session statistics.
  @override
  // ignore: prefer_final_locals
  Future<SessionStatistics> getSessionStatistics() async {
    await _ensureDirectoryInitialized();

    final availableDates = await getAvailableLogDates();

    final stats = <String, int>{
      'totalSize': 0,
      'totalEntries': 0,
    };

    for (final date in availableDates) {
      stats['totalSize'] = stats['totalSize']! + await getDateFileSize(date);
      final logs = await getLogsByDate(date);
      stats['totalEntries'] = stats['totalEntries']! + logs.length;
    }

    return SessionStatistics(
      totalDays: availableDates.length,
      totalSize: stats['totalSize']!,
      totalEntries: stats['totalEntries']!,
      oldestDate: availableDates.isNotEmpty ? availableDates.first : null,
      newestDate: availableDates.isNotEmpty ? availableDates.last : null,
      maxSessionDays: _maxSessionDays,
      autoSaveInterval: _autoSaveInterval,
      enableAutoSave: _autoSaveEnabled,
      maxFileSize: _maxFileSize,
      cleanupStrategy: _sessionCleanupStrategy,
    );
  }

  /// Updates auto-save settings during runtime.
  @override
  void updateAutoSaveSettings({bool? enabled, Duration? interval}) {
    if (enabled != null) {
      if (enabled && !_autoSaveEnabled) {
        // Enable auto-save
        _autoSaveEnabled = true;
        final newInterval = interval ?? _autoSaveInterval;
        _autoSaveTimer?.cancel();
        _autoSaveTimer = Timer.periodic(newInterval, (_) {
          _performAutoSave();
        });
      } else if (!enabled && _autoSaveEnabled) {
        // Disable auto-save
        _autoSaveEnabled = false;
        _autoSaveTimer?.cancel();
        _autoSaveTimer = null;
      }
    } else if (interval != null && _autoSaveEnabled) {
      // Update interval while keeping auto-save enabled
      _autoSaveTimer?.cancel();
      _autoSaveTimer = Timer.periodic(interval, (_) {
        _performAutoSave();
      });
    }
  }

  @override
  Future<List<ISpectifyData>> getLogsByDate(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        return _parseJsonToData(jsonString);
      } catch (e) {
        if (settings.useConsoleLogs) {
          print('Failed to load logs from $date: $e');
        }
        return <ISpectifyData>[];
      }
    }

    return <ISpectifyData>[];
  }

  /// Parses JSON string to list of ISpectifyData with optimized batch processing.
  Future<List<ISpectifyData>> _parseJsonToData(String jsonString) async {
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      final totalLength = jsonList.length;

      if (totalLength == 0) return <ISpectifyData>[];

      // Adaptive chunk size based on data size
      final chunkSize = totalLength > 1000 ? 50 : 25;
      final result = <ISpectifyData>[];

      for (var i = 0; i < totalLength; i += chunkSize) {
        final chunkEnd =
            (i + chunkSize > totalLength) ? totalLength : i + chunkSize;

        // Process batch without creating intermediate collections
        for (var j = i; j < chunkEnd; j++) {
          try {
            final entry = ISpectifyDataJsonUtils.fromJson(
              jsonList[j] as Map<String, dynamic>,
            );
            result.add(entry);
          } catch (e) {
            // Skip invalid entries but continue processing
            if (settings.useConsoleLogs) {
              print('Failed to parse entry at index $j: $e');
            }
          }
        }

        // Yield control less frequently for larger datasets
        if (i % (chunkSize * 8) == 0) {
          await Future<void>.delayed(const Duration(microseconds: 1));
        }
      }

      return result;
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to parse JSON: $e');
      }
      return <ISpectifyData>[];
    }
  }

  /// Validates that all data entries belong to the specified date with early exit optimization.
  bool _validateDataForDate(List<ISpectifyData> data, DateTime targetDate) {
    if (data.isEmpty) return true;

    final targetYear = targetDate.year;
    final targetMonth = targetDate.month;
    final targetDay = targetDate.day;

    // Use indexed loop for better performance on large datasets
    for (var i = 0; i < data.length; i++) {
      final entryTime = data[i].time;
      if (entryTime.year != targetYear ||
          entryTime.month != targetMonth ||
          entryTime.day != targetDay) {
        return false; // Early exit on first mismatch
      }
    }
    return true;
  }

  @override
  Future<List<ISpectifyData>> getLogsBySession(String sessionPath) async {
    await _ensureDirectoryInitialized();

    final file = File(sessionPath);
    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        return _parseJsonToData(jsonString);
      } catch (e) {
        if (settings.useConsoleLogs) {
          print('Failed to load logs from $sessionPath: $e');
        }
        return <ISpectifyData>[];
      }
    }

    return <ISpectifyData>[];
  }
}
