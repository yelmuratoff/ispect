import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

class DetailedItemContainer extends StatelessWidget {
  const DetailedItemContainer({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color:
              context.adjustColor(context.ispectTheme.scaffoldBackgroundColor),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: child,
        ),
      );
}
