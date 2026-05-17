import 'package:flutter/material.dart';

/// Describes a tappable action shown inside the ISpect inspector panel
/// (e.g. in the custom-actions grid).
///
/// Instances are compared by [title] + [icon] only — tap handlers and
/// descriptions don't contribute to equality.
@immutable
class ISpectActionItem {
  /// Creates an action item with the given label, icon, and tap handler.
  const ISpectActionItem({
    required this.onTap,
    required this.title,
    required this.icon,
    this.description,
  });

  /// Invoked when the action is tapped. `null` disables the action.
  final void Function(BuildContext context)? onTap;

  /// Human-readable label shown under the icon.
  final String title;

  /// Icon shown on the action tile.
  final IconData icon;

  /// Optional secondary text shown below the title.
  final String? description;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ISpectActionItem &&
        other.title == title &&
        other.icon == icon;
  }

  @override
  int get hashCode => Object.hash(title, icon);
}
