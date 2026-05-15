import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/screen_size.dart';

/// Centralized UI metrics for ISpect's compact desktop chrome.
///
/// Keeping these values in one place lets every screen render the same
/// toolbar feel without sprinkling magic numbers across the widget tree.
abstract final class ISpectDesktopMetrics {
  /// Density that shrinks Material IconButtons to a tighter desktop hit box.
  ///
  /// `VisualDensity(-4, -4)` is the most compact density Flutter allows and
  /// brings IconButton's min size down from 48 to 32 logical pixels.
  static const VisualDensity buttonDensity =
      VisualDensity(horizontal: -4, vertical: -4);

  /// Compact min height applied to inputs (search field, filter button).
  static const double inputMinHeight = 30;

  /// Compact square size for non-IconButton chrome controls.
  static const double squareControlSize = 30;

  /// Compact toolbar height for app bars on desktop.
  static const double toolbarHeight = 44;

  /// Multiplier applied to app bar title font sizes.
  static const double titleScale = 0.85;

  /// Icon size used inside AppBar IconButtons on desktop.
  static const double iconSize = 18;

  /// Default non-desktop input min height (matches Material SearchBar default).
  static const double defaultInputMinHeight = 40;

  /// Default non-desktop square control size.
  static const double defaultSquareControlSize = 40;

  /// Default non-desktop icon size for AppBar buttons.
  static const double defaultIconSize = 22;
}

/// Context-aware accessors that fall back to mobile-friendly defaults when
/// the layout is narrower than [ISpectScreenSize.desktop].
extension ISpectDesktopMetricsContextExtension on BuildContext {
  bool get _isIspectDesktop => screenSize.isDesktop;

  /// Compact density for AppBar IconButtons on desktop, `null` otherwise so
  /// the default Material density applies.
  VisualDensity? get ispectAppBarButtonDensity =>
      _isIspectDesktop ? ISpectDesktopMetrics.buttonDensity : null;

  /// Compact min height for search-like inputs.
  double get ispectInputMinHeight => _isIspectDesktop
      ? ISpectDesktopMetrics.inputMinHeight
      : ISpectDesktopMetrics.defaultInputMinHeight;

  /// Compact square size for chrome controls (e.g. the filter button).
  double get ispectSquareControlSize => _isIspectDesktop
      ? ISpectDesktopMetrics.squareControlSize
      : ISpectDesktopMetrics.defaultSquareControlSize;

  /// Compact toolbar height for app bars on desktop, `null` otherwise so the
  /// AppBar keeps its platform-default height.
  double? get ispectAppBarToolbarHeight =>
      _isIspectDesktop ? ISpectDesktopMetrics.toolbarHeight : null;

  /// Icon size for IconButtons rendered inside AppBars.
  double get ispectAppBarIconSize => _isIspectDesktop
      ? ISpectDesktopMetrics.iconSize
      : ISpectDesktopMetrics.defaultIconSize;
}
