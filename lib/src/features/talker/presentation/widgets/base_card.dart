// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';
import 'package:talker_flutter/src/ui/theme/default_theme.dart';

class ISpectBaseCard extends StatelessWidget {
  const ISpectBaseCard({
    required this.child,
    required this.color,
    super.key,
    this.padding = const EdgeInsets.all(4),
    this.backgroundColor = defaultCardBackgroundColor,
  });

  final Widget child;
  final Color color;
  final EdgeInsets? padding;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Ink(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor,
          ),
          child: child,
        ),
      );
}
