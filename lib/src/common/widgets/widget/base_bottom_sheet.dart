import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';

class BaseBottomSheet extends StatelessWidget {
  const BaseBottomSheet({
    required this.child,
    required this.title,
    super.key,
  });

  final Widget child;
  final String title;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.only(
          top: 10,
          bottom: mq.padding.bottom,
        ),
        decoration: BoxDecoration(
          color: context.ispectTheme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8)
                  .copyWith(
                bottom: 8,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(color: context.ispectTheme.textColor),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: context.ispectTheme.textColor,
                    ),
                  ),
                ],
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}
