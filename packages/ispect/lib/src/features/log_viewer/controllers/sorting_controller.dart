import 'package:flutter/foundation.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispectify/ispectify.dart';

/// Manages desktop column sorting state.
class SortingController extends ChangeNotifier {
  SortingController({required ValueGetter<bool> isLogOrderReversed})
      : _isLogOrderReversed = isLogOrderReversed;

  final ValueGetter<bool> _isLogOrderReversed;

  LogSortColumn _sortColumn = LogSortColumn.time;
  LogSortDirection _sortDirection = LogSortDirection.descending;

  LogSortColumn get sortColumn => _sortColumn;
  LogSortDirection get sortDirection => _sortDirection;

  bool get isLogOrderReversed => _isLogOrderReversed();

  void toggleSort(LogSortColumn column) {
    if (_sortColumn == column) {
      _sortDirection = _sortDirection == LogSortDirection.ascending
          ? LogSortDirection.descending
          : LogSortDirection.ascending;
    } else {
      _sortColumn = column;
      _sortDirection = LogSortDirection.ascending;
    }
    notifyListeners();
  }

  /// Sort a filtered list by the current sort column/direction.
  List<ISpectLogData> applySorting(List<ISpectLogData> entries) {
    if (_sortColumn == LogSortColumn.time) {
      return entries;
    }
    final sorted = List<ISpectLogData>.of(entries);
    switch (_sortColumn) {
      case LogSortColumn.type:
        sorted.sort((a, b) => (a.key ?? '').compareTo(b.key ?? ''));
      case LogSortColumn.message:
        sorted.sort((a, b) {
          final aMsg = a.isHttpLog ? (a.httpLogText ?? '') : (a.textMessage);
          final bMsg = b.isHttpLog ? (b.httpLogText ?? '') : (b.textMessage);
          return aMsg.compareTo(bMsg);
        });
      case LogSortColumn.time:
        break; // handled above
    }
    if (_sortDirection == LogSortDirection.descending) {
      return sorted.reversed.toList();
    }
    return sorted;
  }

  ({ISpectLogData entry, int actualIndex})? getLogEntryAtIndex(
    List<ISpectLogData> filteredEntries,
    int index,
  ) {
    final actualIndex =
        isLogOrderReversed ? filteredEntries.length - 1 - index : index;
    if (actualIndex < 0 || actualIndex >= filteredEntries.length) {
      return null;
    }
    return (
      entry: filteredEntries[actualIndex],
      actualIndex: actualIndex,
    );
  }
}
