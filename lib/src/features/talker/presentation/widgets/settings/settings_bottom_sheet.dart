// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, implementation_imports

import 'package:flutter/material.dart';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/builder/column_builder.dart';
import 'package:ispect/src/common/widgets/widget/base_bottom_sheet.dart';
import 'package:ispect/src/features/talker/presentation/widgets/settings/settings_card.dart';

import 'package:talker_flutter/talker_flutter.dart';

class TalkerSettingsBottomSheets extends StatefulWidget {
  const TalkerSettingsBottomSheets({
    required this.talker,
    required this.options,
    required this.actions,
    super.key,
  });

  /// Talker implementation
  final ValueNotifier<Talker> talker;

  /// Options for `ISpect`
  final ISpectOptions options;

  final List<TalkerActionItem> actions;

  @override
  State<TalkerSettingsBottomSheets> createState() =>
      _TalkerSettingsBottomSheetState();
}

class _TalkerSettingsBottomSheetState
    extends State<TalkerSettingsBottomSheets> {
  @override
  void initState() {
    super.initState();
    // ignore: avoid_empty_blocks
    widget.talker.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final settings = <Widget>[
      TalkerSettingsCardItem(
        title: context.ispectL10n.enabled,
        enabled: widget.talker.value.settings.enabled,
        backgroundColor: context.ispectTheme.cardColor,
        onChanged: (enabled) {
          (enabled ? widget.talker.value.enable : widget.talker.value.disable)
              .call();
          widget.talker.notifyListeners();
        },
      ),
      TalkerSettingsCardItem(
        canEdit: widget.talker.value.settings.enabled,
        title: context.ispectL10n.useConsoleLogs,
        backgroundColor: context.ispectTheme.cardColor,
        enabled: widget.talker.value.settings.useConsoleLogs,
        onChanged: (enabled) {
          widget.talker.value.configure(
            settings: widget.talker.value.settings.copyWith(
              useConsoleLogs: enabled,
            ),
          );
          widget.talker.notifyListeners();
        },
      ),
      TalkerSettingsCardItem(
        canEdit: widget.talker.value.settings.enabled,
        title: context.ispectL10n.useHistory,
        backgroundColor: context.ispectTheme.cardColor,
        enabled: widget.talker.value.settings.useHistory,
        onChanged: (enabled) {
          widget.talker.value.configure(
            settings: widget.talker.value.settings.copyWith(
              useHistory: enabled,
            ),
          );
          widget.talker.notifyListeners();
        },
      ),
    ];

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.87,
      ),
      child: BaseBottomSheet(
        title: context.ispectL10n.settings,
        child: Expanded(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(bottom: 16, top: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.ispectTheme.cardColor,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: iSpect.theme.dividerColor(context) ??
                              context.ispectTheme.dividerColor,
                        ),
                      ),
                    ),
                    child: ColumnBuilder(
                      itemCount: settings.length,
                      itemBuilder: (_, index) => Column(
                        children: [
                          settings[index],
                          if (index != settings.length - 1)
                            Divider(
                              color: iSpect.theme.dividerColor(
                                    context,
                                  ) ??
                                  context.ispectTheme.dividerColor,
                              height: 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16)
                      .copyWith(bottom: 16),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.ispectTheme.cardColor,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: iSpect.theme.dividerColor(context) ??
                              context.ispectTheme.dividerColor,
                        ),
                      ),
                    ),
                    child: ColumnBuilder(
                      itemCount: widget.actions.length,
                      itemBuilder: (_, index) {
                        final action = widget.actions[index];
                        return _ActionTile(
                          action: action,
                          showDivider: index != widget.actions.length - 1,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
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
              style: context.ispectTheme.textTheme.bodyMedium,
            ),
            leading: Icon(action.icon, color: context.ispectTheme.textColor),
          ),
        ),
        if (showDivider)
          Divider(
            color: iSpect.theme.dividerColor(context) ??
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
