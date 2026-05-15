import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// Indicator shown when new logs arrive while user is scrolled away.
class NewLogsIndicator extends StatelessWidget {
  const NewLogsIndicator({
    required this.onTap,
    this.pointUp = false,
    super.key,
  });

  final VoidCallback onTap;
  final bool pointUp;

  @override
  Widget build(BuildContext context) {
    final primary = context.appTheme.colorScheme.primary;

    return Center(
      child: Material(
        color: primary,
        borderRadius: const BorderRadius.all(Radius.circular(16)),
        elevation: 4,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  pointUp
                      ? Icons.arrow_upward_rounded
                      : Icons.arrow_downward_rounded,
                  size: 14,
                  color: context.appTheme.colorScheme.onPrimary,
                ),
                const Gap(6),
                Text(
                  'New logs',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.appTheme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// FAB for scrolling to top or bottom of the logs list.
class ScrollToEdgeFab extends StatelessWidget {
  const ScrollToEdgeFab({
    required this.onPressed,
    required this.isAtBottom,
    super.key,
  });

  final VoidCallback onPressed;
  final bool isAtBottom;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final borderColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.08);

    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          onTap: onPressed,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              border: Border.all(color: borderColor),
            ),
            child: Icon(
              isAtBottom
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 22,
              color:
                  context.appTheme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
