import 'package:flutter/material.dart';

class ISpectifyActionItem {
  const ISpectifyActionItem({
    required this.onTap,
    required this.title,
    required this.icon,
  });

  final void Function(BuildContext context)? onTap;
  final String title;
  final IconData icon;
}
