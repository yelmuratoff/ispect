import 'package:flutter/widgets.dart';

final class ISpectModalTracker extends ChangeNotifier {
  int _openModals = 0;

  bool get hasOpenModal => _openModals > 0;

  void open() {
    _openModals++;
    if (_openModals == 1) notifyListeners();
  }

  void close() {
    if (_openModals == 0) return;
    _openModals--;
    if (_openModals == 0) notifyListeners();
  }
}

class ISpectModalTrackerScope extends InheritedWidget {
  const ISpectModalTrackerScope({
    required this.tracker,
    required super.child,
    super.key,
  });

  final ISpectModalTracker tracker;

  static ISpectModalTracker? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<ISpectModalTrackerScope>()?.tracker;

  @override
  bool updateShouldNotify(ISpectModalTrackerScope oldWidget) =>
      !identical(tracker, oldWidget.tracker);
}

class ISpectModalGuard extends StatefulWidget {
  const ISpectModalGuard({required this.child, super.key});

  final Widget child;

  @override
  State<ISpectModalGuard> createState() => _ISpectModalGuardState();
}

class _ISpectModalGuardState extends State<ISpectModalGuard> {
  ISpectModalTracker? _tracker;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final tracker = ISpectModalTrackerScope.maybeOf(context);
    if (identical(tracker, _tracker)) return;
    _tracker?.close();
    _tracker = tracker?..open();
  }

  @override
  void dispose() {
    _tracker?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
