import 'package:flutter/foundation.dart';
import 'package:ispect/ispect.dart';

/// Display toggles backing the Settings sheet and in-screen action chips.
/// `ISpectViewController` keeps these fields in lockstep with
/// `ISpectSettingsState` so values persist across sessions.
class DisplayController extends ChangeNotifier {
  DisplayController({ISpectSettingsState? initialSettings})
      : _expandedLogs = initialSettings?.expandedLogs ?? false,
        _isLogOrderReversed = initialSettings?.isLogOrderReversed ?? true,
        _groupHttpLogs = initialSettings?.groupHttpLogs ?? true,
        _useRelativeTime = initialSettings?.useRelativeTime ?? false,
        _compactNetworkUrls = initialSettings?.compactNetworkUrls ?? true;

  bool _expandedLogs;
  bool _isLogOrderReversed;
  bool _groupHttpLogs;
  bool _useRelativeTime;
  bool _compactNetworkUrls;

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

  set isLogOrderReversed(bool value) {
    if (_isLogOrderReversed == value) return;
    _isLogOrderReversed = value;
    notifyListeners();
  }

  void toggleLogOrder() {
    _isLogOrderReversed = !_isLogOrderReversed;
    notifyListeners();
  }

  bool get groupHttpLogs => _groupHttpLogs;

  set groupHttpLogs(bool value) {
    if (_groupHttpLogs == value) return;
    _groupHttpLogs = value;
    notifyListeners();
  }

  void toggleGroupHttpLogs() {
    _groupHttpLogs = !_groupHttpLogs;
    notifyListeners();
  }

  bool get useRelativeTime => _useRelativeTime;

  set useRelativeTime(bool value) {
    if (_useRelativeTime == value) return;
    _useRelativeTime = value;
    notifyListeners();
  }

  void toggleTimestampFormat() {
    _useRelativeTime = !_useRelativeTime;
    notifyListeners();
  }

  bool get compactNetworkUrls => _compactNetworkUrls;

  set compactNetworkUrls(bool value) {
    if (_compactNetworkUrls == value) return;
    _compactNetworkUrls = value;
    notifyListeners();
  }

  void toggleCompactNetworkUrls() {
    _compactNetworkUrls = !_compactNetworkUrls;
    notifyListeners();
  }

  void applyFromSettings(ISpectSettingsState settings) {
    final changed = _expandedLogs != settings.expandedLogs ||
        _isLogOrderReversed != settings.isLogOrderReversed ||
        _groupHttpLogs != settings.groupHttpLogs ||
        _useRelativeTime != settings.useRelativeTime ||
        _compactNetworkUrls != settings.compactNetworkUrls;
    if (!changed) return;
    _expandedLogs = settings.expandedLogs;
    _isLogOrderReversed = settings.isLogOrderReversed;
    _groupHttpLogs = settings.groupHttpLogs;
    _useRelativeTime = settings.useRelativeTime;
    _compactNetworkUrls = settings.compactNetworkUrls;
    notifyListeners();
  }
}
