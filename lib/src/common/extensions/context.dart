import 'package:flutter/material.dart';
import 'package:ispect/src/core/localization/localization.dart';
import 'package:ispect/src/core/localization/translations/app_localizations.dart';

/// List of extensions for `BuildContext`
extension ISpectContextExtension on BuildContext {
  /// `theme` returns the current `ThemeData` of the `BuildContext`.
  ThemeData get ispectTheme => Theme.of(this);

  /// Returns the current `AppLocalizations` of the `BuildContext`.
  AppLocalizations get ispectL10n => Localization.of(this);
}
