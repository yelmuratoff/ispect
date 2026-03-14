import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/extensions/string.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// A widget displayed when there are no logs to show.
class EmptyLogsWidget extends StatelessWidget {
  const EmptyLogsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appTheme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.15);
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 56),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cardColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: muted),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.terminal_rounded,
                      size: 36,
                      color: onSurface.withValues(alpha: 0.18),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: cardColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.search_off_rounded,
                          size: 24,
                          color: onSurface.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),
            Text(
              context.ispectL10n.notFound.capitalize(),
              style: context.appTheme.textTheme.titleMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(6),
            Text(
              context.ispectL10n.noResultsHint,
              style: context.appTheme.textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.35),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
