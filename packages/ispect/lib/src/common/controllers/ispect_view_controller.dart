import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/download_logs/download_logs.dart';
import 'package:ispectify/ispectify.dart';

class ISpectifyViewController extends ChangeNotifier {
  ISpectifyFilter _filter = ISpectifyFilter();
  bool _expandedLogs = true;
  bool _isLogOrderReversed = true;

  ISpectifyFilter get filter => _filter;
  set filter(ISpectifyFilter val) {
    _filter = val;
    notifyListeners();
  }

  bool get expandedLogs => _expandedLogs;

  void toggleExpandedLogs() {
    _expandedLogs = !_expandedLogs;
    notifyListeners();
  }

  bool get isLogOrderReversed => _isLogOrderReversed;

  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  void updateFilterSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  void addFilterType(Type type) {
    final currentTypes = _getCurrentTypes();
    _filter = ISpectifyFilter(
      titles: _getCurrentTitles(),
      types: [...currentTypes, type],
      searchQuery: _getCurrentSearchQuery(),
    );
    notifyListeners();
  }

  void removeFilterType(Type type) {
    final currentTypes = _getCurrentTypes();
    _filter = ISpectifyFilter(
      titles: _getCurrentTitles(),
      types: currentTypes.where((t) => t != type).toList(),
      searchQuery: _getCurrentSearchQuery(),
    );
    notifyListeners();
  }

  void addFilterTitle(String title) {
    final currentTitles = _getCurrentTitles();
    _filter = ISpectifyFilter(
      titles: [...currentTitles, title],
      types: _getCurrentTypes(),
      searchQuery: _getCurrentSearchQuery(),
    );
    notifyListeners();
  }

  void removeFilterTitle(String title) {
    final currentTitles = _getCurrentTitles();
    _filter = ISpectifyFilter(
      titles: currentTitles.where((t) => t != title).toList(),
      types: _getCurrentTypes(),
      searchQuery: _getCurrentSearchQuery(),
    );
    notifyListeners();
  }

  Future<void> downloadLogsFile(String logs) async => downloadFile(logs);

  void update() => notifyListeners();

  List<String> _getCurrentTitles() {
    final titleFilter = _filter.filters.firstWhere(
      (f) => f is TitleFilter,
      orElse: () => TitleFilter([]),
    ) as TitleFilter;
    return titleFilter.titles.toList();
  }

  List<Type> _getCurrentTypes() {
    final typeFilter = _filter.filters.firstWhere(
      (f) => f is TypeFilter,
      orElse: () => TypeFilter([]),
    ) as TypeFilter;
    return typeFilter.types.toList();
  }

  String? _getCurrentSearchQuery() {
    final searchFilter = _filter.filters.firstWhere(
      (f) => f is SearchFilter,
      orElse: () => SearchFilter(''),
    ) as SearchFilter;
    return searchFilter.query.isEmpty ? null : searchFilter.query;
  }
}
