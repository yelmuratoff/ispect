import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/icons.dart';

/// `ISpectScopeModel` is a model class that holds the state of the ISpect scope.
class ISpectScopeModel extends ChangeNotifier {
  ISpectScopeModel({
    bool isISpectEnabled = false,
    bool isPerformanceTrackingEnabled = false,
    ISpectOptions options = const ISpectOptions(),
    ISpectTheme theme = const ISpectTheme(),
    this.observer,
  })  : _isISpectEnabled = isISpectEnabled,
        _isPerformanceTrackingEnabled = isPerformanceTrackingEnabled,
        _options = options,
        _theme = theme;

  bool _isISpectEnabled;
  bool get isISpectEnabled => _isISpectEnabled;
  set isISpectEnabled(bool value) {
    if (_isISpectEnabled != value) {
      _isISpectEnabled = value;
      notifyListeners();
    }
  }

  bool _isPerformanceTrackingEnabled;
  bool get isPerformanceTrackingEnabled => _isPerformanceTrackingEnabled;
  set isPerformanceTrackingEnabled(bool value) {
    if (_isPerformanceTrackingEnabled != value) {
      _isPerformanceTrackingEnabled = value;
      notifyListeners();
    }
  }

  ISpectOptions _options;
  ISpectOptions get options => _options;
  set options(ISpectOptions value) {
    _options = value;
    notifyListeners();
  }

  ISpectTheme _theme;
  ISpectTheme get theme => _theme;
  set theme(ISpectTheme value) {
    _theme = value.copyWith(
      logIcons: {
        ...typeIcons,
        ...value.logIcons,
      },
    );
    notifyListeners();
  }

  NavigatorObserver? observer;

  void toggleISpect() {
    isISpectEnabled = !isISpectEnabled;
  }

  void togglePerformanceTracking() {
    isPerformanceTrackingEnabled = !isPerformanceTrackingEnabled;
  }
}

/// InheritedNotifier to provide the `ISpectScopeModel` to the widget tree.
class ISpectScopeController extends InheritedNotifier<ISpectScopeModel> {
  const ISpectScopeController({
    required ISpectScopeModel model,
    required super.child,
  }) : super(notifier: model);

  static ISpectScopeModel of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<ISpectScopeController>();
    assert(inherited != null, 'No ISpectScopeModel found in context');
    return inherited!.notifier!;
  }
}
