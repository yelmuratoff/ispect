import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/widget/base_bottom_sheet.dart';

class TalkerActionsBottomSheet extends StatelessWidget {
  const TalkerActionsBottomSheet({
    required this.actions,
    super.key,
  });

  final List<TalkerActionItem> actions;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return BaseBottomSheet(
      title: context.ispectL10n.actions,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16)
              .copyWith(bottom: 16, top: 8),
          decoration: BoxDecoration(
            color: iSpect.theme.cardColor(isDark: context.isDarkMode) ??
                context.ispectTheme.cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(16)),
            border: Border.fromBorderSide(
              BorderSide(
                color: iSpect.theme.dividerColor(isDark: context.isDarkMode) ??
                    context.ispectTheme.dividerColor,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...actions.asMap().entries.map(
                      (e) => _ActionTile(
                        action: e.value,
                        showDivider: e.key != actions.length - 1,
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

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    this.showDivider = true,
  });

  final TalkerActionItem action;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: ListTile(
            onTap: () => _onTap(context),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
            dense: true,
            title: Text(
              action.title,
              style: context.ispectTheme.textTheme.bodyLarge,
            ),
            leading: Icon(action.icon, color: context.ispectTheme.textColor),
          ),
        ),
        if (showDivider)
          Divider(
            color: iSpect.theme.dividerColor(isDark: context.isDarkMode) ??
                context.ispectTheme.dividerColor,
            height: 1,
          ),
      ],
    );
  }

  void _onTap(BuildContext context) {
    Navigator.pop(context);
    action.onTap?.call(context);
  }
}
