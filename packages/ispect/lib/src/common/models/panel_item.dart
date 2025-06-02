import 'package:flutter/material.dart';

@immutable
class ISpectPanelItem {
  const ISpectPanelItem({
    required this.onTap,
    required this.enableBadge,
    required this.icon,
  });

  final IconData icon;
  final bool enableBadge;
  final void Function(BuildContext context) onTap;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ISpectPanelItem &&
        other.icon == icon &&
        other.enableBadge == enableBadge &&
        other.onTap == onTap;
  }

  @override
  int get hashCode => Object.hash(icon, enableBadge, onTap);
}
