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

  bool get isISpectEnabled => _isISpectEnabled;

  bool get isPerformanceTrackingEnabled => _isPerformanceTrackingEnabled;

  ISpectOptions get options => _options;

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
}

/// `ISpectScopeWrapper` is a wrapper widget that provides the `ISpectScopeModel` to its children.
class ISpectScopeWrapper extends StatelessWidget {
  final Widget child;
  final ISpectOptions options;
  final bool isISpectEnabled;

  const ISpectScopeWrapper({
    required this.child,
    required this.options,
    required this.isISpectEnabled,
    super.key,
  });

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<ISpectScopeModel>(
        create: (context) => ISpectScopeModel()
          ..setOptions(options)
          ..setISpect = isISpectEnabled,
        child: child,
      );
}
