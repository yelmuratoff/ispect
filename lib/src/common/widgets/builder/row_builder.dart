import 'package:flutter/material.dart';

///* `RowBuilder` - This widget is designed to build a row layout with a specified number of child widgets,
///which are generated dynamically based on an IndexedWidgetBuilder function.

class RowBuilder extends StatelessWidget {
  const RowBuilder({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.textDirection,
    this.verticalDirection = VerticalDirection.down,
  });
  final IndexedWidgetBuilder itemBuilder;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final TextDirection? textDirection;
  final VerticalDirection verticalDirection;
  final int itemCount;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: mainAxisAlignment,
        mainAxisSize: mainAxisSize,
        crossAxisAlignment: crossAxisAlignment,
        textDirection: textDirection,
        verticalDirection: verticalDirection,
        children:
            List.generate(itemCount, (index) => itemBuilder(context, index)),
      );
}
