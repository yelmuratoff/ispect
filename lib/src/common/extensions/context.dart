import 'package:flutter/material.dart';
import 'package:ispect/src/core/localization/localization.dart';

/// List of extensions for `BuildContext`
extension ISpectContextExtension on BuildContext {
  /// `theme` returns the current `ThemeData` of the `BuildContext`.
  ThemeData get ispectTheme => Theme.of(this);

  /// Returns the current `ISpectAppLocalizations` of the `BuildContext`.
  ISpectGeneratedLocalization get ispectL10n => ISpectLocalization.of(this);
}

extension ISpectColorExtension on ThemeData {
  Color get textColor => colorScheme.onSurface;
}
