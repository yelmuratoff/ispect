import 'package:flutter/material.dart';

class TalkerActionItem {
  const TalkerActionItem({
    required this.onTap,
    required this.title,
    required this.icon,
  });

  final void Function(BuildContext context)? onTap;
  final String title;
  final IconData icon;
}
