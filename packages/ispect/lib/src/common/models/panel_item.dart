import 'package:flutter/material.dart';

/// An item displayed in the ISpect floating panel.
///
/// Each item has an [icon], an optional badge indicator, and a tap callback
/// that receives the current [BuildContext].
@immutable
class ISpectPanelItem {
  /// Creates a panel item with the given [icon], [enableBadge] flag, and
  /// [onTap] callback.
  const ISpectPanelItem({
    required this.onTap,
    required this.enableBadge,
    required this.icon,
  });

  /// The icon displayed for this panel item.
  final IconData icon;

  /// Whether to show a notification badge on this item.
  final bool enableBadge;

  /// Called when the user taps this panel item.
  final void Function(BuildContext context) onTap;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ISpectPanelItem &&
        other.icon == icon &&
        other.enableBadge == enableBadge;
  }

  @override
  int get hashCode => Object.hash(icon, enableBadge);
}
