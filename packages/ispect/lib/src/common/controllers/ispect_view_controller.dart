import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/download_logs/download_nonweb_logs.dart'
    if (dart.library.html) 'package:ispect/src/common/utils/download_logs/download_web_logs.dart';
import 'package:ispectify/ispectify.dart';

/// Controller to work with [ISpectifyScreen]
class ISpectifyViewController extends ChangeNotifier {
  BaseISpectifyFilter _filter = BaseISpectifyFilter();

  var _expandedLogs = true;
  bool _isLogOrderReversed = true;

  /// Filter for selecting specific logs and errors
  BaseISpectifyFilter get filter => _filter;
  set filter(BaseISpectifyFilter val) {
    _filter = val;
    notifyListeners();
  }

  bool get expandedLogs => _expandedLogs;

  void toggleExpandedLogs() {
    _expandedLogs = !_expandedLogs;
    notifyListeners();
  }

  bool get isLogOrderReversed => _isLogOrderReversed;

  /// Toggle log order (earliest or latest first)
  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  /// Method for updating a search query based on errors and logs
  void updateFilterSearchQuery(String query) {
    _filter = _filter.copyWith(searchQuery: query);
    notifyListeners();
  }

  /// Method adds an type to the filter
  void addFilterType(Type type) {
    _filter = _filter.copyWith(types: [..._filter.types, type]);
    notifyListeners();
  }

  /// Method removes an type from the filter
  void removeFilterType(Type type) {
    _filter = _filter.copyWith(types: _filter.types.where((t) => t != type).toList());
    notifyListeners();
  }

  /// Method adds an title to the filter
  void addFilterTitle(String title) {
    _filter = _filter.copyWith(titles: [..._filter.titles, title]);
    notifyListeners();
  }

  /// Method removes an title from the filter
  void removeFilterTitle(String title) {
    _filter = _filter.copyWith(titles: _filter.titles.where((t) => t != title).toList());
    notifyListeners();
  }

  Future<void> downloadLogsFile(String logs) async => downloadFile(logs);

  /// Redefinition [notifyListeners]
  void update() => notifyListeners();
}
