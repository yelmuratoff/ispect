import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/screen_size.dart';

/// Centralized UI metrics for ISpect's compact desktop chrome.
abstract final class ISpectDesktopMetrics {
  static const VisualDensity buttonDensity =
      VisualDensity(horizontal: -4, vertical: -4);
  static const double inputMinHeight = 30;
  static const double squareControlSize = 30;
  static const double toolbarHeight = 44;
  static const double titleScale = 0.85;
  static const double iconSize = 18;

  static const double defaultInputMinHeight = 40;
  static const double defaultSquareControlSize = 40;
  static const double defaultIconSize = 22;
}

extension ISpectDesktopMetricsContextExtension on BuildContext {
  bool get _isIspectDesktop => screenSize.isDesktop;

  VisualDensity? get ispectAppBarButtonDensity =>
      _isIspectDesktop ? ISpectDesktopMetrics.buttonDensity : null;

  double get ispectInputMinHeight => _isIspectDesktop
      ? ISpectDesktopMetrics.inputMinHeight
      : ISpectDesktopMetrics.defaultInputMinHeight;

  double get ispectSquareControlSize => _isIspectDesktop
      ? ISpectDesktopMetrics.squareControlSize
      : ISpectDesktopMetrics.defaultSquareControlSize;

  double? get ispectAppBarToolbarHeight =>
      _isIspectDesktop ? ISpectDesktopMetrics.toolbarHeight : null;

  double get ispectAppBarIconSize => _isIspectDesktop
      ? ISpectDesktopMetrics.iconSize
      : ISpectDesktopMetrics.defaultIconSize;
}
