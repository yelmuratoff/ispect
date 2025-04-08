import 'package:flutter/material.dart';

/// A card-like container widget that wraps its child
/// with customizable styling.
///
/// The `JsonCard` provides a way to display content within a decorated container
/// with configurable background color, padding, border radius, and border side.
///
/// Example:
/// ```dart
/// JsonCard(
///   backgroundColor: Colors.blue,
///   child: Text('Hello'),
///   padding: EdgeInsets.all(8),
///   borderRadius: BorderRadius.circular(8),
///   borderSide: BorderSide(color: Colors.black),
/// )
/// ```
///
/// Parameters:
/// * `child` - The widget to be displayed inside the card.
/// * `backgroundColor` - Optional background color for the card.
/// * `padding` - The internal padding of the card. Defaults to horizontal padding of 4.
/// * `borderRadius` - The border radius of the card. Defaults to 4 pixels on all corners.
/// * `borderSide` - Optional border styling for the card.
///
/// The background color, if provided, will be applied with 20% opacity (alpha: 0.2).

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
