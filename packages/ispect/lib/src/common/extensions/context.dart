import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';

/// List of extensions for `BuildContext`
extension ISpectContextExtension on BuildContext {
  // /// `theme` returns the current `ThemeData` of the `BuildContext`.
  ThemeData get appTheme => Theme.of(this);

  ISpectTheme get ispectTheme => iSpect.theme;

  bool get isDarkMode => appTheme.brightness == Brightness.dark;

  /// Returns the current `ISpectAppLocalizations` of the `BuildContext`.
  ISpectGeneratedLocalization get ispectL10n => ISpectLocalization.of(this);

  ISpectScopeModel get iSpect => ISpect.read(this);

  Color adjustColor(Color color) => isDarkMode
      ? adjustColorBrightness(color, 0.9)
      : adjustColorDarken(color, 0.1);
}

extension ISpectColorExtension on ThemeData {
  Color get textColor => colorScheme.onSurface;
}

/// Shared color tokens used across ISpect's surfaces, sheets, dialogs, and
/// inputs. Prefer these over re-declaring the same resolve/fallback chain in
/// every widget.
extension ISpectColorTokens on BuildContext {
  /// Primary accent (highlights, focus, icon tint).
  Color get ispectPrimaryColor =>
      ispectTheme.primary?.resolve(this) ?? appTheme.colorScheme.primary;

  /// Background for the outermost surface (dialogs, bottom sheets).
  Color get ispectBackgroundColor =>
      ispectTheme.background?.resolve(this) ??
      appTheme.colorScheme.surfaceContainerLowest;

  /// Background for inset cards, tiles, and input fields living on top of the
  /// background surface.
  Color get ispectCardColor =>
      ispectTheme.card?.resolve(this) ??
      appTheme.colorScheme.surfaceContainerHigh;

  /// Subtle 1px border tint shared by tiles, inputs, and chips.
  Color get ispectSubtleBorderColor =>
      appTheme.colorScheme.onSurface.withValues(alpha: 0.08);
}

extension OptionsExtension on ISpectOptions {
  Future<void> push(BuildContext context, Route<dynamic> route) async {
    if (observer != null) {
      await observer?.navigator?.push(route);
    } else {
      await Navigator.of(context).push(route);
    }
  }

  void pop(BuildContext context) {
    if (observer != null) {
      observer?.navigator?.pop();
    } else {
      Navigator.of(context).pop();
    }
  }
}
