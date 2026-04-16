import 'package:flutter/foundation.dart';

/// Manages display toggle states: expand/collapse, order, grouping,
/// and timestamp format.
class DisplayController extends ChangeNotifier {
  bool _expandedLogs = true;
  bool _isLogOrderReversed = true;
  bool _groupHttpLogs = true;
  bool _useRelativeTime = false;

  /// Sets the initial value for [groupHttpLogs] before listeners attach.
  // ignore: use_setters_to_change_properties
  void setInitialGroupHttpLogs({required bool value}) {
    _groupHttpLogs = value;
  }

  bool get expandedLogs => _expandedLogs;

  set expandedLogs(bool value) {
    if (_expandedLogs == value) return;
    _expandedLogs = value;
    notifyListeners();
  }

  void toggleExpandedLogs() {
    _expandedLogs = !_expandedLogs;
    notifyListeners();
  }

  bool get isLogOrderReversed => _isLogOrderReversed;

  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  bool get groupHttpLogs => _groupHttpLogs;

  void toggleGroupHttpLogs() {
    _groupHttpLogs = !_groupHttpLogs;
    notifyListeners();
  }

  bool get useRelativeTime => _useRelativeTime;

  void toggleTimestampFormat() {
    _useRelativeTime = !_useRelativeTime;
    notifyListeners();
  }
}
