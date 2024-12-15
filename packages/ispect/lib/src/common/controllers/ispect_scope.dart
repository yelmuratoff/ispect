// ignore_for_file: avoid_setters_without_getters

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/icons.dart';

import 'package:provider/provider.dart';

/// `ISpectScopeModel` is a model class that holds the state of the ISpect scope.
class ISpectScopeModel with ChangeNotifier {
  bool _isISpectEnabled = false;
  bool _isPerformanceTrackingEnabled = false;
  ISpectOptions _options = const ISpectOptions();
  ISpectTheme _theme = const ISpectTheme();

  NavigatorObserver? _observer;

  bool get isISpectEnabled => _isISpectEnabled;

  bool get isPerformanceTrackingEnabled => _isPerformanceTrackingEnabled;

  ISpectOptions get options => _options;

  ISpectTheme get theme => _theme;

  NavigatorObserver? get observer => _observer;

  set setObserver(NavigatorObserver? observer) {
    _observer = observer;
    notifyListeners();
  }

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

  void setOptions(ISpectOptions? options) {
    if (options == null) return;

    _options = options;
    notifyListeners();
  }

  void setTheme(ISpectTheme? theme) {
    if (theme != null) {
      _theme = theme.copyWith(
        logIcons: {
          ...typeIcons,
          ...theme.logIcons,
        },
      );
    } else {
      _theme = const ISpectTheme(
        logIcons: typeIcons,
      );
    }
    notifyListeners();
  }
}

/// `ISpectScopeWrapper` is a wrapper widget that provides the `ISpectScopeModel` to its children.
class ISpectScopeWrapper extends StatelessWidget {
  const ISpectScopeWrapper({
    required this.child,
    required this.isISpectEnabled,
    this.options,
    this.theme,
    super.key,
  });
  final Widget child;
  final ISpectOptions? options;
  final ISpectTheme? theme;
  final bool isISpectEnabled;

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider<ISpectScopeModel>(
        create: (_) => ISpectScopeModel()
          ..setISpect = isISpectEnabled
          ..setOptions(options)
          ..setTheme(theme),
        child: child,
      );
}
