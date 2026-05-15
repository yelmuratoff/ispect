import 'package:flutter/material.dart';

/// Tracks whether the inspector's logger page is currently active so the
/// floating panel can hide its draggable button while the user is inside the
/// log viewer.
final class ISpectLogPageController extends ChangeNotifier {
  bool _inLoggerPage = false;

  /// Indicates whether the logger page is currently active.
  bool get inLoggerPage => _inLoggerPage;

  /// Updates the state of the logger page.
  ///
  /// - `isLoggerPage`: A boolean value indicating whether the logger page is active.
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

/// Renamed to [ISpectLogPageController] in 5.0.0 for consistency with the
/// ISpect* package prefix. Will be removed in 6.0.0.
@Deprecated(
  'Use ISpectLogPageController instead. Will be removed in 6.0.0.',
)
typedef LogPageController = ISpectLogPageController;
