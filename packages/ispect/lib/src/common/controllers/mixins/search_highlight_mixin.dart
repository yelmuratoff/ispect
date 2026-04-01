import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/managers/filter_manager.dart';
import 'package:ispectify/ispectify.dart';

/// Manages search highlighting state and navigation (desktop).
mixin SearchHighlightMixin on ChangeNotifier {
  FilterManager get filterManager;

  final searchController = TextEditingController();

  SearchMode _searchMode = SearchMode.highlight;
  List<int> _searchMatchIds = const [];
  Set<int> _searchMatchIdSet = const {};
  int _focusedMatchIndex = -1;
  List<ISpectLogData>? _lastUpdateMatchesInput;

  SearchMode get searchMode => _searchMode;

  /// Ordered list of matched log IDs.
  List<int> get searchMatchIds => _searchMatchIds;

  /// Set of matched log IDs for O(1) lookup.
  Set<int> get searchMatchIdSet => _searchMatchIdSet;

  int get focusedMatchIndex => _focusedMatchIndex;

  /// 1-based position of the focused match for display (e.g. "3/12").
  int get focusedMatchPosition =>
      _focusedMatchIndex >= 0 ? _focusedMatchIndex + 1 : 0;

  int get searchMatchCount => _searchMatchIds.length;

  bool get hasSearchMatches => _searchMatchIds.isNotEmpty;

  /// The ID of the currently focused search match, or -1.
  int get focusedMatchId {
    if (_focusedMatchIndex < 0 ||
        _focusedMatchIndex >= _searchMatchIds.length) {
      return -1;
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
    } else {
      filterManager.updateFilterSearchQuery(
        searchController.text,
        immediate: true,
      );
    }
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

  void disposeSearch() {
    searchController.dispose();
  }
}
