import 'package:ispectify/ispectify.dart';
import 'package:material_ui/material_ui.dart';

/// Tracks whether the inspector's logger page is currently active so the
/// floating panel can hide its draggable button while the user is inside the
/// log viewer.
final class ISpectLogPageController extends ChangeNotifier {
  bool _inLoggerPage = false;
  int _unseenErrorCount = 0;

  /// Indicates whether the logger page is currently active.
  bool get inLoggerPage => _inLoggerPage;

  /// The number of error entries logged since the logger page was last
  /// opened. Entries logged while the page is open count as seen.
  int get unseenErrorCount => _unseenErrorCount;

  /// Updates the state of the logger page.
  ///
  /// - `isLoggerPage`: A boolean value indicating whether the logger page is active.
  /// - Opening the page marks every error as seen.
  /// - Notifies listeners of the change.
  void setInLoggerPage({required bool isLoggerPage}) {
    if (_inLoggerPage == isLoggerPage) return;
    _inLoggerPage = isLoggerPage;
    if (isLoggerPage) _unseenErrorCount = 0;
    notifyListeners();
  }

  /// Counts [log] as unseen when it is an error and the logger page is
  /// closed, and notifies listeners when the count changes.
  void recordLog(ISpectLogData log) {
    if (_inLoggerPage || !log.isError) return;
    _unseenErrorCount++;
    notifyListeners();
  }

  /// Forgets every unseen error, as when the logger they came from goes away.
  void resetUnseenErrors() {
    if (_unseenErrorCount == 0) return;
    _unseenErrorCount = 0;
    notifyListeners();
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
/// ISpect* package prefix. Will be removed in 8.0.0.
@Deprecated('Use ISpectLogPageController instead. Will be removed in 8.0.0.')
typedef LogPageController = ISpectLogPageController;
