import 'package:flutter/material.dart';

@immutable
class ISpectActionItem {
  const ISpectActionItem({
    required this.onTap,
    required this.title,
    required this.icon,
  });

  final void Function(BuildContext context)? onTap;
  final String title;
  final IconData icon;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ISpectActionItem &&
        other.title == title &&
        other.icon == icon &&
        other.onTap == onTap;
  }

  @override
  int get hashCode => Object.hash(title, icon, onTap);
}
