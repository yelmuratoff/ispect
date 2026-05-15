import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/action_tile.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/compact_toggle_grid.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/limit_tile.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/log_type_filter_section.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/toggle_spec.dart';

class ISpectSettingsBottomSheet {
  const ISpectSettingsBottomSheet({
    required this.logger,
    required this.options,
    required this.actions,
    required this.controller,
  });

  /// ISpectLogger implementation
  final ISpectLoggerNotifier logger;

  /// Options for `ISpect`
  final ISpectOptions options;

  /// Actions to display in the settings bottom sheet
  final List<ISpectActionItem> actions;

  /// Controller for the ISpect view
  final ISpectViewController controller;

  Future<void> show(BuildContext context) => showISpectSheet(
        context,
        fitContent: false,
        initialChildSize: 0.8,
        minChildSize: 0.3,
        maxChildSize: 0.9,
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

  final ISpectLoggerNotifier logger;
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

    // Defer to a post-frame callback so updates don't fire listeners during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final initialSettings = widget.options.initialSettings;
      if (initialSettings != null &&
          widget.controller.settings != initialSettings) {
        widget.controller.updateSettings(initialSettings);
        _applySettingsToLogger(initialSettings);
      } else {
        final loggerOptions = widget.logger.value.options;
        final existing = widget.controller.settings;
        final currentSettings = existing.copyWith(
          enabled: loggerOptions.enabled,
          useConsoleLogs: loggerOptions.useConsoleLogs,
          useHistory: loggerOptions.useHistory,
          forwardErrorToConsole: loggerOptions.forwardErrorToConsole,
          maxHistoryItems: loggerOptions.maxHistoryItems,
          logTruncateLength: loggerOptions.logTruncateLength,
        );
        if (existing != currentSettings) {
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

  void _applySettingsToLogger(ISpectSettingsState settings) {
    final enabledTypes = settings.disabledLogTypes.isEmpty
        ? <String>[]
        : ISpectLogType.builtIn
            .map((e) => e.key)
            .where((key) => !settings.disabledLogTypes.contains(key))
            .toList();

    widget.logger.value.configure(
      options: widget.logger.value.options.copyWith(
        enabled: settings.enabled,
        useConsoleLogs: settings.useConsoleLogs,
        useHistory: settings.useHistory,
        forwardErrorToConsole: settings.forwardErrorToConsole,
        maxHistoryItems: settings.maxHistoryItems,
        logTruncateLength: settings.logTruncateLength,
      ),
      filter: enabledTypes.isNotEmpty
          ? ISpectFilter(logTypeKeys: enabledTypes)
          : null,
    );
    widget.logger.notify();
  }

  void _onSettingChanged(ISpectSettingsState newSettings) {
    widget.controller.updateSettings(newSettings);
    _applySettingsToLogger(newSettings);
  }

  void _onLogTypeToggled(String logTypeKey, {required bool enabled}) {
    final currentSettings = widget.controller.settings;
    final currentDisabledTypes = currentSettings.disabledLogTypes;
    final newDisabledTypes = enabled
        ? ({...currentDisabledTypes}..remove(logTypeKey))
        : {...currentDisabledTypes, logTypeKey};

    _onSettingChanged(
      currentSettings.copyWith(disabledLogTypes: newDisabledTypes),
    );
  }

  void _onSelectAll() {
    _onSettingChanged(
      widget.controller.settings.copyWith(disabledLogTypes: <String>{}),
    );
  }

  void _onDeselectAll() {
    final allLogTypes = ISpectLogType.builtIn.map((e) => e.key).toSet();
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
          const SliverToBoxAdapter(
            child: ISpectDragHandle(),
          ),
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
          SliverToBoxAdapter(
            child: ISpectSectionLabel(title: context.ispectL10n.settings),
          ),
          SliverToBoxAdapter(
            child: CompactToggleGrid(
              tiles: [
                ToggleSpec(
                  title: context.ispectL10n.enabled,
                  icon: Icons.power_settings_new_rounded,
                  enabled: currentSettings.enabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(enabled: v),
                  ),
                ),
                ToggleSpec(
                  title: context.ispectL10n.useConsoleLogs,
                  icon: Icons.terminal_rounded,
                  enabled: currentSettings.useConsoleLogs,
                  canEdit: currentSettings.enabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(useConsoleLogs: v),
                  ),
                ),
                ToggleSpec(
                  title: context.ispectL10n.useHistory,
                  icon: Icons.history_rounded,
                  enabled: currentSettings.useHistory,
                  canEdit: currentSettings.enabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(useHistory: v),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: ISpectSectionLabel(title: 'Display'),
          ),
          SliverToBoxAdapter(
            child: CompactToggleGrid(
              tiles: [
                ToggleSpec(
                  title: 'Expand logs',
                  icon: Icons.unfold_more_rounded,
                  enabled: currentSettings.expandedLogs,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(expandedLogs: v),
                  ),
                ),
                ToggleSpec(
                  title: 'Newest first',
                  icon: Icons.swap_vert_rounded,
                  enabled: currentSettings.isLogOrderReversed,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isLogOrderReversed: v),
                  ),
                ),
                ToggleSpec(
                  title: 'Group HTTP',
                  icon: Icons.merge_type_rounded,
                  enabled: currentSettings.groupHttpLogs,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(groupHttpLogs: v),
                  ),
                ),
                ToggleSpec(
                  title: 'Relative time',
                  icon: Icons.schedule_rounded,
                  enabled: currentSettings.useRelativeTime,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(useRelativeTime: v),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: ISpectSectionLabel(title: 'Tools'),
          ),
          SliverToBoxAdapter(
            child: CompactToggleGrid(
              tiles: [
                ToggleSpec(
                  title: 'Log viewer',
                  icon: Icons.reorder_rounded,
                  enabled: currentSettings.isLogPageEnabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isLogPageEnabled: v),
                  ),
                ),
                ToggleSpec(
                  title: 'Performance',
                  icon: Icons.monitor_heart_outlined,
                  enabled: currentSettings.isPerformanceEnabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isPerformanceEnabled: v),
                  ),
                ),
                ToggleSpec(
                  title: 'Inspector',
                  icon: Icons.format_shapes_rounded,
                  enabled: currentSettings.isInspectorEnabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isInspectorEnabled: v),
                  ),
                ),
                ToggleSpec(
                  title: 'Color picker',
                  icon: Icons.colorize_rounded,
                  enabled: currentSettings.isColorPickerEnabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isColorPickerEnabled: v),
                  ),
                ),
              ],
            ),
          ),
          const SliverToBoxAdapter(
            child: ISpectSectionLabel(title: 'Advanced'),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  CompactToggleRow(
                    spec: ToggleSpec(
                      title: 'Forward errors to dart:developer',
                      icon: Icons.bug_report_rounded,
                      enabled: currentSettings.forwardErrorToConsole,
                      canEdit: currentSettings.enabled &&
                          currentSettings.useConsoleLogs,
                      onChanged: (v) => _onSettingChanged(
                        currentSettings.copyWith(forwardErrorToConsole: v),
                      ),
                    ),
                  ),
                  const Gap(8),
                  LimitTile(
                    label: 'History capacity',
                    description: 'Logs kept in memory',
                    icon: Icons.history_toggle_off_rounded,
                    value: currentSettings.maxHistoryItems,
                    options: const [1000, 5000, 10000, 25000, 50000],
                    formatter: formatCount,
                    onChanged: (v) => _onSettingChanged(
                      currentSettings.copyWith(maxHistoryItems: v),
                    ),
                  ),
                  const Gap(8),
                  LimitTile(
                    label: 'Console truncate',
                    description: 'Max chars per console line',
                    icon: Icons.short_text_rounded,
                    value: currentSettings.logTruncateLength,
                    options: const [256, 1000, 4000, 10000, 40000],
                    formatter: formatCount,
                    onChanged: (v) => _onSettingChanged(
                      currentSettings.copyWith(logTruncateLength: v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.actions.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: ISpectSectionLabel(
                title: context.ispectL10n.actions,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 8.0;
                    final tileWidth = (constraints.maxWidth - spacing) / 2;
                    return Wrap(
                      spacing: spacing,
                      runSpacing: spacing,
                      children: widget.actions
                          .map(
                            (action) => SizedBox(
                              width: tileWidth,
                              child: ActionTile(action: action),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
            ),
          ],
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
