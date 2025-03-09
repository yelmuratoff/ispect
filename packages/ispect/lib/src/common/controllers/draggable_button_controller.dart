import 'package:flutter/material.dart';

/// A controller for managing the state of the inspector.
///
/// This class extends [ChangeNotifier] to allow UI updates when the state changes.
final class InspectorController extends ChangeNotifier {
  bool _inLoggerPage = false;

  /// Indicates whether the logger page is currently active.
  bool get inLoggerPage => _inLoggerPage;

  /// Updates the state of the logger page.
  ///
  /// - [isLoggerPage]: A boolean value indicating whether the logger page is active.
  /// - Notifies listeners of the change.
  void setInLoggerPage({required bool isLoggerPage}) {
    if (_inLoggerPage != isLoggerPage) {
      _inLoggerPage = isLoggerPage;
      notifyListeners();
    }
  }

  /// Resets the state, marking the logger page as inactive.
  ///
  /// - Notifies listeners of the change.
  void reset() {
    if (_inLoggerPage) {
      _inLoggerPage = false;
      notifyListeners();
    }
  }
}
