import 'package:flutter/material.dart';
import 'package:ispect/src/common/utils/squircle.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/core/res/ispect_default_palette.dart';

/// Builds the [ThemeData] ISpect injects above its own surfaces (via
/// `ISpectThemeScope`) so every `Theme.of(context)` inside ISpect resolves to
/// the owned flat, tonal design language. [dark] selects the dark (default) or
/// light variant.
///
/// The token getters in `ISpectColorTokens` fall back to `colorScheme.*`, so
/// mapping the owned palette onto the surface-container scale here re-skins
/// those call sites without rewiring each getter.
ThemeData buildISpectThemeData({required bool dark}) {
  final background = ISpectDefaultPalette.background.pick(isDark: dark)!;
  final card = ISpectDefaultPalette.card.pick(isDark: dark)!;
  final rowCard = ISpectDefaultPalette.rowCard.pick(isDark: dark)!;
  final foreground = ISpectDefaultPalette.foreground.pick(isDark: dark)!;
  final divider = ISpectDefaultPalette.divider.pick(isDark: dark)!;
  final primary = ISpectDefaultPalette.primary.pick(isDark: dark)!;
  final brightness = dark ? Brightness.dark : Brightness.light;

  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: primary,
    onPrimary: Colors.white,
    secondary: primary,
    onSecondary: Colors.white,
    surface: background,
    onSurface: foreground,
    surfaceContainerLowest: background,
    surfaceContainerLow: rowCard,
    surfaceContainer: card,
    surfaceContainerHigh: card,
    surfaceContainerHighest: card,
    onSurfaceVariant: foreground.withValues(alpha: 0.7),
    outline: foreground.withValues(alpha: 0.12),
    outlineVariant: foreground.withValues(alpha: 0.08),
    error: ISpectDefaultPalette.error.pick(isDark: dark)!,
    onError: Colors.white,
  );

  final squircle =
      WidgetStatePropertyAll<OutlinedBorder>(ISpectSquircle.border());

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: background,
    canvasColor: background,
    cardColor: rowCard,
    dividerColor: divider,
    dividerTheme: DividerThemeData(color: divider, space: 1, thickness: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        shape: squircle,
        backgroundColor: WidgetStatePropertyAll(primary),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        shape: squircle,
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(shape: squircle),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(shape: squircle),
    ),
    chipTheme: ChipThemeData(
      shape:
          ISpectSquircle.border(radius: ISpectConstants.standardBorderRadius),
    ),
  );
}
