import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ispectify/ispectify.dart';

/// An abstract class representing a log history storage.
///
/// This defines a common interface for managing logged data.
abstract class LogHistory {
  /// A list of stored log entries.
  List<ISpectifyData> get history;

  /// Clears the log history.
  void clear();

  /// Adds a new log entry to the history.
  void add(ISpectifyData data);
}

/// Extended interface for log history with file system support.
///
/// This interface adds functionality for persistent storage,
/// import/export capabilities, and session management.
abstract class FileLogHistory extends LogHistory {
  /// Saves the current history to a file.
  Future<void> saveToFile(String filePath);

  /// Loads history from a file.
  Future<void> loadFromFile(String filePath);

  /// Exports history to JSON format.
  Future<String> exportToJson();

  /// Imports history from JSON format.
  Future<void> importFromJson(String jsonString);

  /// Clears file-based storage.
  Future<void> clearFileStorage();

  /// Gets the current session file path.
  String? get currentSessionPath;

  /// Sets up automatic session saving.
  void enableAutoSave(String sessionDirectory, {Duration? interval});

  /// Disables automatic session saving.
}

/// The default implementation of `LogHistory` for managing log history.
///
/// This class stores log entries in-memory and follows the configuration
/// defined in `ISpectifyOptions`.
class DefaultISpectifyHistory implements LogHistory {
  /// Creates a log history manager with the given `settings`.
  ///
  /// Optionally, an initial `history` list can be provided.
  DefaultISpectifyHistory(
    this.settings, {
    List<ISpectifyData>? history,
  }) {
    if (history != null) {
      _history.addAll(history);
    }
  }

  /// Configuration options for logging behavior.
  final ISpectifyOptions settings;

  /// Internal list to store log history.
  final List<ISpectifyData> _history = [];

  @override
  List<ISpectifyData> get history => List.unmodifiable(_history);

  @override
  void clear() {
    if (settings.useHistory) {
      _history.clear();
    }
  }

  @override
  void add(ISpectifyData data) {
    if (!settings.useHistory || !settings.enabled) return;

    // Enforce max history size
    if (_history.length >= settings.maxHistoryItems) {
      _history.removeAt(0); // Remove oldest entry
    }
    _history.add(data);
  }
}

/// The default implementation of `FileLogHistory` for managing log history
/// with file system support.
///
/// This class extends `DefaultISpectifyHistory` to provide persistent storage
/// and session management features.
class DefaultFileLogHistory extends DefaultISpectifyHistory
    implements FileLogHistory {
  /// Creates a file-based log history manager with the given `settings`.
  ///
  /// Optionally, an initial `history` list can be provided.
  DefaultFileLogHistory(
    super.settings, {
    super.history,
  });

  String? _currentSessionPath;
  Timer? _autoSaveTimer;

  @override
  String? get currentSessionPath => _currentSessionPath;

  @override
  void enableAutoSave(String sessionDirectory, {Duration? interval}) {
    _currentSessionPath = '$sessionDirectory/session_history.json';
    _autoSaveTimer?.cancel();
    if (interval != null) {
      _autoSaveTimer = Timer.periodic(interval, (_) {
        saveToFile(_currentSessionPath!);
      });
    }
  }

  void disableAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  @override
  Future<void> saveToFile(String filePath) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    final jsonString = await exportToJson();
    await file.writeAsString(jsonString);
  }

  @override
  Future<void> loadFromFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      final jsonString = await file.readAsString();
      await importFromJson(jsonString);
    }
  }

  @override
  Future<String> exportToJson() async {
    final jsonList = <Map<String, dynamic>>[];
    for (final entry in history) {
      jsonList.add(entry.toJson());
    }
    return jsonEncode(jsonList);
  }

  @override
  Future<void> importFromJson(String jsonString) async {
    final dynamic jsonData = jsonDecode(jsonString);
    final jsonList = jsonData as List<dynamic>;
    for (final jsonEntry in jsonList) {
      final entry =
          ISpectifyDataJsonUtils.fromJson(jsonEntry as Map<String, dynamic>);
      add(entry);
    }
  }

  @override
  Future<void> clearFileStorage() async {
    if (_currentSessionPath != null) {
      final file = File(_currentSessionPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
