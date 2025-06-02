import 'package:flutter/material.dart';

@immutable
class ISpectPanelButtonItem {
  const ISpectPanelButtonItem({
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ISpectPanelButtonItem &&
        other.icon == icon &&
        other.label == label &&
        other.onTap == onTap;
  }

  @override
  int get hashCode => Object.hash(icon, label, onTap);
}
