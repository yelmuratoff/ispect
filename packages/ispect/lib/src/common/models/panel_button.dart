import 'package:flutter/material.dart';

/// A labelled button displayed in the ISpect expanded panel menu.
///
/// Unlike [ISpectPanelItem], this variant includes a text [label] and is
/// typically used for secondary actions in the panel's button row.
@immutable
class ISpectPanelButtonItem {
  /// Creates a panel button with the given [icon], [label], and [onTap]
  /// callback.
  const ISpectPanelButtonItem({
    required this.onTap,
    required this.label,
    required this.icon,
  });

  /// The icon displayed for this button.
  final IconData icon;

  /// The text label displayed alongside the icon.
  final String label;

  /// Called when the user taps this button.
  final void Function(BuildContext context) onTap;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ISpectPanelButtonItem &&
        other.icon == icon &&
        other.label == label;
  }

  @override
  int get hashCode => Object.hash(icon, label);
}
