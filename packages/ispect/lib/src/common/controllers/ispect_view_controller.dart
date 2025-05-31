import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/download_logs/download_logs.dart';
import 'package:ispectify/ispectify.dart';

/// Controller for managing the state of ISpectify views.
///
/// This class extends `ChangeNotifier` to provide state updates
/// when filters, log visibility, or log order change.
class ISpectifyViewController extends ChangeNotifier {
  ISpectifyFilter _filter = ISpectifyFilter();
  bool _expandedLogs = true;
  bool _isLogOrderReversed = true;
  ISpectifyData? _activeData;

  /// Retrieves the current log filter.
  ISpectifyFilter get filter => _filter;

  /// Updates the log filter and notifies listeners.
  set filter(ISpectifyFilter val) {
    if (_filter != val) {
      _filter = val;
      notifyListeners();
    }
  }

  set activeData(ISpectifyData? data) {
    _activeData = data;
    notifyListeners();
  }

  /// Indicates whether logs are expanded.
  bool get expandedLogs => _expandedLogs;

  ISpectifyData? get activeData => _activeData;

  /// Toggles the expanded logs state and notifies listeners.
  void toggleExpandedLogs() {
    _expandedLogs = !_expandedLogs;
    notifyListeners();
  }

  /// Indicates whether log order is reversed.
  bool get isLogOrderReversed => _isLogOrderReversed;

  /// Toggles the log order between normal and reversed.
  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  /// Updates the filter's search query and notifies listeners.
  void updateFilterSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  /// Adds a new filter type and notifies listeners.
  void addFilterType(Type type) {
    final currentTypes = _getCurrentTypes();
    if (!currentTypes.contains(type)) {
      _filter = ISpectifyFilter(
        titles: _getCurrentTitles(),
        types: [...currentTypes, type],
        searchQuery: _getCurrentSearchQuery(),
      );
      notifyListeners();
    }
  }

  /// Removes a filter type and notifies listeners.
  void removeFilterType(Type type) {
    final updatedTypes = _getCurrentTypes().where((t) => t != type).toList();
    if (updatedTypes.length != _getCurrentTypes().length) {
      _filter = ISpectifyFilter(
        titles: _getCurrentTitles(),
        types: updatedTypes,
        searchQuery: _getCurrentSearchQuery(),
      );
      notifyListeners();
    }
  }

  /// Adds a new filter title and notifies listeners.
  void addFilterTitle(String title) {
    final currentTitles = _getCurrentTitles();
    if (!currentTitles.contains(title)) {
      _filter = ISpectifyFilter(
        titles: [...currentTitles, title],
        types: _getCurrentTypes(),
        searchQuery: _getCurrentSearchQuery(),
      );
      notifyListeners();
    }
  }

  /// Removes a filter title and notifies listeners.
  void removeFilterTitle(String title) {
    final updatedTitles = _getCurrentTitles().where((t) => t != title).toList();
    if (updatedTitles.length != _getCurrentTitles().length) {
      _filter = ISpectifyFilter(
        titles: updatedTitles,
        types: _getCurrentTypes(),
        searchQuery: _getCurrentSearchQuery(),
      );
      notifyListeners();
    }
  }

  /// Downloads logs as a file.
  Future<void> downloadLogsFile(String logs) async => downloadFile(logs);

  /// Forces a UI update.
  void update() => notifyListeners();

  /// Retrieves the current title filters.
  List<String> _getCurrentTitles() => (_filter.filters.firstWhere(
        (f) => f is TitleFilter,
        orElse: () => TitleFilter([]),
      ) as TitleFilter)
          .titles
          .toList();

  /// Retrieves the current type filters.
  List<Type> _getCurrentTypes() => (_filter.filters.firstWhere(
        (f) => f is TypeFilter,
        orElse: () => TypeFilter([]),
      ) as TypeFilter)
          .types
          .toList();

  /// Retrieves the current search query, returning `null` if empty.
  String? _getCurrentSearchQuery() {
    final query = (_filter.filters.firstWhere(
      (f) => f is SearchFilter,
      orElse: () => SearchFilter(''),
    ) as SearchFilter)
        .query;
    return query.isEmpty ? null : query;
  }
}
