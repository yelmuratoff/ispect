import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/common/widgets/ispect_bordered_surface.dart';

class ActionTile extends StatelessWidget {
  const ActionTile({required this.action, super.key});

  final ISpectActionItem action;

  @override
  Widget build(BuildContext context) {
    final tile = ISpectBorderedSurface(
      onTap: () {
        Navigator.pop(context);
        action.onTap?.call(context);
      },
      semanticsLabel: action.title,
      child: Row(
        children: [
          Icon(action.icon, size: 14, color: context.ispectPrimaryColor),
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
    );

    if (action.description case final description?) {
      return Tooltip(message: description, child: tile);
    }
    return tile;
  }
}
