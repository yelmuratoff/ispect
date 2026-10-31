import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_bordered_surface.dart';
import 'package:ispect/src/common/widgets/ispect_icon_badge.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({required this.action, super.key});

  final ISpectActionItem action;

  @override
  Widget build(BuildContext context) {
    final textColor = context.appTheme.textColor;
    final description = action.description;

    return Semantics(
      button: true,
      child: ISpectBorderedSurface(
        onTap: () {
          Navigator.pop(context);
          action.onTap?.call(context);
        },
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ISpectIconBadge(icon: action.icon, size: ISpectIconBadgeSize.small),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTheme.textTheme.labelLarge?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.appTheme.textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: 0.55),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
