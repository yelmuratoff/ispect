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
  Widget build(BuildContext context) => ActionRow(
    icon: action.icon,
    title: action.title,
    description: action.description,
    descriptionMaxLines: 2,
    onTap: () {
      Navigator.pop(context);
      action.onTap?.call(context);
    },
  );
}

class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.description,
    this.descriptionMaxLines,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? description;
  final int? descriptionMaxLines;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = context.appTheme.textColor;
    final description = this.description;

    return Semantics(
      button: true,
      child: ISpectBorderedSurface(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            ISpectIconBadge(icon: icon, size: ISpectIconBadgeSize.small),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
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
                      maxLines: descriptionMaxLines,
                      overflow: descriptionMaxLines == null
                          ? null
                          : TextOverflow.ellipsis,
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
