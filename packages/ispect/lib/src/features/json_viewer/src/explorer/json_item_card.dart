import 'package:flutter/material.dart';

class JsonCard extends StatelessWidget {
  const JsonCard({
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: 4,
    ),
    this.borderRadius = const BorderRadius.all(
      Radius.circular(4),
    ),
    this.borderSide,
    super.key,
  });

  final Color? backgroundColor;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final BorderSide? borderSide;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          border:
              borderSide != null ? Border.fromBorderSide(borderSide!) : null,
          color: backgroundColor?.withValues(
            alpha: 0.2,
          ),
          borderRadius: borderRadius,
        ),
        child: Padding(
          padding: padding,
          child: child,
        ),
      );
}
