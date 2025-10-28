// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

///* `ISpectColumnBuilder` - This widget is designed to build a column layout with a specified number of child widgets,
/// which are generated dynamically based on an IndexedWidgetBuilder function.

class ISpectColumnBuilder extends StatelessWidget {
  const ISpectColumnBuilder({
    required this.itemBuilder,
    required this.itemCount,
    super.key,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.mainAxisSize = MainAxisSize.max,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.verticalDirection = VerticalDirection.down,
  });
  final IndexedWidgetBuilder itemBuilder;
  final MainAxisAlignment mainAxisAlignment;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;
  final VerticalDirection verticalDirection;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>.filled(
      itemCount,
      const SizedBox.shrink(),
    );

    for (var i = 0; i < itemCount; i++) {
      children[i] = itemBuilder(context, i);
    }

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: mainAxisSize,
      mainAxisAlignment: mainAxisAlignment,
      verticalDirection: verticalDirection,
      children: children,
    );
  }
}
