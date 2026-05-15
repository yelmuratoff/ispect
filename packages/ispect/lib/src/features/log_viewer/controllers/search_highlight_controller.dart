import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ispect/src/common/managers/filter_manager.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispectify/ispectify.dart';

/// Manages search highlighting state and navigation (desktop).
class SearchHighlightController extends ChangeNotifier {
  SearchHighlightController({required this.filterManager});

  final FilterManager filterManager;

  final searchController = TextEditingController();

  SearchMode _searchMode = SearchMode.highlight;
  List<String> _searchMatchIds = const [];
  Set<String> _searchMatchIdSet = const {};
  int _focusedMatchIndex = -1;
  List<ISpectLogData>? _lastUpdateMatchesInput;

  SearchMode get searchMode => _searchMode;

  /// Ordered list of matched log IDs.
  List<String> get searchMatchIds => _searchMatchIds;

  /// Set of matched log IDs for O(1) lookup.
  Set<String> get searchMatchIdSet => _searchMatchIdSet;

  int get focusedMatchIndex => _focusedMatchIndex;

  /// 1-based position of the focused match for display (e.g. "3/12").
  int get focusedMatchPosition =>
      _focusedMatchIndex >= 0 ? _focusedMatchIndex + 1 : 0;

  int get searchMatchCount => _searchMatchIds.length;

  bool get hasSearchMatches => _searchMatchIds.isNotEmpty;

  /// The ID of the currently focused search match, or `null` when no match
  /// is focused (no results, or controller in non-highlight mode).
  String? get focusedMatchId {
    if (_focusedMatchIndex < 0 ||
        _focusedMatchIndex >= _searchMatchIds.length) {
      return null;
    }
    return _searchMatchIds[_focusedMatchIndex];
  }

  set searchMode(SearchMode mode) {
    if (_searchMode == mode) return;
    _searchMode = mode;
    _searchMatchIds = const [];
    _searchMatchIdSet = const {};
    _focusedMatchIndex = -1;
    _lastUpdateMatchesInput = null;
    if (mode == SearchMode.highlight) {
      filterManager.clearLogTypeKeyFilters();
    }

    filterManager.updateFilterSearchQuery(
      searchController.text,
      immediate: true,
    );
    notifyListeners();
  }

  /// Synchronizes the search match state with the given log entries.
  void updateSearchMatches(List<ISpectLogData> matches) {
    if (identical(matches, _lastUpdateMatchesInput)) return;
    _lastUpdateMatchesInput = matches;

    final newIds = matches.map((e) => e.id).toList(growable: false);
    if (listEquals(_searchMatchIds, newIds)) return;

    final oldFocused = _focusedMatchIndex;
    _searchMatchIds = newIds;
    _searchMatchIdSet = newIds.toSet();
    if (newIds.isEmpty) {
      _focusedMatchIndex = -1;
    } else if (_focusedMatchIndex < 0 || _focusedMatchIndex >= newIds.length) {
      _focusedMatchIndex = 0;
    }

    if (_focusedMatchIndex != oldFocused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Returns the [SearchMatchState] for a given log entry.
  SearchMatchState matchStateFor(ISpectLogData logEntry) {
    if (_searchMode != SearchMode.highlight) return SearchMatchState.none;
    final logId = logEntry.id;
    if (logId == focusedMatchId) return SearchMatchState.focused;
    if (_searchMatchIdSet.contains(logId)) return SearchMatchState.match;
    return SearchMatchState.none;
  }

  /// Returns the [SearchMatchState] for a network transaction.
  ///
  /// A transaction matches if any of its constituent logs (request, response,
  /// error) is in the current search match set.
  SearchMatchState matchStateForTransaction(NetworkTransaction tx) {
    if (_searchMode != SearchMode.highlight) return SearchMatchState.none;
    final ids = [
      tx.request.id,
      if (tx.response != null) tx.response!.id,
      if (tx.error != null) tx.error!.id,
    ];
    if (ids.contains(focusedMatchId)) return SearchMatchState.focused;
    if (ids.any(_searchMatchIdSet.contains)) return SearchMatchState.match;
    return SearchMatchState.none;
  }

  void focusNextMatch() {
    if (_searchMatchIds.isEmpty) return;
    _focusedMatchIndex = (_focusedMatchIndex + 1) % _searchMatchIds.length;
    notifyListeners();
  }

  void focusPreviousMatch() {
    if (_searchMatchIds.isEmpty) return;
    _focusedMatchIndex = (_focusedMatchIndex - 1 + _searchMatchIds.length) %
        _searchMatchIds.length;
    notifyListeners();
  }

  /// Finds log entries matching the current search query.
  List<ISpectLogData> findSearchMatches(List<ISpectLogData> logsData) =>
      filterManager.findSearchMatches(logsData);

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
