import 'package:flutter/material.dart';

class ISpectPanelButtonItem {
  const ISpectPanelButtonItem({
    required this.onTap,
    required this.label,
    required this.icon,
  });

  final IconData icon;
  final String label;
  final void Function(BuildContext context) onTap;
}
