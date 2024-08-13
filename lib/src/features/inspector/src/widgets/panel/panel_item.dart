import 'package:flutter/material.dart';

class ISpectPanelItem {
  const ISpectPanelItem({
    required this.icon,
    this.enableBadge = false,
    this.onTap,
  });

  final IconData icon;
  final bool enableBadge;
  final VoidCallback? onTap;
}
