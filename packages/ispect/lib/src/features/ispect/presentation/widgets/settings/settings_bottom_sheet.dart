// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member, implementation_imports

import 'package:flutter/material.dart';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/log_type_filter_section.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/settings_card.dart';

class ISpectSettingsBottomSheet {
  const ISpectSettingsBottomSheet({
    required this.logger,
    required this.options,
    required this.actions,
    required this.controller,
  });

  /// ISpectLogger implementation
  final ValueNotifier<ISpectLogger> logger;

  /// Options for `ISpect`
  final ISpectOptions options;

  /// Actions to display in the settings bottom sheet
  final List<ISpectActionItem> actions;

  /// Controller for the ISpect view
  final ISpectViewController controller;

  Future<void> show(BuildContext context) => showISpectSheet(
        context,
        initialChildSize: 0.8,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        dialogHeightFactor: 0.7,
        dialogWidth: MediaQuery.sizeOf(context).width * 0.8,
        topOnlyRadius: true,
        routeSettings: const RouteSettings(name: 'ISpect Logs Settings Sheet'),
        useRootNavigator: false,
        builder: (context, scrollController) => _SettingsContent(
          logger: logger,
          options: options,
          actions: actions,
          controller: controller,
          externalScrollController: scrollController,
        ),
      );
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent({
    required this.logger,
    required this.options,
    required this.actions,
    required this.controller,
    this.externalScrollController,
  });

  final ValueNotifier<ISpectLogger> logger;
  final ISpectOptions options;
  final List<ISpectActionItem> actions;
  final ISpectViewController controller;
  final ScrollController? externalScrollController;

  @override
  State<_SettingsContent> createState() => _SettingsContentState();
}

class _SettingsContentState extends State<_SettingsContent> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.externalScrollController ?? ScrollController();
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
    if (widget.externalScrollController == null) {
      _scrollController.dispose();
    }
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
    final currentSettings = widget.controller.settings;

    return Scrollbar(
      thumbVisibility: true,
      controller: _scrollController,
      interactive: true,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Drag handle
          const SliverToBoxAdapter(
            child: ISpectDragHandle(),
          ),
          // Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ISpectBottomSheetHeader(
                title: 'ISpect',
                subtitle: context.ispectL10n.settings,
                icon: Icons.tune_rounded,
              ),
            ),
          ),
          // General section — horizontal toggle cards
          SliverToBoxAdapter(
            child: ISpectSectionLabel(title: context.ispectL10n.settings),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IntrinsicHeight(
                child: Row(
                  spacing: 8,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ISpectSettingsCardItem(
                      title: context.ispectL10n.enabled,
                      enabled: currentSettings.enabled,
                      icon: Icons.power_settings_new_rounded,
                      onChanged: (enabled) {
                        _onSettingChanged(
                          currentSettings.copyWith(enabled: enabled),
                        );
                      },
                    ),
                    ISpectSettingsCardItem(
                      canEdit: currentSettings.enabled,
                      title: context.ispectL10n.useConsoleLogs,
                      icon: Icons.terminal_rounded,
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
                      icon: Icons.history_rounded,
                      enabled: currentSettings.useHistory,
                      onChanged: (enabled) {
                        _onSettingChanged(
                          currentSettings.copyWith(useHistory: enabled),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Actions section — grid of action buttons
          if (widget.actions.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: ISpectSectionLabel(
                title: context.ispectL10n.actions,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.actions
                      .map((action) => _ActionTile(action: action))
                      .toList(),
                ),
              ),
            ),
          ],
          // Log type filter section
          SliverToBoxAdapter(
            child: LogTypeFilterSection(
              disabledLogTypes: currentSettings.disabledLogTypes,
              onLogTypeToggled: _onLogTypeToggled,
              onSelectAll: _onSelectAll,
              onDeselectAll: _onDeselectAll,
            ),
          ),
          const SliverToBoxAdapter(
            child: Gap(32),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action});

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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  action.icon,
                  size: 15,
                  color: primaryColor,
                ),
                const Gap(6),
                Text(
                  action.title,
                  style: context.appTheme.textTheme.labelMedium?.copyWith(
                    color: context.appTheme.textColor,
                    fontWeight: FontWeight.w500,
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
