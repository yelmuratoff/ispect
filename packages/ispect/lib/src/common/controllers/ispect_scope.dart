// ignore_for_file: avoid_setters_without_getters

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/icons.dart';

/// `ISpectScopeModel` is a model class that holds the state of the ISpect scope.
class ISpectScopeModel {
  ISpectScopeModel({
    this.isISpectEnabled = false,
    this.isPerformanceTrackingEnabled = false,
    this.options = const ISpectOptions(),
    this.theme = const ISpectTheme(),
    this.observer,
  });

  bool isISpectEnabled;
  bool isPerformanceTrackingEnabled;
  ISpectOptions options;
  ISpectTheme theme;

  NavigatorObserver? observer;

  void toggleISpect() {
    isISpectEnabled = !isISpectEnabled;
  }

  set setISpect(bool value) {
    isISpectEnabled = value;
  }

  void togglePerformanceTracking() {
    isPerformanceTrackingEnabled = !isPerformanceTrackingEnabled;
  }

  set setPerformanceTracking(bool value) {
    isPerformanceTrackingEnabled = value;
  }

  void setOptions(ISpectOptions? newOptions) {
    if (newOptions != null) {
      options = newOptions;
    }
  }

  void setTheme(ISpectTheme? newTheme) {
    if (newTheme != null) {
      theme = newTheme.copyWith(
        logIcons: {
          ...typeIcons,
          ...newTheme.logIcons,
        },
      );
    } else {
      theme = const ISpectTheme(
        logIcons: typeIcons,
      );
    }
  }
}

/// `ISpectScopeWrapper` is a wrapper widget that provides the `ISpectScopeModel` to its children.
class ISpectScopeWrapper extends StatefulWidget {
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
  State<ISpectScopeWrapper> createState() => _ISpectScopeWrapperState();
}

class _ISpectScopeWrapperState extends State<ISpectScopeWrapper> {
  late ISpectScopeModel model;

  @override
  void initState() {
    super.initState();
    model = ISpectScopeModel();

    model
      ..setISpect = widget.isISpectEnabled
      ..setOptions(widget.options)
      ..setTheme(widget.theme);
  }

  @override
  Widget build(BuildContext context) => ISpectScopeController(
        model: model,
        child: widget.child,
      );
}

/// InheritedWidget to provide the `ISpectScopeModel` to the widget tree.
class ISpectScopeController extends InheritedWidget {
  const ISpectScopeController({
    required this.model,
    required super.child,
  });

  final ISpectScopeModel model;

  static ISpectScopeModel of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<ISpectScopeController>();
    assert(inherited != null, 'No ISpectScopeModel found in context');
    return inherited!.model;
  }

  @override
  bool updateShouldNotify(covariant ISpectScopeController oldWidget) => oldWidget.model != model;
}
