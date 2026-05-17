import 'dart:collection';

import 'package:ispectify/ispectify.dart';
import 'package:meta/meta.dart';

/// Contract for log history storage.
///
/// Implementations may persist entries in-memory, on disk, or remotely.
abstract interface class ILogHistory {
  List<ISpectLogData> get history;

  void clear();

  void add(ISpectLogData data);

  /// Releases resources (e.g. auto-save timers in [FileLogHistory]).
  void dispose();
}

/// In-memory [ILogHistory] backed by a [ListQueue].
///
/// Respects [ISpectLoggerOptions.useHistory], [ISpectLoggerOptions.enabled],
/// and [ISpectLoggerOptions.maxHistoryItems]. Exposes an unmodifiable view
/// via [history] that is lazily cached and invalidated on mutation.
class DefaultISpectLoggerHistory implements ILogHistory {
  DefaultISpectLoggerHistory(
    this.settings, {
    List<ISpectLogData>? history,
  }) {
    if (history != null) {
      _history.addAll(history);
    }
  }

  final ISpectLoggerOptions settings;

  final ListQueue<ISpectLogData> _history = ListQueue<ISpectLogData>();

  /// Cached unmodifiable view, invalidated on mutation.
  List<ISpectLogData>? _cachedHistory;

  @override
  List<ISpectLogData> get history =>
      _cachedHistory ??= List<ISpectLogData>.unmodifiable(_history);

  @override
  void clear() {
    _history.clear();
    _cachedHistory = null;
  }

  @override
  void dispose() {
    // No-op for in-memory history.
  }

  @override
  void add(ISpectLogData data) {
    if (!settings.useHistory || !settings.enabled) return;
    _addEntry(data);
  }

  /// Adds data bypassing the [ISpectLoggerOptions.useHistory] guard.
  @visibleForTesting
  void addForTesting(ISpectLogData data) => _addEntry(data);

  void _addEntry(ISpectLogData data) {
    final maxItems = settings.maxHistoryItems;
    if (maxItems <= 0) return;

    if (_history.length >= maxItems) {
      _history.removeFirst();
      _cachedHistory = null;
    }

    _history.addLast(data);
    _cachedHistory = null;
  }
}
