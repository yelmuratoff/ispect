import 'package:flutter/material.dart';

/// Visual palette for the inspector overlay. Passed in via [Inspector.theme]
/// so host apps can retune accent colours (e.g. for dark themes where the
/// default blue selection lacks contrast against a `colorScheme.primary` of
/// similar hue).
@immutable
class InspectorTheme {
  const InspectorTheme({
    this.selectedColor = const Color(0xFF2962FF),
    this.hoveredColor = const Color(0xFF448AFF),
    this.comparedColor = const Color(0xFFFF6D00),
    this.containerColor = const Color(0xFFFFB300),
    this.compareLineColor,
    this.chromeAccentColor = const Color(0xFF3B82F6),
    this.chromeSurfaceColor = const Color(0xFF1E1E1E),
    this.chromeOnSurfaceColor = Colors.white70,
    this.chromeOnAccentColor = Colors.white,
  });

  /// Outline/fill for the primary (tap-selected) target.
  final Color selectedColor;

  /// Outline for the mouse/pointer hover target (dashed).
  final Color hoveredColor;

  /// Outline/fill for the second target in compare mode.
  final Color comparedColor;

  /// Padding-highlight wash drawn when the selection has a parent container.
  final Color containerColor;

  /// Dashed measurement line between the selected and compared targets.
  /// Falls back to `Colors.green.shade700` when null.
  final Color? compareLineColor;

  /// Accent for active controls in the inspector chrome (panel, action bar).
  final Color chromeAccentColor;

  /// Neutral surface for inactive controls in the inspector chrome.
  final Color chromeSurfaceColor;

  /// Foreground on [chromeSurfaceColor].
  final Color chromeOnSurfaceColor;

  /// Foreground on [chromeAccentColor].
  final Color chromeOnAccentColor;

  static const InspectorTheme defaults = InspectorTheme();

  InspectorTheme copyWith({
    Color? selectedColor,
    Color? hoveredColor,
    Color? comparedColor,
    Color? containerColor,
    Color? compareLineColor,
    Color? chromeAccentColor,
    Color? chromeSurfaceColor,
    Color? chromeOnSurfaceColor,
    Color? chromeOnAccentColor,
  }) =>
      InspectorTheme(
        selectedColor: selectedColor ?? this.selectedColor,
        hoveredColor: hoveredColor ?? this.hoveredColor,
        comparedColor: comparedColor ?? this.comparedColor,
        containerColor: containerColor ?? this.containerColor,
        compareLineColor: compareLineColor ?? this.compareLineColor,
        chromeAccentColor: chromeAccentColor ?? this.chromeAccentColor,
        chromeSurfaceColor: chromeSurfaceColor ?? this.chromeSurfaceColor,
        chromeOnSurfaceColor: chromeOnSurfaceColor ?? this.chromeOnSurfaceColor,
        chromeOnAccentColor: chromeOnAccentColor ?? this.chromeOnAccentColor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectorTheme &&
          selectedColor == other.selectedColor &&
          hoveredColor == other.hoveredColor &&
          comparedColor == other.comparedColor &&
          containerColor == other.containerColor &&
          compareLineColor == other.compareLineColor &&
          chromeAccentColor == other.chromeAccentColor &&
          chromeSurfaceColor == other.chromeSurfaceColor &&
          chromeOnSurfaceColor == other.chromeOnSurfaceColor &&
          chromeOnAccentColor == other.chromeOnAccentColor;

  @override
  int get hashCode => Object.hash(
        selectedColor,
        hoveredColor,
        comparedColor,
        containerColor,
        compareLineColor,
        chromeAccentColor,
        chromeSurfaceColor,
        chromeOnSurfaceColor,
        chromeOnAccentColor,
      );
}
