import 'package:flutter/material.dart';
import 'package:ispect/src/core/res/ispect_theme.dart';

/// ISpect's built-in default design language: dark-first, flat, with
/// tonal-elevation surfaces (layered by lightness, not shadow) and a single
/// blue accent.
///
/// Used as the fallback palette when the consumer hasn't overridden a colour
/// and [ISpectTheme.useHostColors] is off, so ISpect keeps a consistent
/// identity regardless of the host app's theme.
abstract final class ISpectDefaultPalette {
  const ISpectDefaultPalette._();

  /// Outermost surface — scaffolds, sheets, dialog scrims.
  static const ISpectDynamicColor background = ISpectDynamicColor(
    dark: Color(0xFF0E0E11),
    light: Color(0xFFF6F6F8),
  );

  /// Inset cards, tiles, and input fields one tonal step above [background].
  static const ISpectDynamicColor card = ISpectDynamicColor(
    dark: Color(0xFF1B1B1F),
    light: Color(0xFFFFFFFF),
  );

  /// Rows / list items — one tonal step *below* [card] so tiles read on top.
  static const ISpectDynamicColor rowCard = ISpectDynamicColor(
    dark: Color(0xFF151518),
    light: Color(0xFFF1F1F4),
  );

  /// Primary text and icons.
  static const ISpectDynamicColor foreground = ISpectDynamicColor(
    dark: Color(0xFFF5F5F7),
    light: Color(0xFF1A1A1E),
  );

  /// Hairline dividers.
  static const ISpectDynamicColor divider = ISpectDynamicColor(
    dark: Color(0xFF2A2A2E),
    light: Color(0xFFE2E2E6),
  );

  /// Single accent — primary buttons, focus, selection, links.
  static const ISpectDynamicColor primary = ISpectDynamicColor(
    dark: Color(0xFF3B82F6),
    light: Color(0xFF2F6FE0),
  );

  /// Error / destructive state.
  static const ISpectDynamicColor error = ISpectDynamicColor(
    dark: Color(0xFFFF6B6B),
    light: Color(0xFFD32F2F),
  );
}
