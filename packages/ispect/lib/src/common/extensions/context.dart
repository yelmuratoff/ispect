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

  ISpectScopeModel get iSpect => ISpectScopeController.of(this);

  Color adjustColor(Color color) => isDarkMode
      ? adjustColorBrightness(color, 0.9)
      : adjustColorDarken(color, 0.1);
}

extension ISpectColorExtension on ThemeData {
  Color get textColor => colorScheme.onSurface;
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
