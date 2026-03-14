import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

/// Status bar at the bottom of the desktop log view.
class DesktopStatusBar extends StatelessWidget {
  const DesktopStatusBar({
    required this.filteredCount,
    required this.totalCount,
    required this.isFiltered,
    required this.useRelativeTime,
    required this.onToggleTimestamp,
    this.selectedLog,
    this.isLiveTailActive = false,
    super.key,
  });

  final int filteredCount;
  final int totalCount;
  final bool isFiltered;
  final ISpectLogData? selectedLog;
  final bool isLiveTailActive;
  final bool useRelativeTime;
  final VoidCallback onToggleTimestamp;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final onSurface = context.appTheme.colorScheme.onSurface;
    final borderColor = onSurface.withValues(alpha: 0.1);
    final labelColor = onSurface.withValues(alpha: 0.55);

    final countText =
        isFiltered ? '$filteredCount / $totalCount' : '$totalCount';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            // Live tail indicator
            if (isLiveTailActive) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              const Gap(6),
              const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                  letterSpacing: 0.5,
                ),
              ),
              const Gap(10),
            ],
            Icon(
              Icons.list_alt_rounded,
              size: 14,
              color: labelColor,
            ),
            const Gap(6),
            Text(
              '$countText logs',
              style: TextStyle(fontSize: 12, color: labelColor),
            ),
            if (selectedLog != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: SizedBox(
                  height: 12,
                  child: VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: onSurface.withValues(alpha: 0.12),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  '${selectedLog!.key ?? ''} \u2014 '
                  '${selectedLog!.formattedTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ] else
              const Spacer(),
            // Timestamp format toggle
            Tooltip(
              message: useRelativeTime ? 'Absolute time' : 'Relative time',
              child: InkWell(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                onTap: onToggleTimestamp,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    useRelativeTime
                        ? Icons.access_time_rounded
                        : Icons.schedule_rounded,
                    size: 14,
                    color: useRelativeTime
                        ? context.appTheme.colorScheme.primary
                        : labelColor,
                  ),
                ),
              ),
            ),
            const Gap(10),
            const _KeyBadge(label: '\u2191\u2193'),
            const Gap(4),
            Text(
              'navigate',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const Gap(12),
            const _KeyBadge(label: '\u23CE'),
            const Gap(4),
            Text(
              'open',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const Gap(12),
            _KeyBadge(
              label: Theme.of(context).platform == TargetPlatform.macOS
                  ? '\u2318C'
                  : 'Ctrl+C',
            ),
            const Gap(4),
            Text(
              context.ispectL10n.copy.toLowerCase(),
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const Gap(12),
            const _KeyBadge(label: '/'),
            const Gap(4),
            Text(
              'search',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
            const Gap(12),
            const _KeyBadge(label: 'Esc'),
            const Gap(4),
            Text(
              'close',
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  const _KeyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: onSurface.withValues(alpha: 0.06),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        border: Border.all(color: onSurface.withValues(alpha: 0.12)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: onSurface.withValues(alpha: 0.5),
            height: 1.3,
          ),
        ),
      ),
    );
  }
}
