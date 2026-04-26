import 'package:flutter/material.dart';

/// Looks up which `ColorScheme` token(s) a picked colour corresponds to.
///
/// The reverse lookup table (`argb32 → [tokenNames]`) is cached per
/// [ColorScheme] instance via an [Expando], so the 50-entry map is built
/// at most once per scheme — not on every pointer tick during picking.
class ColorSchemeInspector {
  ColorSchemeInspector._();

  static final Expando<Map<int, List<String>>> _cache =
      Expando('ColorSchemeInspector.reverseLookup');

  /// Returns all `ColorScheme` tokens that exactly match [color], or an empty
  /// list if none match. Multiple tokens can share a value (e.g.
  /// `primary` == `inversePrimary` in some themes), so callers should be
  /// prepared to render more than one.
  static List<String> matchingTokens(Color color, ColorScheme scheme) {
    final lookup = _cache[scheme] ??= _buildReverseLookup(scheme);
    return lookup[color.toARGB32()] ?? const [];
  }

  /// Backwards-compatible string form: `colorScheme.foo` or
  /// `colorScheme.foo, colorScheme.bar`. Returns empty string when no match.
  ///
  /// Prefer [matchingTokens] for new code — it preserves structure for the UI.
  static String identifyColorSchemeMatch(
    Color color,
    ColorScheme colorScheme,
  ) {
    final names = matchingTokens(color, colorScheme);
    if (names.isEmpty) return '';
    return names.map((n) => 'colorScheme.$n').join(', ');
  }

  static Map<int, List<String>> _buildReverseLookup(ColorScheme s) {
    // Order matters: tokens listed earlier win when callers want a single
    // representative match. Keep the canonical roles first.
    final entries = <String, Color>{
      'primary': s.primary,
      'onPrimary': s.onPrimary,
      'primaryContainer': s.primaryContainer,
      'onPrimaryContainer': s.onPrimaryContainer,
      'primaryFixed': s.primaryFixed,
      'onPrimaryFixed': s.onPrimaryFixed,
      'primaryFixedDim': s.primaryFixedDim,
      'onPrimaryFixedVariant': s.onPrimaryFixedVariant,
      'secondary': s.secondary,
      'onSecondary': s.onSecondary,
      'secondaryContainer': s.secondaryContainer,
      'onSecondaryContainer': s.onSecondaryContainer,
      'secondaryFixed': s.secondaryFixed,
      'onSecondaryFixed': s.onSecondaryFixed,
      'secondaryFixedDim': s.secondaryFixedDim,
      'onSecondaryFixedVariant': s.onSecondaryFixedVariant,
      'tertiary': s.tertiary,
      'onTertiary': s.onTertiary,
      'tertiaryContainer': s.tertiaryContainer,
      'onTertiaryContainer': s.onTertiaryContainer,
      'tertiaryFixed': s.tertiaryFixed,
      'onTertiaryFixed': s.onTertiaryFixed,
      'tertiaryFixedDim': s.tertiaryFixedDim,
      'onTertiaryFixedVariant': s.onTertiaryFixedVariant,
      'error': s.error,
      'onError': s.onError,
      'errorContainer': s.errorContainer,
      'onErrorContainer': s.onErrorContainer,
      'outline': s.outline,
      'outlineVariant': s.outlineVariant,
      'surface': s.surface,
      'onSurface': s.onSurface,
      'onSurfaceVariant': s.onSurfaceVariant,
      'inverseSurface': s.inverseSurface,
      'onInverseSurface': s.onInverseSurface,
      'inversePrimary': s.inversePrimary,
      'shadow': s.shadow,
      'surfaceTint': s.surfaceTint,
      'scrim': s.scrim,
      'surfaceContainerHighest': s.surfaceContainerHighest,
      'surfaceContainerHigh': s.surfaceContainerHigh,
      'surfaceContainer': s.surfaceContainer,
      'surfaceContainerLow': s.surfaceContainerLow,
      'surfaceContainerLowest': s.surfaceContainerLowest,
      'surfaceBright': s.surfaceBright,
      'surfaceDim': s.surfaceDim,
    };

    final lookup = <int, List<String>>{};
    for (final entry in entries.entries) {
      final key = entry.value.toARGB32();
      (lookup[key] ??= <String>[]).add(entry.key);
    }
    return lookup;
  }
}
