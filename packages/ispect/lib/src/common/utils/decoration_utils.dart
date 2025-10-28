import 'package:flutter/material.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

/// A utility class providing common decoration patterns used throughout the app.
///
/// This class follows the DRY (Don't Repeat Yourself) principle by centralizing
/// commonly used BoxDecoration patterns.
final class DecorationUtils {
  const DecorationUtils._();

  /// Creates a rounded border decoration with a colored border.
  ///
  /// Uses [ISpectConstants.largeBorderRadius] for the border radius.
  static BoxDecoration roundedBorder({
    required Color color,
    double? borderRadius,
  }) =>
      BoxDecoration(
        borderRadius: BorderRadius.all(
          Radius.circular(borderRadius ?? ISpectConstants.largeBorderRadius),
        ),
        border: Border.all(color: color),
      );

  /// Creates a rounded background decoration with a colored background.
  ///
  /// Uses [ISpectConstants.standardBorderRadius] for the border radius.
  static BoxDecoration roundedBackground({
    required Color color,
    double? borderRadius,
    double? opacity,
  }) =>
      BoxDecoration(
        color: color.withValues(
          alpha: opacity ?? ISpectConstants.iconButtonBackgroundOpacity,
        ),
        borderRadius: BorderRadius.all(
          Radius.circular(borderRadius ?? ISpectConstants.standardBorderRadius),
        ),
      );

  /// Creates a standard border radius used in icon buttons and small components.
  static BorderRadius get standardBorderRadius => const BorderRadius.all(
        Radius.circular(ISpectConstants.standardBorderRadius),
      );

  /// Creates a large border radius used in containers and cards.
  static BorderRadius get largeBorderRadius => const BorderRadius.all(
        Radius.circular(ISpectConstants.largeBorderRadius),
      );

  /// Creates a snackbar border radius.
  static BorderRadius get snackbarBorderRadius => const BorderRadius.all(
        Radius.circular(ISpectConstants.snackbarBorderRadius),
      );
}
