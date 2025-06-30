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
  String? get sessionDirectory;

  /// Gets today's session file path.
  String get todaySessionPath;

  /// Gets available log dates.
  Future<List<DateTime>> getAvailableLogDates();

  /// Sets up automatic daily session saving.
  void enableDailyAutoSave(String sessionDirectory, {Duration? interval});

  /// Disables automatic session saving.
  void disableAutoSave();

  /// Gets file size for a specific date.
  Future<int> getDateFileSize(DateTime date);

  /// Checks if today's session file exists.
  Future<bool> hasTodaySession();
}

/// Optimized daily file-based log history implementation.
///
/// This class provides efficient daily log management with cross-platform support,
/// automatic day-based file organization, and memory-conscious operations.
class DailyFileLogHistory extends DefaultISpectifyHistory
    implements FileLogHistory {
  /// Creates a daily file-based log history manager.
  ///
  /// - Parameters: settings for log behavior
  /// - Return: DailyFileLogHistory instance
  /// - Usage example: DailyFileLogHistory(ISpectifyOptions())
  /// - Edge case notes: Handles platform-specific paths and permissions
  DailyFileLogHistory(
    super.settings, {
    super.history,
  });

  String? _sessionDirectory;
  Timer? _autoSaveTimer;
  DateTime? _lastSaveDate;
  final Set<String> _pendingWrites = {};
  final StreamController<String> _writeQueue =
      StreamController<String>.broadcast();

  @override
  String? get sessionDirectory => _sessionDirectory;

  @override
  String get todaySessionPath {
    if (_sessionDirectory == null) {
      throw StateError(
        'Session directory not set. Call enableDailyAutoSave first.',
      );
    }
    return _getDateFilePath(DateTime.now());
  }

  /// Gets file path for specific date with optimized formatting.
  String _getDateFilePath(DateTime date) {
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '$_sessionDirectory/logs_$dateStr.json';
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

  @override
  void enableDailyAutoSave(String sessionDirectory, {Duration? interval}) {
    _sessionDirectory = sessionDirectory;
    _autoSaveTimer?.cancel();

    final saveInterval = interval ?? const Duration(seconds: 30);
    _autoSaveTimer = Timer.periodic(saveInterval, (_) {
      _performAutoSave();
    });

    // Load today's history if exists
    loadTodayHistory();
  }

  @override
  void disableAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Performs optimized auto-save with write queue management.
  Future<void> _performAutoSave() async {
    if (_sessionDirectory == null ||
        _pendingWrites.contains(todaySessionPath)) {
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
    if (_sessionDirectory == null) return;

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
    return _lastSaveDate == null ||
        !_isSameDay(_lastSaveDate!, now) ||
        _lastSaveDate!.difference(now).inMinutes > 5;
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

  /// Merges history data avoiding duplicates.
  List<ISpectifyData> _mergeHistoryData(
    List<ISpectifyData> existing,
    List<ISpectifyData> current,
  ) {
    final merged = <String, ISpectifyData>{};

    // Add existing data
    for (final item in existing) {
      final key =
          '${item.time.millisecondsSinceEpoch}_${item.message?.hashCode ?? 0}';
      merged[key] = item;
    }

    // Add current data (newer entries override)
    for (final item in current) {
      final key =
          '${item.time.millisecondsSinceEpoch}_${item.message?.hashCode ?? 0}';
      merged[key] = item;
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
    if (_sessionDirectory == null) return;

    final filePath = _getDateFilePath(date);
    final file = File(filePath);

    if (await file.exists()) {
      try {
        final jsonString = await file.readAsString();
        await importFromJson(jsonString);
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
          add(entry);
        }

        // Yield control for UI responsiveness
        if (i % (chunkSize * 4) == 0) {
          await Future<void>.delayed(const Duration(microseconds: 1));
        }
      }
    } catch (e) {
      if (settings.useConsoleLogs) {
        print('Failed to import JSON: $e');
      }
    }
  }

  @override
  Future<void> clearAllFileStorage() async {
    if (_sessionDirectory == null) return;

    try {
      final directory = Directory(_sessionDirectory!);
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
    if (_sessionDirectory == null) return;

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
    if (_sessionDirectory == null) return [];

    final dates = <DateTime>[];

    try {
      final directory = Directory(_sessionDirectory!);
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
    if (_sessionDirectory == null) return 0;

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
    if (_sessionDirectory == null) return false;

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
    disableAutoSave();
    _writeQueue.close();
  }
}
