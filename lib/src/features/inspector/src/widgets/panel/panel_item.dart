import 'package:flutter/material.dart';

class ISpectPanelItem {
  const ISpectPanelItem({
    required this.icon,
    required this.onTap,
    this.enableBadge = false,
  });

  final IconData icon;
  final bool enableBadge;
  final void Function(BuildContext context) onTap;
}

class ISpectPanelButton {
  const ISpectPanelButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  final void Function(BuildContext context) onTap;
}
