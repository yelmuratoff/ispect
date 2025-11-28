// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, implementation_imports

import 'package:flutter/material.dart';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/screen_size.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/log_type_filter_section.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_card.dart';

class ISpectSettingsBottomSheet extends StatefulWidget {
  const ISpectSettingsBottomSheet({
    required this.logger,
    required this.options,
    required this.actions,
    required this.controller,
    super.key,
  });

  /// ISpectLogger implementation
  final ValueNotifier<ISpectLogger> logger;

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
      _ISpectLoggerSettingsBottomSheetState();
}

class _ISpectLoggerSettingsBottomSheetState
    extends State<ISpectSettingsBottomSheet> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.logger.addListener(_handleUpdate);
    widget.controller.addListener(_handleUpdate);

    // Initialize settings in controller if not already set from options
    // Use addPostFrameCallback to avoid notifying listeners during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final initialSettings = widget.options.initialSettings;
      if (initialSettings != null &&
          widget.controller.settings != initialSettings) {
        widget.controller.updateSettings(initialSettings);
        _applySettingsToLogger(initialSettings);
      } else {
        // Ensure controller has current logger state
        final currentSettings = ISpectSettingsState(
          enabled: widget.logger.value.options.enabled,
          useConsoleLogs: widget.logger.value.options.useConsoleLogs,
          useHistory: widget.logger.value.options.useHistory,
          disabledLogTypes: widget.controller.settings.disabledLogTypes,
        );
        if (widget.controller.settings != currentSettings) {
          widget.controller.updateSettings(currentSettings);
        }
      }
    });
  }

  void _handleUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.logger.removeListener(_handleUpdate);
    widget.controller.removeListener(_handleUpdate);
    _scrollController.dispose();
    super.dispose();
  }

  /// Applies settings to the logger instance.
  void _applySettingsToLogger(ISpectSettingsState settings) {
    // Convert disabled types to enabled types for filter
    final enabledTypes = settings.disabledLogTypes.isEmpty
        ? <String>[] // Empty = no filter (all enabled)
        : ISpectLogType.values
            .map((e) => e.key)
            .where((key) => !settings.disabledLogTypes.contains(key))
            .toList();

    widget.logger.value.configure(
      options: widget.logger.value.options.copyWith(
        enabled: settings.enabled,
        useConsoleLogs: settings.useConsoleLogs,
        useHistory: settings.useHistory,
      ),
      filter: enabledTypes.isNotEmpty
          ? ISpectFilter(logTypeKeys: enabledTypes)
          : null,
    );
    widget.logger.notifyListeners();
  }

  void _onSettingChanged(ISpectSettingsState newSettings) {
    // Update controller state
    widget.controller.updateSettings(newSettings);

    // Apply to logger
    _applySettingsToLogger(newSettings);

    // Notify callback
    widget.options.onSettingsChanged?.call(newSettings);
  }

  void _onLogTypeToggled(String logTypeKey, {required bool enabled}) {
    final currentSettings = widget.controller.settings;
    final currentDisabledTypes = currentSettings.disabledLogTypes;
    Set<String> newDisabledTypes;

    if (enabled) {
      // User enabled this type, so remove from disabled set
      newDisabledTypes = {...currentDisabledTypes}..remove(logTypeKey);
    } else {
      // User disabled this type, so add to disabled set
      newDisabledTypes = {...currentDisabledTypes, logTypeKey};
    }

    _onSettingChanged(
      currentSettings.copyWith(disabledLogTypes: newDisabledTypes),
    );
  }

  void _onSelectAll() {
    // Enable all = clear disabled set
    _onSettingChanged(
      widget.controller.settings.copyWith(disabledLogTypes: <String>{}),
    );
  }

  void _onDeselectAll() {
    // Disable all = add all types to disabled set
    final allLogTypes = ISpectLogType.values.map((e) => e.key).toSet();
    _onSettingChanged(
      widget.controller.settings.copyWith(disabledLogTypes: allLogTypes),
    );
  }

  @override
  Widget build(BuildContext context) {
    final iSpect = ISpect.read(context);
    final currentSettings = widget.controller.settings;

    final settings = <Widget>[
      ISpectSettingsCardItem(
        title: context.ispectL10n.enabled,
        enabled: currentSettings.enabled,
        backgroundColor: context.ispectTheme.card?.resolve(context) ??
            context.appTheme.cardColor,
        onChanged: (enabled) {
          _onSettingChanged(currentSettings.copyWith(enabled: enabled));
        },
      ),
      ISpectSettingsCardItem(
        canEdit: currentSettings.enabled,
        title: context.ispectL10n.useConsoleLogs,
        backgroundColor: context.ispectTheme.card?.resolve(context) ??
            context.appTheme.cardColor,
        enabled: currentSettings.useConsoleLogs,
        onChanged: (enabled) {
          _onSettingChanged(
            currentSettings.copyWith(useConsoleLogs: enabled),
          );
        },
      ),
      ISpectSettingsCardItem(
        canEdit: currentSettings.enabled,
        title: context.ispectL10n.useHistory,
        backgroundColor: context.ispectTheme.card?.resolve(context) ??
            context.appTheme.cardColor,
        enabled: currentSettings.useHistory,
        onChanged: (enabled) {
          _onSettingChanged(currentSettings.copyWith(useHistory: enabled));
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
          disabledLogTypes: currentSettings.disabledLogTypes,
          onLogTypeToggled: _onLogTypeToggled,
          onSelectAll: _onSelectAll,
          onDeselectAll: _onDeselectAll,
        ),
      ),
      orElse: () => AlertDialog(
        contentPadding: EdgeInsets.zero,
        backgroundColor: iSpect.theme.background?.resolve(context),
        content: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          width: MediaQuery.sizeOf(context).width * 0.8,
          child: _SettingsBody(
            iSpect: iSpect,
            settings: settings,
            scrollController: _scrollController,
            actions: widget.actions,
            disabledLogTypes: currentSettings.disabledLogTypes,
            onLogTypeToggled: _onLogTypeToggled,
            onSelectAll: _onSelectAll,
            onDeselectAll: _onDeselectAll,
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
    required this.disabledLogTypes,
    required this.onLogTypeToggled,
    required this.onSelectAll,
    required this.onDeselectAll,
  });

  final ISpectScopeModel iSpect;
  final List<Widget> settings;
  final ScrollController scrollController;
  final List<ISpectActionItem> actions;
  final Set<String> disabledLogTypes;
  final void Function(String logTypeKey, {required bool enabled})
      onLogTypeToggled;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: iSpect.theme.background?.resolve(context) ??
              context.appTheme.scaffoldBackgroundColor,
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
                      color: context.ispectTheme.card?.resolve(context) ??
                          context.appTheme.cardColor,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(16),
                      ),
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: iSpect.theme.divider?.resolve(context) ??
                              context.appTheme.dividerColor,
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
                              color: iSpect.theme.divider?.resolve(
                                    context,
                                  ) ??
                                  context.appTheme.dividerColor,
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
                      color: context.ispectTheme.card?.resolve(context) ??
                          context.appTheme.cardColor,
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      border: Border.fromBorderSide(
                        BorderSide(
                          color: iSpect.theme.divider?.resolve(context) ??
                              context.appTheme.dividerColor,
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
              SliverToBoxAdapter(
                child: LogTypeFilterSection(
                  disabledLogTypes: disabledLogTypes,
                  onLogTypeToggled: onLogTypeToggled,
                  onSelectAll: onSelectAll,
                  onDeselectAll: onDeselectAll,
                ),
              ),
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 32, top: 16),
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
                style: context.appTheme.textTheme.titleLarge?.copyWith(
                  color: context.ispectTheme.primary?.resolve(context),
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
    final theme = context.appTheme;

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
              style: context.appTheme.textTheme.bodyMedium,
            ),
            leading: Icon(action.icon, color: context.appTheme.textColor),
          ),
        ),
        if (showDivider)
          Divider(
            color: iSpect.theme.divider?.resolve(context) ??
                context.appTheme.dividerColor,
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
