import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';

/// A utility class providing common decoration patterns used throughout the app.
///
/// This class follows the DRY (Don't Repeat Yourself) principle by centralizing
/// commonly used decoration patterns. Surfaces use squircle (continuous) corners
/// via [ISpectSquircle] so they match the rest of the ISpect design system.
final class DecorationUtils {
  const DecorationUtils._();

  /// Creates a squircle border decoration with a colored border.
  ///
  /// Uses [ISpectConstants.largeBorderRadius] for the border radius.
  static ShapeDecoration roundedBorder({
    required Color color,
    double? borderRadius,
  }) =>
      ISpectSquircle.decoration(
        radius: borderRadius ?? ISpectConstants.largeBorderRadius,
        side: BorderSide(color: color),
      );

  /// Creates a squircle background decoration with a colored background.
  ///
  /// Uses [ISpectConstants.standardBorderRadius] for the border radius.
  static ShapeDecoration roundedBackground({
    required Color color,
    double? borderRadius,
    double? opacity,
  }) =>
      ISpectSquircle.decoration(
        color: color.withValues(
          alpha: opacity ?? ISpectConstants.iconButtonBackgroundOpacity,
        ),
        radius: borderRadius ?? ISpectConstants.standardBorderRadius,
      );

  /// Creates a standard border radius used in icon buttons and small components.
  static BorderRadius get standardBorderRadius => const BorderRadius.all(
        Radius.circular(ISpectConstants.standardBorderRadius),
      );

  /// Creates a large border radius used in containers and cards.
  static BorderRadius get largeBorderRadius => const BorderRadius.all(
        Radius.circular(ISpectConstants.largeBorderRadius),
      );
}
