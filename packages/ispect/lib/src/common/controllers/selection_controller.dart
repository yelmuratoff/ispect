import 'package:flutter/foundation.dart';
import 'package:ispectify/ispectify.dart';

/// Manages active log selection and detail panel state.
class SelectionController extends ChangeNotifier {
  ISpectLogData? _activeData;
  ISpectLogData? _detailData;

  ISpectLogData? get activeData => _activeData;

  set activeData(ISpectLogData? data) {
    if (_activeData == data) return;
    _activeData = data;
    notifyListeners();
  }

  ISpectLogData? get detailData => _detailData;

  set detailData(ISpectLogData? data) {
    if (_detailData == data) return;
    _detailData = data;
    notifyListeners();
  }

  /// Single click on desktop: select/highlight only.
  // ignore: use_setters_to_change_properties
  void selectLog(ISpectLogData entry) {
    activeData = entry;
  }

  /// Double click on desktop: open detail panel.
  void openLogDetail(ISpectLogData entry) {
    _activeData = entry;
    _detailData = _detailData == entry ? null : entry;
    notifyListeners();
  }

  /// Select a log and update the detail panel in a single notification.
  void selectAndFollowDetail(ISpectLogData entry) {
    _activeData = entry;
    _detailData = entry;
    notifyListeners();
  }

  /// Close the detail panel without clearing selection.
  void closeDetail() {
    if (_detailData == null) return;
    _detailData = null;
    notifyListeners();
  }

  void handleLogItemTap(ISpectLogData logEntry) {
    activeData = activeData == logEntry ? null : logEntry;
  }
}
