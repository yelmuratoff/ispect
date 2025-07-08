// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';

/// Extended interface for log history with daily file system support.
///
/// This interface adds functionality for persistent storage organized by date,
/// import/export capabilities, and optimized session management.
abstract class FileLogHistory extends LogHistory {
  /// Saves the current history to daily organized files.
  Future<void> saveToDailyFile();

  /// Loads history from a specific date.
  Future<void> loadFromDate(DateTime date);

  /// Loads history from today's file if exists.
  Future<void> loadTodayHistory();

  /// Exports history to JSON format.
  Future<String> exportToJson();

  /// Imports history from JSON format.
  Future<void> importFromJson(String jsonString);

  /// Clears all file-based storage.
  Future<void> clearAllFileStorage();

  /// Clears specific date's storage.
  Future<void> clearDateStorage(DateTime date);

  /// Gets the current session directory path.
  String get sessionDirectory;

  /// Gets today's session file path.
  String get todaySessionPath;

  /// Gets available log dates.
  Future<List<DateTime>> getAvailableLogDates();

  /// Gets file size for a specific date.
  Future<int> getDateFileSize(DateTime date);

  /// Checks if today's session file exists.
  Future<bool> hasTodaySession();

  /// Gets all logs for a specific date without modifying current history.
  Future<List<ISpectifyData>> getLogsByDate(DateTime date);

  Future<List<ISpectifyData>> getLogsBySession(String sessionPath);
}

/// Optimized daily file-based log history implementation.
///
/// This class provides efficient daily log management with automatic
/// secure cache directory setup and memory-conscious operations.
class DailyFileLogHistory extends DefaultISpectifyHistory
    implements FileLogHistory {
  /// Creates a daily file-based log history manager.
  ///
  /// - Parameters: settings for log behavior
  /// - Return: DailyFileLogHistory instance
  /// - Usage example: DailyFileLogHistory(ISpectifyOptions())
  /// - Edge case notes: Automatically creates secure cache directory
  DailyFileLogHistory(
    super.settings, {
    super.history,
    Duration? autoSaveInterval,
  }) {
    _initializeSecureDirectory();
    _setupAutoSave(autoSaveInterval ?? const Duration(seconds: 1));
  }

  String? _sessionDirectory;
  Timer? _autoSaveTimer;
  DateTime? _lastSaveDate;
  final Set<String> _pendingWrites = {};
  final StreamController<String> _writeQueue =
      StreamController<String>.broadcast();
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
  Future<void> _initializeSecureDirectory() async {
    try {
      final cacheDir = await _getSecureCacheDirectory();
      final logsDir = Directory('$cacheDir/ispectify_logs');

      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }

      _sessionDirectory = logsDir.path;
      _directoryInitialized.complete();

      // Don't auto-load history on initialization to prevent data mixing
      // Users should explicitly call loadTodayHistory() if needed
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to initialize secure directory: $e');
      }
      _directoryInitialized.completeError(e);
    }
  }

  /// Gets platform-specific secure cache directory.
  Future<String> _getSecureCacheDirectory() async {
    if (Platform.isAndroid || Platform.isIOS) {
      // For mobile platforms, use app cache directory
      return _getMobileCacheDirectory();
    } else if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // For desktop platforms, use system cache directory
      return _getDesktopCacheDirectory();
    } else {
      // Fallback to current directory with hidden folder
      return Directory.current.path;
    }
  }

  /// Gets mobile cache directory path.
  Future<String> _getMobileCacheDirectory() async {
    // For mobile, we'll use a subdirectory in temp
    final tempDir = Directory.systemTemp;
    final appCacheDir = Directory('${tempDir.path}/ispectify_cache');

    if (!await appCacheDir.exists()) {
      await appCacheDir.create(recursive: true);
    }

    return appCacheDir.path;
  }

  /// Gets desktop cache directory path.
  Future<String> _getDesktopCacheDirectory() async {
    final homeDir = Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.current.path;

    String cacheDir;
    if (Platform.isMacOS) {
      cacheDir = '$homeDir/Library/Caches/ispectify';
    } else if (Platform.isWindows) {
      final localAppData =
          Platform.environment['LOCALAPPDATA'] ?? '$homeDir/AppData/Local';
      cacheDir = '$localAppData/ispectify/cache';
    } else {
      // Linux
      final xdgCache =
          Platform.environment['XDG_CACHE_HOME'] ?? '$homeDir/.cache';
      cacheDir = '$xdgCache/ispectify';
    }

    final dir = Directory(cacheDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    return dir.path;
  }

  /// Ensures directory is initialized before operations.
  Future<void> _ensureDirectoryInitialized() async {
    if (!_directoryInitialized.isCompleted) {
      await _directoryInitialized.future;
    }
  }

  /// Sets up automatic saving with the specified interval.
  void _setupAutoSave(Duration interval) {
    _autoSaveTimer = Timer.periodic(interval, (_) {
      _performAutoSave();
    });
  }

  /// Gets file path for specific date with optimized formatting.
  String _getDateFilePath(DateTime date, {String fileType = 'json'}) {
    if (_sessionDirectory == null) {
      throw StateError('Session directory not initialized yet.');
    }
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$_sessionDirectory/logs_$dateStr.$fileType';
  }

  /// Optimized date parsing from file name.
  DateTime? _parseDateFromFileName(String fileName) {
    final regex = RegExp(r'logs_(\d{4})-(\d{2})-(\d{2})\.json');
    final match = regex.firstMatch(fileName);
    if (match != null) {
      final year = int.parse(match.group(1)!);
      final month = int.parse(match.group(2)!);
      final day = int.parse(match.group(3)!);
      return DateTime(year, month, day);
    }
    return null;
  }

  /// Performs optimized auto-save with write queue management.
  Future<void> _performAutoSave() async {
    if (_sessionDirectory == null || history.isEmpty) return;

    if (_pendingWrites.contains(todaySessionPath)) {
      return;
    }

    try {
      await saveToDailyFile();
    } catch (e) {
      // Silently handle auto-save errors to prevent app crashes
      if (settings.useConsoleLogs) {
        print('ISpectify auto-save failed: $e');
      }
    }
  }

  @override
  Future<void> saveToDailyFile() async {
    await _ensureDirectoryInitialized();

    // Don't save empty history
    if (history.isEmpty) return;

    final filePath = todaySessionPath;
    if (_pendingWrites.contains(filePath)) {
      return; // Prevent concurrent writes
    }

    _pendingWrites.add(filePath);

    try {
      final file = File(filePath);
      await file.parent.create(recursive: true);

      // Load existing data for today if different session
      var existingData = <ISpectifyData>[];
      if (await file.exists() && _shouldMergeWithExisting()) {
        existingData = await _loadExistingData(file);
      }

      // Merge with current history (avoid duplicates)
      final mergedData = _mergeHistoryData(existingData, history);

      // Don't save if no new data
      if (mergedData.isEmpty) return;

      // Validate that all data belongs to today
      final today = DateTime.now();
      if (!_validateDataForDate(mergedData, today)) {
        if (settings.useConsoleLogs) {
          print('Prevented saving mixed-date data to daily file');
        }
        return;
      }

      // Additional safety: ensure we're not overwriting files from other days
      final existingFileData = await _loadExistingData(file);
      if (existingFileData.isNotEmpty) {
        final firstEntryDate = existingFileData.first.time;
        if (!_isSameDay(firstEntryDate, today)) {
          // File contains data from another day - don't overwrite
          if (settings.useConsoleLogs) {
            print(
              "Prevented overwriting file from ${firstEntryDate.toIso8601String().split('T').first} with today's data",
            );
          }
          return;
        }
      }

      // Use chunked writing for large datasets
      await _writeDataChunked(file, mergedData);
      _lastSaveDate = DateTime.now();
    } finally {
      _pendingWrites.remove(filePath);
    }
  }

  /// Checks if we should merge with existing data.
  bool _shouldMergeWithExisting() {
    final now = DateTime.now();

    // If no previous save date, merge with existing (first save in a session)
    if (_lastSaveDate == null) return true;

    // If different day, DON'T merge - we're creating a new day file
    if (!_isSameDay(_lastSaveDate!, now)) return false;

    // Always merge if saving on the same day to prevent data loss
    return true;
  }

  /// Loads existing data from file efficiently.
  Future<List<ISpectifyData>> _loadExistingData(File file) async {
    try {
      final jsonString = await file.readAsString();
      final dynamic jsonData = jsonDecode(jsonString);
      final jsonList = jsonData as List<dynamic>;

      return jsonList
          .map(
            (jsonEntry) => ISpectifyDataJsonUtils.fromJson(
              jsonEntry as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Merges history data avoiding duplicates and filtering by today's date.
  List<ISpectifyData> _mergeHistoryData(
    List<ISpectifyData> existing,
    List<ISpectifyData> current,
  ) {
    final merged = <String, ISpectifyData>{};
    final today = DateTime.now();

    // Add existing data (only from today)
    for (final item in existing) {
      if (_isSameDay(item.time, today)) {
        final key =
            '${item.time.millisecondsSinceEpoch}_${item.message?.hashCode ?? 0}';
        merged[key] = item;
      }
    }

    // Add current data (only from today, newer entries override)
    for (final item in current) {
      if (_isSameDay(item.time, today)) {
        final key =
            '${item.time.millisecondsSinceEpoch}_${item.message?.hashCode ?? 0}';
        merged[key] = item;
      }
    }

    // Sort by time
    final result = merged.values.toList()
      ..sort((a, b) => a.time.compareTo(b.time));
    return result;
  }

  /// Writes data in chunks to prevent memory issues.
  Future<void> _writeDataChunked(File file, List<ISpectifyData> data) async {
    const chunkSize = 100;
    final buffer = StringBuffer()..write('[');

    for (var i = 0; i < data.length; i += chunkSize) {
      final chunk = data.skip(i).take(chunkSize);
      final chunkJson =
          chunk.map((entry) => jsonEncode(entry.toJson())).join(',');

      if (i > 0) buffer.write(',');
      buffer.write(chunkJson);

      // Yield control periodically
      if (i % (chunkSize * 5) == 0) {
        await Future<void>.delayed(const Duration(microseconds: 1));
      }
    }

    buffer.write(']');
    await file.writeAsString(buffer.toString());
  }

  @override
  Future<void> loadFromDate(DateTime date) async {
    await _ensureDirectoryInitialized();

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        final loadedData = await _parseJsonToData(jsonString);

        // Replace current history with loaded data (don't merge)
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
    final jsonList = <Map<String, dynamic>>[];

    // Process in chunks to prevent memory spikes
    const chunkSize = 50;
    for (var i = 0; i < history.length; i += chunkSize) {
      final chunk = history.skip(i).take(chunkSize);
      for (final entry in chunk) {
        jsonList.add(entry.toJson());
      }

      // Yield control
      if (i % (chunkSize * 10) == 0) {
        await Future<void>.delayed(const Duration(microseconds: 1));
      }
    }

    return jsonEncode(jsonList);
  }

  @override
  Future<void> importFromJson(String jsonString) async {
    // Note: This method is for importing external JSON data, not for loading daily files
    // Use loadFromDate() for loading specific date files
    try {
      final loadedData = await _parseJsonToData(jsonString);

      // Add imported data to current history (this is the expected behavior for import)
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
        await for (final file in directory.list()) {
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
        await for (final file in directory.list()) {
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
  bool _isSameDay(DateTime date1, DateTime date2) =>
      date1.year == date2.year &&
      date1.month == date2.month &&
      date1.day == date2.day;

  /// Cleanup resources when history is no longer needed.
  void dispose() {
    _autoSaveTimer?.cancel();
    _writeQueue.close();
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
        return [];
      }
    }

    return [];
  }

  /// Parses JSON string to list of ISpectifyData without modifying current history.
  Future<List<ISpectifyData>> _parseJsonToData(String jsonString) async {
    final result = <ISpectifyData>[];

    try {
      final dynamic jsonData = jsonDecode(jsonString);
      final jsonList = jsonData as List<dynamic>;

      // Process in chunks to prevent UI freezing
      const chunkSize = 25;
      for (var i = 0; i < jsonList.length; i += chunkSize) {
        final chunk = jsonList.skip(i).take(chunkSize);

        for (final jsonEntry in chunk) {
          final entry = ISpectifyDataJsonUtils.fromJson(
            jsonEntry as Map<String, dynamic>,
          );
          result.add(entry);
        }

        // Yield control for UI responsiveness
        if (i % (chunkSize * 4) == 0) {
          await Future<void>.delayed(const Duration(microseconds: 1));
        }
      }
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to parse JSON: $e');
      }
    }

    return result;
  }

  /// Validates that all data entries belong to the specified date.
  bool _validateDataForDate(List<ISpectifyData> data, DateTime targetDate) {
    if (data.isEmpty) return true;

    for (final entry in data) {
      if (!_isSameDay(entry.time, targetDate)) {
        return false;
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
        return [];
      }
    }

    return [];
  }
}
