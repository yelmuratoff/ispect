import 'package:flutter/material.dart';

/// A [Column] whose children are produced lazily from an
/// [IndexedWidgetBuilder], mirroring the API of [ListView.builder] but without
/// a scroll view.
///
/// Useful for small, fixed-count lists where scrolling isn't wanted but an
/// index-driven builder is convenient.
class ISpectColumnBuilder extends StatelessWidget {
  /// Creates a column that builds [itemCount] children via [itemBuilder].
  const ISpectColumnBuilder({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.verticalDirection = VerticalDirection.down,
  });

  /// Called for each index in `[0, itemCount)` to produce a child.
  final IndexedWidgetBuilder itemBuilder;

  /// How children are placed along the main (vertical) axis.
  final MainAxisAlignment mainAxisAlignment;

  /// How much space the column should occupy on its main axis.
  final MainAxisSize mainAxisSize;

  /// How children are placed along the cross (horizontal) axis.
  final CrossAxisAlignment crossAxisAlignment;

  /// Whether children are laid out top-to-bottom or bottom-to-top.
  final VerticalDirection verticalDirection;

  /// Number of children the column should contain.
  final int itemCount;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        mainAxisAlignment: mainAxisAlignment,
        verticalDirection: verticalDirection,
        children: List.generate(
          itemCount,
          (index) => itemBuilder(context, index),
          growable: false,
        ),
      );
}
