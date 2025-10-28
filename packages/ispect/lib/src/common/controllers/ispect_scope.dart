import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

/// A model class that holds the state of the ISpect scope.
///
/// This class extends `ChangeNotifier` to allow UI updates when the state changes.
class ISpectScopeModel extends ChangeNotifier {
  /// Creates an instance of `ISpectScopeModel`.
  ///
  /// - `isISpectEnabled`: Whether ISpect is enabled.
  /// - `isPerformanceTrackingEnabled`: Whether performance tracking is enabled.
  /// - `options`: Configurations for ISpect.
  /// - `theme`: Theme settings for ISpect.
  /// - `observer`: An optional `NavigatorObserver` for tracking navigation events.
  ISpectScopeModel({
    bool isISpectEnabled = false,
    bool isPerformanceTrackingEnabled = false,
    ISpectOptions? options,
    ISpectTheme theme = const ISpectTheme(),
    this.observer,
  })  : _isISpectEnabled = isISpectEnabled,
        _isPerformanceTrackingEnabled = isPerformanceTrackingEnabled,
        _options = options ?? ISpectOptions(observer: observer),
        _theme = theme;

  // Private fields to store state
  bool _isISpectEnabled;
  bool _isPerformanceTrackingEnabled;
  ISpectOptions _options;
  ISpectTheme _theme;

  /// Helper method to update a value and notify listeners if changed.
  void _updateValue<T>(T currentValue, T newValue, void Function(T) setter) {
    if (currentValue != newValue) {
      setter(newValue);
      notifyListeners();
    }
  }

  /// Indicates whether ISpect is enabled.
  bool get isISpectEnabled => _isISpectEnabled;
  set isISpectEnabled(bool value) =>
      _updateValue(_isISpectEnabled, value, (v) => _isISpectEnabled = v);

  /// Indicates whether performance tracking is enabled.
  bool get isPerformanceTrackingEnabled => _isPerformanceTrackingEnabled;
  set isPerformanceTrackingEnabled(bool value) => _updateValue(
        _isPerformanceTrackingEnabled,
        value,
        (v) => _isPerformanceTrackingEnabled = v,
      );

  /// Configuration options for ISpect.
  ISpectOptions get options => _options;
  set options(ISpectOptions value) =>
      _updateValue(_options, value, (v) => _options = v);

  /// Theming settings for ISpect.
  ISpectTheme get theme => _theme;
  set theme(ISpectTheme value) {
    final updatedTheme = value.copyWith(
      logIcons: {
        ...ISpectConstants.typeIcons, // Default icons
        ...value.logIcons, // Custom user-defined icons
      },
    );
    _updateValue(_theme, updatedTheme, (v) => _theme = v);
  }

  /// A navigator observer for tracking navigation events.
  NavigatorObserver? observer;

  /// Toggles the ISpect state.
  void toggleISpect() {
    isISpectEnabled = !isISpectEnabled;
  }

  /// Toggles the performance tracking state.
  void togglePerformanceTracking() {
    isPerformanceTrackingEnabled = !isPerformanceTrackingEnabled;
  }
}

/// Provides the `ISpectScopeModel` to the widget tree.
///
/// This class uses `InheritedNotifier` to make [ISpectScopeModel]
/// accessible in the widget tree.
class ISpectScopeController extends InheritedNotifier<ISpectScopeModel> {
  /// Creates an instance of `ISpectScopeController`.
  ///
  /// - `model`: The `ISpectScopeModel` instance.
  /// - `child`: The widget subtree that can access the model.
  const ISpectScopeController({
    required ISpectScopeModel model,
    required super.child,
  }) : super(notifier: model);

  /// Retrieves the nearest `ISpectScopeModel` in the widget tree.
  ///
  /// Throws an assertion error if no `ISpectScopeController` is found.
  static ISpectScopeModel of(BuildContext context) {
    final inherited =
        context.dependOnInheritedWidgetOfExactType<ISpectScopeController>();
    assert(inherited != null, 'No ISpectScopeModel found in context');
    return inherited!.notifier!;
  }
}
