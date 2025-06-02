import 'package:flutter/material.dart';

class ISpectActionItem {
  const ISpectActionItem({
    required this.onTap,
    required this.title,
    required this.icon,
  });

  final void Function(BuildContext context)? onTap;
  final String title;
  final IconData icon;
}
