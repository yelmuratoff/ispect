import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

enum EmptyLogsReason { noLogs, noMatches, noSessions }

class EmptyLogsWidget extends StatelessWidget {
  const EmptyLogsWidget({required this.reason, this.onClearFilters, super.key});

  final EmptyLogsReason reason;

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    final onSurface = context.appTheme.colorScheme.onSurface;
    final muted = onSurface.withValues(alpha: 0.15);
    final cardColor = context.ispectRowCardColor;
    final (icon, badgeIcon, title, hint) = switch (reason) {
      EmptyLogsReason.noLogs => (
        Icons.terminal_rounded,
        null,
        l10n.noLogsYet,
        l10n.noLogsYetHint,
      ),
      EmptyLogsReason.noMatches => (
        Icons.terminal_rounded,
        Icons.search_off_rounded,
        l10n.noMatchingLogs,
        l10n.noResultsHint,
      ),
      EmptyLogsReason.noSessions => (
        Icons.history_rounded,
        null,
        l10n.noSavedSessions,
        l10n.noSavedSessionsHint,
      ),
    };

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
                      icon,
                      size: 36,
                      color: onSurface.withValues(alpha: 0.18),
                    ),
                    if (badgeIcon != null)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            badgeIcon,
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
              title,
              textAlign: TextAlign.center,
              style: context.appTheme.textTheme.titleMedium?.copyWith(
                color: onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(6),
            Text(
              hint,
              style: context.appTheme.textTheme.bodySmall?.copyWith(
                color: onSurface.withValues(alpha: 0.45),
              ),
              textAlign: TextAlign.center,
            ),
            if (onClearFilters case final onClear?) ...[
              const Gap(12),
              TextButton.icon(
                onPressed: onClear,
                icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
                label: Text(l10n.clearAllFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
