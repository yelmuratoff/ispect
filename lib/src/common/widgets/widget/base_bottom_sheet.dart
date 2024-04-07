import 'package:flutter/material.dart';
import 'package:talker_flutter/talker_flutter.dart';

class BaseBottomSheet extends StatelessWidget {
  const BaseBottomSheet({
    required this.talkerScreenTheme,
    required this.child,
    required this.title,
    super.key,
  });

  final TalkerScreenTheme talkerScreenTheme;
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
          color: talkerScreenTheme.backgroundColor,
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
                        ?.copyWith(color: talkerScreenTheme.textColor),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: talkerScreenTheme.textColor,
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
