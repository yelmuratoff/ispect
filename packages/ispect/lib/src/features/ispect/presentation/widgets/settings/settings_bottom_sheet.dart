// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, implementation_imports

import 'package:flutter/material.dart';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/builder/column_builder.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_card.dart';

class ISpectifySettingsBottomSheets extends StatefulWidget {
  const ISpectifySettingsBottomSheets({
    required this.iSpectify,
    required this.options,
    required this.actions,
    super.key,
  });

  /// ISpectify implementation
  final ValueNotifier<ISpectify> iSpectify;

  /// Options for `ISpect`
  final ISpectOptions options;

  final List<ISpectifyActionItem> actions;

  @override
  State<ISpectifySettingsBottomSheets> createState() =>
      _ISpectifySettingsBottomSheetState();
}

class _ISpectifySettingsBottomSheetState
    extends State<ISpectifySettingsBottomSheets> {
  @override
  void initState() {
    super.initState();
    // ignore: avoid_empty_blocks
    widget.iSpectify.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final settings = <Widget>[
      ISpectifySettingsCardItem(
        title: context.ispectL10n.enabled,
        enabled: widget.iSpectify.value.settings.enabled,
        backgroundColor: context.ispectTheme.cardColor,
        onChanged: (enabled) {
          (enabled
                  ? widget.iSpectify.value.enable
                  : widget.iSpectify.value.disable)
              .call();
          widget.iSpectify.notifyListeners();
        },
      ),
      ISpectifySettingsCardItem(
        canEdit: widget.iSpectify.value.settings.enabled,
        title: context.ispectL10n.useConsoleLogs,
        backgroundColor: context.ispectTheme.cardColor,
        enabled: widget.iSpectify.value.settings.useConsoleLogs,
        onChanged: (enabled) {
          widget.iSpectify.value.configure(
            settings: widget.iSpectify.value.settings.copyWith(
              useConsoleLogs: enabled,
            ),
          );
          widget.iSpectify.notifyListeners();
        },
      ),
      ISpectifySettingsCardItem(
        canEdit: widget.iSpectify.value.settings.enabled,
        title: context.ispectL10n.useHistory,
        backgroundColor: context.ispectTheme.cardColor,
        enabled: widget.iSpectify.value.settings.useHistory,
        onChanged: (enabled) {
          widget.iSpectify.value.configure(
            settings: widget.iSpectify.value.settings.copyWith(
              useHistory: enabled,
            ),
          );
          widget.iSpectify.notifyListeners();
        },
      ),
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.ispectTheme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              sliver: SliverToBoxAdapter(
                child: _Header(title: context.ispectL10n.settings),
              ),
            ),
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
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.only(bottom: 32),
                child: _HowToReachMeWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HowToReachMeWidget extends StatelessWidget {
  const _HowToReachMeWidget();

  @override
  Widget build(BuildContext context) => Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Flexible(
            child: Text.rich(
              TextSpan(
                text: 'ISpect',
                style: context.ispectTheme.textTheme.titleLarge?.copyWith(
                  color: context.ispectTheme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: '\n📫 How to reach me: \n',
                    children: [
                      TextSpan(
                        text: 'yelamanyelmuratov@gmail.com',
                        style:
                            context.ispectTheme.textTheme.bodyMedium?.copyWith(
                          color: context.ispectTheme.colorScheme.primary,
                        ),
                      ),
                    ],
                    style: context.ispectTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = context.ispectTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style:
              theme.textTheme.headlineSmall?.copyWith(color: theme.textColor),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close_rounded, color: theme.textColor),
        ),
      ],
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    this.showDivider = true,
  });

  final ISpectifyActionItem action;
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
