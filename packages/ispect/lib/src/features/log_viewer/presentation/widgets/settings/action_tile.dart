import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({required this.action, super.key});

  final ISpectActionItem action;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;

    Widget chip = Material(
      color: cardColor,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          action.onTap?.call(context);
        },
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: context.appTheme.colorScheme.onSurface
                  .withValues(alpha: 0.08),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  action.icon,
                  size: 14,
                  color: primaryColor,
                ),
                const Gap(6),
                Expanded(
                  child: Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.appTheme.textTheme.labelMedium?.copyWith(
                      color: context.appTheme.textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (action.description case final description?) {
      chip = Tooltip(
        message: description,
        child: chip,
      );
    }

    return chip;
  }
}
