import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/observers/transition.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/log_card/log_card.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/navigation_flow/actions_sheet.dart';

final _timestampFormat = DateFormat('dd.MM.yy, HH:mm:ss');

class NavigationTransitionCard extends StatelessWidget {
  const NavigationTransitionCard({
    required this.items,
    required this.transition,
    required this.index,
    required this.totalItems,
    this.selectedTransitionId,
    this.log,
  });

  final List<RouteTransition> items;
  final RouteLog? log;
  final RouteTransition transition;
  final int index;
  final int totalItems;
  final String? selectedTransitionId;

  bool get _isSpecial => index == 0 || index == totalItems - 1;
  bool get _isSelected => selectedTransitionId == transition.id;

  @override
  Widget build(BuildContext context) {
    final theme = context.appTheme;
    final isHighlighted = _isSpecial || _isSelected;

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top section: special indicator and actions button
            if (isHighlighted)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _buildSpecialIndicator(context)),
                  if (log != null) _buildActionsButton(context, theme),
                ],
              ),
            // Middle section: transition text and actions button
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      transition.transitionText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight:
                            _isSpecial ? FontWeight.w600 : FontWeight.w500,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (log != null && !isHighlighted)
                    _buildActionsButton(context, theme),
                ],
              ),
            ),
            // Bottom section: timestamp
            Text(
              _timestampFormat.format(transition.timestamp),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsButton(BuildContext context, ThemeData theme) =>
      SquareIconButton(
        icon: Icons.more_horiz_rounded,
        color: theme.colorScheme.primary,
        onPressed: () {
          ISpectNavigationFlowActionsSheet(
            items: items,
            transition: transition,
            log: log,
          ).show(context);
        },
      );

  Widget _buildSpecialIndicator(BuildContext context) {
    final colorScheme = context.appTheme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_headerIcon(), style: const TextStyle(fontSize: 10)),
          const Gap(4),
          Flexible(
            child: Text(
              _headerText(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.appTheme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _headerIcon() {
    if (index == 0) return '📍';
    if (index == totalItems - 1) return '🏁';
    return '🔄';
  }

  String _headerText(BuildContext context) {
    if (index == 0) return context.ispectL10n.current;
    if (index == totalItems - 1) return context.ispectL10n.start;
    return context.ispectL10n.selectedTransition;
  }
}
