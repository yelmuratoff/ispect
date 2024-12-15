import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/adjust_color.dart';
import 'package:ispect/src/core/localization/localization.dart';

/// List of extensions for `BuildContext`
extension ISpectContextExtension on BuildContext {
  /// `theme` returns the current `ThemeData` of the `BuildContext`.
  ThemeData get ispectTheme => Theme.of(this);

  bool get isDarkMode => ispectTheme.brightness == Brightness.dark;

  /// Returns the current `ISpectAppLocalizations` of the `BuildContext`.
  ISpectGeneratedLocalization get ispectL10n => ISpectLocalization.of(this);

  Color adjustColor(Color color) => isDarkMode
      ? adjustColorBrightness(color, 0.9)
      : adjustColorDarken(color, 0.1);
}

extension ISpectColorExtension on ThemeData {
  Color get textColor => colorScheme.onSurface;
}
