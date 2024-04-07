import 'package:flutter/material.dart';

final class ISpectController extends ChangeNotifier {
  bool _isPerformanceTrackingEnabled = false;
  bool _isInspectorEnabled = false;

  bool get isPerformanceTrackingEnabled => _isPerformanceTrackingEnabled;
  bool get isInspectorEnabled => _isInspectorEnabled;

  void togglePerformanceTracking() {
    _isPerformanceTrackingEnabled = !_isPerformanceTrackingEnabled;
    notifyListeners();
  }

  void toggleInspector() {
    _isInspectorEnabled = !_isInspectorEnabled;
    notifyListeners();
  }

  void reset() {
    _isPerformanceTrackingEnabled = false;
    _isInspectorEnabled = false;
    notifyListeners();
  }
}
