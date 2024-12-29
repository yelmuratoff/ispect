// ignore_for_file: implementation_imports

import 'package:flutter/material.dart';

class ISpectBaseCard extends StatelessWidget {
  const ISpectBaseCard({
    required this.child,
    required this.color,
    super.key,
    this.padding = const EdgeInsets.all(4),
    this.backgroundColor = const Color.fromARGB(255, 49, 49, 49),
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
