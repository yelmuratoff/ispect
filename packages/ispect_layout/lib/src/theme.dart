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

  static const InspectorTheme defaults = InspectorTheme();

  InspectorTheme copyWith({
    Color? selectedColor,
    Color? hoveredColor,
    Color? comparedColor,
    Color? containerColor,
    Color? compareLineColor,
  }) =>
      InspectorTheme(
        selectedColor: selectedColor ?? this.selectedColor,
        hoveredColor: hoveredColor ?? this.hoveredColor,
        comparedColor: comparedColor ?? this.comparedColor,
        containerColor: containerColor ?? this.containerColor,
        compareLineColor: compareLineColor ?? this.compareLineColor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectorTheme &&
          selectedColor == other.selectedColor &&
          hoveredColor == other.hoveredColor &&
          comparedColor == other.comparedColor &&
          containerColor == other.containerColor &&
          compareLineColor == other.compareLineColor;

  @override
  int get hashCode => Object.hash(
        selectedColor,
        hoveredColor,
        comparedColor,
        containerColor,
        compareLineColor,
      );
}
