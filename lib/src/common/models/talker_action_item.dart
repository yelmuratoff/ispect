import 'package:flutter/material.dart';

class TalkerActionItem {
  const TalkerActionItem({
    required this.onTap,
    required this.title,
    required this.icon,
    this.contextOnTap,
  });

  final VoidCallback onTap;
  final String title;
  final IconData icon;
  final void Function(BuildContext context)? contextOnTap;
}
