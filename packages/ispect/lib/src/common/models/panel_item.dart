import 'package:flutter/material.dart';

class ISpectPanelItem {
  const ISpectPanelItem({
    required this.onTap,
    required this.enableBadge,
    required this.icon,
  });

  final IconData icon;
  final bool enableBadge;
  final void Function(BuildContext context) onTap;
}
