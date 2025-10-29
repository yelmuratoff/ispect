// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, implementation_imports

import 'package:flutter/material.dart';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_card.dart';

class ISpectSettingsBottomSheet extends StatefulWidget {
  const ISpectSettingsBottomSheet({
    required this.iSpectify,
    required this.options,
    required this.actions,
    required this.controller,
    super.key,
  });

  /// ISpectify implementation
  final ValueNotifier<ISpectify> iSpectify;

  /// Options for `ISpect`
  final ISpectOptions options;

  /// Actions to display in the settings bottom sheet
  final List<ISpectActionItem> actions;

  /// Controller for the ISpect view
  final ISpectViewController controller;

  Future<void> show(BuildContext context) async {
    await context.screenSizeMaybeWhen(
      phone: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        routeSettings: const RouteSettings(name: 'ISpect Logs Settings Sheet'),
        builder: (_) => this,
      ),
      orElse: () => showDialog<void>(
        context: context,
        useRootNavigator: false,
        routeSettings: const RouteSettings(name: 'ISpect Logs Settings Dialog'),
        builder: (_) => this,
      ),
    );
  }

  @override
  State<ISpectSettingsBottomSheet> createState() =>
      _ISpectifySettingsBottomSheetState();
}

class _ISpectifySettingsBottomSheetState
    extends State<ISpectSettingsBottomSheet> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.iSpectify.addListener(_handleUpdate);
  }

  void _handleUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.iSpectify.removeListener(_handleUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final settings = <Widget>[
      ISpectSettingsCardItem(
        title: context.ispectL10n.enabled,
        enabled: widget.iSpectify.value.options.enabled,
        backgroundColor: context.ispectTheme.cardColor,
        onChanged: (enabled) {
          (enabled
                  ? widget.iSpectify.value.enable
                  : widget.iSpectify.value.disable)
              .call();
          widget.iSpectify.notifyListeners();
        },
      ),
      ISpectSettingsCardItem(
        canEdit: widget.iSpectify.value.options.enabled,
        title: context.ispectL10n.useConsoleLogs,
        backgroundColor: context.ispectTheme.cardColor,
        enabled: widget.iSpectify.value.options.useConsoleLogs,
        onChanged: (enabled) {
          widget.iSpectify.value.configure(
            options: widget.iSpectify.value.options.copyWith(
              useConsoleLogs: enabled,
            ),
          );
          widget.iSpectify.notifyListeners();
        },
      ),
      ISpectSettingsCardItem(
        canEdit: widget.iSpectify.value.options.enabled,
        title: context.ispectL10n.useHistory,
        backgroundColor: context.ispectTheme.cardColor,
        enabled: widget.iSpectify.value.options.useHistory,
        onChanged: (enabled) {
          widget.iSpectify.value.configure(
            options: widget.iSpectify.value.options.copyWith(
              useHistory: enabled,
            ),
          );
          widget.iSpectify.notifyListeners();
        },
      ),
    ];

    return context.screenSizeMaybeWhen(
      phone: () => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => _SettingsBody(
          iSpect: iSpect,
          settings: settings,
          scrollController: scrollController,
          actions: widget.actions,
        ),
      ),
      orElse: () => AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: context.ispectTheme.scaffoldBackgroundColor,
        content: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          width: MediaQuery.sizeOf(context).width * 0.8,
          child: _SettingsBody(
            iSpect: iSpect,
            settings: settings,
            scrollController: _scrollController,
            actions: widget.actions,
          ),
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody({
    required this.iSpect,
    required this.settings,
    required this.scrollController,
    required this.actions,
  });

  final ISpectScopeModel iSpect;
  final List<Widget> settings;
  final ScrollController scrollController;
  final List<ISpectActionItem> actions;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.ispectTheme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Scrollbar(
          thumbVisibility: true,
          controller: scrollController,
          interactive: true,
          child: CustomScrollView(
            controller: scrollController,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
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
                      borderRadius: const BorderRadius.all(
                        Radius.circular(16),
                      ),
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: iSpect.theme.dividerColor(context) ??
                              context.ispectTheme.dividerColor,
                        ),
                      ),
                    ),
                    child: ISpectColumnBuilder(
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
                    child: ISpectColumnBuilder(
                      itemCount: actions.length,
                      itemBuilder: (_, index) {
                        final action = actions[index];
                        return _ActionTile(
                          action: action,
                          showDivider: index != actions.length - 1,
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

  final ISpectActionItem action;
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
