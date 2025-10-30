import 'dart:collection';

import 'package:ispectify/ispectify.dart';
import 'package:meta/meta.dart';
export 'file_log/file_log_history.dart';

/// An abstract class representing a log history storage.
///
/// This defines a common interface for managing logged data.
abstract interface class ILogHistory {
  /// A list of stored log entries.
  List<ISpectLogData> get history;

  /// Clears the log history.
  void clear();

  /// Adds a new log entry to the history.
  void add(ISpectLogData data);
}

/// The default implementation of `ILogHistory` for managing log history.
///
/// This class stores log entries in-memory and follows the configuration
/// defined in `ISpectLoggerOptions`.
class DefaultISpectLoggerHistory implements ILogHistory {
  /// Creates a log history manager with the given `settings`.
  ///
  /// Optionally, an initial `history` list can be provided.
  DefaultISpectLoggerHistory(
    this.settings, {
    List<ISpectLogData>? history,
  }) {
    if (history != null) {
      _history.addAll(history);
    }
  }

  /// Configuration options for logging behavior.
  final ISpectLoggerOptions settings;

  /// Internal list to store log history.
  final ListQueue<ISpectLogData> _history = ListQueue<ISpectLogData>();

  @override
  List<ISpectLogData> get history => List<ISpectLogData>.unmodifiable(_history);

  @override
  void clear() {
    _history.clear();
  }

  @override
  void add(ISpectLogData data) {
    if (!settings.useHistory || !settings.enabled) return;

    // If maxHistoryItems is 0 or negative, disable history
    if (settings.maxHistoryItems <= 0) return;

    // Enforce max history size
    _trimIfNeeded();
    _history.addLast(data);
  }

  /// Adds data to history bypassing the useHistory check.
  /// This method is intended for testing purposes only.
  @visibleForTesting
  void addForTesting(ISpectLogData data) {
    // If maxHistoryItems is 0 or negative, disable history
    if (settings.maxHistoryItems <= 0) return;

    _trimIfNeeded();
    _history.addLast(data);
  }

  void _trimIfNeeded() {
    final maxItems = settings.maxHistoryItems;
    if (maxItems <= 0) {
      _history.clear();
      return;
    }
    while (_history.length >= maxItems) {
      _history.removeFirst();
    }
  }
}
