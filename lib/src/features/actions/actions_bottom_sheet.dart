import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/widget/base_bottom_sheet.dart';
import 'package:talker_flutter/talker_flutter.dart';

class TalkerActionsBottomSheet extends StatelessWidget {
  const TalkerActionsBottomSheet({
    required this.talkerScreenTheme,
    required this.actions,
    super.key,
  });

  final TalkerScreenTheme talkerScreenTheme;
  final List<TalkerActionItem> actions;

  @override
  Widget build(BuildContext context) => BaseBottomSheet(
        title: context.ispectL10n.actions,
        talkerScreenTheme: talkerScreenTheme,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16).copyWith(bottom: 16, top: 8),
          decoration: BoxDecoration(
            color: talkerScreenTheme.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.ispectTheme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...actions.asMap().entries.map(
                    (e) => _ActionTile(
                      talkerScreenTheme: talkerScreenTheme,
                      action: e.value,
                      showDivider: e.key != actions.length - 1,
                    ),
                  ),
            ],
          ),
        ),
      );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.talkerScreenTheme,
    this.showDivider = true,
  });

  final TalkerActionItem action;
  final TalkerScreenTheme talkerScreenTheme;
  final bool showDivider;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: ListTile(
              onTap: () => _onTap(context),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              dense: true,
              title: Text(
                action.title,
                style: context.ispectTheme.textTheme.bodyLarge,
              ),
              leading: Icon(action.icon, color: talkerScreenTheme.textColor),
            ),
          ),
          if (showDivider)
            Divider(
              color: context.ispectTheme.dividerColor,
              height: 1,
            ),
        ],
      );

  void _onTap(BuildContext context) {
    Navigator.pop(context);
    action.onTap();
  }
}

class TalkerActionItem {
  const TalkerActionItem({
    required this.onTap,
    required this.title,
    required this.icon,
  });

  final VoidCallback onTap;
  final String title;
  final IconData icon;
}
