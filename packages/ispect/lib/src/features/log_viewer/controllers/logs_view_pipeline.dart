import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/managers/filter_manager.dart';
import 'package:ispect/src/common/services/network_transaction_service.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/controllers/logs_screen_controller.dart';

/// Everything the logs list needs to render one frame, derived from the raw
/// history snapshot by [LogsViewPipeline.compute].
final class LogsViewState {
  const LogsViewState({
    required this.totalCount,
    required this.filtered,
    required this.sorted,
    required this.grouped,
    required this.isReversed,
    required this.isHighlightMode,
    required this.searchMatches,
    required this.levelStats,
    required this.logTypeKeys,
    required this.idToVisualIndex,
  });

  /// Size of the raw snapshot the state was derived from.
  final int totalCount;

  /// Entries that pass the active filters (search excluded in highlight mode).
  final List<ISpectLogData> filtered;

  /// [filtered] in the order the desktop table sorts by; identical to
  /// [filtered] when the time column is active.
  final List<ISpectLogData> sorted;

  /// [sorted] with HTTP request/response/error triples folded into
  /// [NetworkTransaction] rows, or null when grouping is off.
  final List<Object>? grouped;

  /// Whether the list renders newest-first through index inversion.
  final bool isReversed;

  /// Whether search highlights matches instead of filtering them.
  final bool isHighlightMode;

  /// Matches in visual order, or null outside highlight mode.
  final List<ISpectLogData>? searchMatches;

  final ({int errors, int warnings}) levelStats;
  final LogTypeKeysResult logTypeKeys;

  /// Log id to the index of the row that displays it, for both flat and
  /// grouped layouts.
  final Map<String, int> idToVisualIndex;

  bool get isFiltered => filtered.length != totalCount;
}

/// Turns the raw history snapshot into a [LogsViewState].
///
/// Owns the caches that make repeated builds cheap: the reversed-matches list
/// and the id-to-row index are rebuilt only when their inputs change identity
/// or the filter generation advances.
final class LogsViewPipeline {
  LogsViewPipeline({
    required LogsScreenController screen,
    NetworkTransactionService? transactionService,
  }) : _screen = screen,
       _transactionService = transactionService ?? NetworkTransactionService();

  final LogsScreenController _screen;
  final NetworkTransactionService _transactionService;

  Map<String, int> _idToVisualIndex = const {};
  List<ISpectLogData>? _lastVisualIndexInput;
  int _lastVisualIndexGeneration = -1;
  bool _lastVisualIndexGrouped = false;
  bool _lastVisualIndexReversed = false;

  List<ISpectLogData>? _lastRawMatches;
  List<ISpectLogData> _reversedMatchesCache = const [];

  ISpectViewController get _view => _screen.logsViewController;

  /// Row index currently displaying [id], or null when it is not on screen.
  int? visualIndexOf(String id) => _idToVisualIndex[id];

  LogsViewState compute(List<ISpectLogData> logs) {
    final isHighlightMode = _view.searchMode == SearchMode.highlight;
    final filtered = isHighlightMode
        ? _view.applyFiltersWithoutSearch(logs)
        : _view.applyCurrentFilters(logs);
    final sorted = _screen.applySortingIfNeeded(filtered);
    final isReversed =
        _view.sortColumn == LogSortColumn.time && _view.isLogOrderReversed;
    final shouldGroup = _view.groupHttpLogs && _view.filter.logTypeKeys.isEmpty;
    final grouped = shouldGroup
        ? _transactionService
              .getGroupedEntries(sorted, _view.outputGeneration)
              .entries
        : null;

    _updateVisualIndexes(sorted, grouped: grouped, isReversed: isReversed);

    return LogsViewState(
      totalCount: logs.length,
      filtered: filtered,
      sorted: sorted,
      grouped: grouped,
      isReversed: isReversed,
      isHighlightMode: isHighlightMode,
      searchMatches: isHighlightMode
          ? _searchMatches(sorted, isReversed: isReversed)
          : null,
      levelStats: _view.getLevelStats(logs),
      logTypeKeys: _view.getLogTypeKeys(logs),
      idToVisualIndex: _idToVisualIndex,
    );
  }

  List<ISpectLogData> _searchMatches(
    List<ISpectLogData> sorted, {
    required bool isReversed,
  }) {
    final matches = _view.findSearchMatches(sorted);
    if (!isReversed || matches.isEmpty) return matches;
    if (!identical(matches, _lastRawMatches)) {
      _reversedMatchesCache = matches.reversed.toList();
      _lastRawMatches = matches;
    }
    return _reversedMatchesCache;
  }

  void _updateVisualIndexes(
    List<ISpectLogData> sorted, {
    required List<Object>? grouped,
    required bool isReversed,
  }) {
    final generation = _view.outputGeneration;
    final isGrouped = grouped != null;
    if (identical(sorted, _lastVisualIndexInput) &&
        generation == _lastVisualIndexGeneration &&
        isGrouped == _lastVisualIndexGrouped &&
        isReversed == _lastVisualIndexReversed) {
      return;
    }

    final visualIndexes = <String, int>{};
    if (grouped case final entries?) {
      for (var visualIndex = 0; visualIndex < entries.length; visualIndex++) {
        final dataIndex = isReversed
            ? entries.length - 1 - visualIndex
            : visualIndex;
        final entry = entries[dataIndex];
        if (entry is ISpectLogData) {
          visualIndexes[entry.id] = visualIndex;
        } else if (entry is NetworkTransaction) {
          visualIndexes[entry.request.id] = visualIndex;
          if (entry.response case final response?) {
            visualIndexes[response.id] = visualIndex;
          }
          if (entry.error case final error?) {
            visualIndexes[error.id] = visualIndex;
          }
        }
      }
    } else {
      for (var visualIndex = 0; visualIndex < sorted.length; visualIndex++) {
        final entry = _screen.getEntryAtVisualIndex(sorted, visualIndex);
        visualIndexes[entry.id] = visualIndex;
      }
    }

    _idToVisualIndex = visualIndexes;
    _lastVisualIndexInput = sorted;
    _lastVisualIndexGeneration = generation;
    _lastVisualIndexGrouped = isGrouped;
    _lastVisualIndexReversed = isReversed;
  }
}
