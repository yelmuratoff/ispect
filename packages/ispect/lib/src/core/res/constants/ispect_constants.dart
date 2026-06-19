import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/log_viewer/domain/models/log_description.dart';

part 'ispect_log_icons.dart';
part 'ispect_log_palette.dart';
part 'ispect_log_descriptions.dart';

/// Numeric, color, and log-type constants used across the ISpect UI. The
/// large icon / color / description tables live in sibling `part` files;
/// this class re-exposes them so call sites stay on a single namespace.
final class ISpectConstants {
  const ISpectConstants._();

  // ===== UI Sizing & Layout =====

  static const double draggableButtonWidth = 60;
  static const double draggableButtonHeight = 60;

  static const double logCardIconSize = 16;
  static const double iconButtonDimension = 24;
  static const double iconButtonIconSize = 16;
  static const double actionControlHeight = 28;

  static const double smallBorderRadius = 4;
  static const double mediumBorderRadius = 6;
  static const double standardBorderRadius = 8;
  static const double largeBorderRadius = 10;
  static const double snackbarBorderRadius = 16;

  static const double standardHorizontalPadding = 12;
  static const double standardVerticalPadding = 8;
  static const double standardGap = 6;

  // ===== Animation & Limits =====

  static const int animationDurationMs = 150;
  static const int stackTraceMaxLines = 50;

  // ===== Opacities =====

  static const double standardBackgroundOpacity = 0.08;
  static const double iconButtonBackgroundOpacity = 0.1;
  static const double disabledOpacity = 0.5;

  // ===== Colors =====

  static const Color toastBackgroundColor = Color.fromARGB(255, 49, 49, 49);

  // ===== Misc =====

  static const String hidden = 'Hidden';

  // ===== Log-type tables (defined in part files) =====

  static const Map<String, IconData> typeIcons = _kTypeIcons;
  static const Map<String, Color> lightTypeColors = _kLightTypeColors;
  static const Map<String, Color> darkTypeColors = _kDarkTypeColors;

  static List<LogDescription> defaultLogDescriptions(BuildContext context) =>
      _buildDefaultLogDescriptions(context);
}
