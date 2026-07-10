import 'dart:collection';

import 'package:ispectify/ispectify.dart';

final class BoundedLogBuffer {
  BoundedLogBuffer(this.options);

  final ISpectLoggerOptions options;

  final ListQueue<ISpectLogData> _entries = ListQueue<ISpectLogData>();
  final Set<String> _ids = <String>{};
  List<ISpectLogData>? _cachedHistory;

  List<ISpectLogData> get history =>
      _cachedHistory ??= List<ISpectLogData>.unmodifiable(_entries);

  bool add(ISpectLogData data) {
    final maxItems = options.maxHistoryItems;
    if (!options.useHistory || maxItems == 0 || _ids.contains(data.id)) {
      return false;
    }

    if (_entries.length == maxItems) {
      final removed = _entries.removeFirst();
      _ids.remove(removed.id);
    }

    _entries.addLast(data);
    _ids.add(data.id);
    _cachedHistory = null;
    return true;
  }

  void replaceAll(Iterable<ISpectLogData> entries) {
    clear();
    entries.forEach(add);
  }

  void clear() {
    _entries.clear();
    _ids.clear();
    _cachedHistory = null;
  }
}
