// ignore_for_file: avoid_setters_without_getters

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:provider/provider.dart';

/// `ISpectScopeModel` is a model class that holds the state of the ISpect scope.
class ISpectScopeModel with ChangeNotifier {
  bool _isISpectEnabled = false;
  bool _isPerformanceTrackingEnabled = false;
  ISpectOptions _options = const ISpectOptions(
    locale: Locale('en'),
  );
  ISpectTheme _theme = const ISpectTheme();

  bool get isISpectEnabled => _isISpectEnabled;

  bool get isPerformanceTrackingEnabled => _isPerformanceTrackingEnabled;

  ISpectOptions get options => _options;

  ISpectTheme get theme => _theme;

  void toggleISpect() {
    _isISpectEnabled = !_isISpectEnabled;
    notifyListeners();
  }

  set setISpect(bool value) {
    _isISpectEnabled = value;
    notifyListeners();
  }

  void togglePerformanceTracking() {
    _isPerformanceTrackingEnabled = !_isPerformanceTrackingEnabled;
    notifyListeners();
  }

  set setPerformanceTracking(bool value) {
    _isPerformanceTrackingEnabled = value;
    notifyListeners();
  }

  void setOptions(ISpectOptions options) {
    _options = options;
    notifyListeners();
  }

  void setTheme(ISpectTheme? theme) {
    if (theme != null) {
      _theme = theme;
    }
    notifyListeners();
  }
}

/// `ISpectScopeWrapper` is a wrapper widget that provides the `ISpectScopeModel` to its children.
class ISpectScopeWrapper extends StatelessWidget {
  const ISpectScopeWrapper({
    required this.child,
    required this.options,
    required this.isISpectEnabled,
    this.theme,
    super.key,
  });
  final Widget child;
  final ISpectOptions options;
  final ISpectTheme? theme;
  final bool isISpectEnabled;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<ISpectScopeModel>(
        create: (_) => ISpectScopeModel()
          ..setOptions(options)
          ..setTheme(theme)
          ..setISpect = isISpectEnabled,
        child: child,
      );
}
