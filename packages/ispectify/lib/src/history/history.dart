import 'package:ispectify/ispectify.dart';
import 'package:meta/meta.dart';
export 'file_log/file_log_history.dart';

/// An abstract class representing a log history storage.
///
/// This defines a common interface for managing logged data.
abstract interface class ILogHistory {
  /// A list of stored log entries.
  List<ISpectifyData> get history;

  /// Clears the log history.
  void clear();

  /// Adds a new log entry to the history.
  void add(ISpectifyData data);
}

/// The default implementation of `ILogHistory` for managing log history.
///
/// This class stores log entries in-memory and follows the configuration
/// defined in `ISpectifyOptions`.
class DefaultISpectifyHistory implements ILogHistory {
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
    _history.clear();
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

  /// Adds data to history bypassing the useHistory check.
  /// This method is intended for testing purposes only.
  @visibleForTesting
  void addForTesting(ISpectifyData data) {
    if (_history.length >= settings.maxHistoryItems) {
      _history.removeAt(0); // Remove oldest entry
    }
    _history.add(data);
  }
}
