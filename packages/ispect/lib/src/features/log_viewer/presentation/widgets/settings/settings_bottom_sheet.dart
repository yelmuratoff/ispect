import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/utils/logger_settings.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/log_viewer/controllers/ispect_view_controller.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/action_tile.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/compact_toggle_grid.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/limit_tile.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/log_type_filter_section.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/policy_profile_tile.dart';
import 'package:ispect/src/features/log_viewer/presentation/widgets/settings/toggle_spec.dart';

class ISpectSettingsBottomSheet {
  const ISpectSettingsBottomSheet({
    required this.logger,
    required this.actions,
    required this.controller,
  });

  /// ISpectLogger implementation
  final ISpectLoggerNotifier logger;

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
      actions: actions,
      controller: controller,
      externalScrollController: scrollController,
    ),
  );
}

class _SettingsContent extends StatefulWidget {
  const _SettingsContent({
    required this.logger,
    required this.actions,
    required this.controller,
    this.externalScrollController,
  });

  final ISpectLoggerNotifier logger;
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

      final loggerOptions = widget.logger.value.options;
      final existing = widget.controller.settings;
      final currentSettings = existing.copyWith(
        enabled: loggerOptions.enabled,
        useConsoleLogs: loggerOptions.useConsoleLogs,
        useHistory: loggerOptions.useHistory,
        forwardErrorToConsole: loggerOptions.forwardErrorToConsole,
        maxHistoryItems: loggerOptions.maxHistoryItems,
        logTruncateLength: loggerOptions.logTruncateLength,
        captureMode: loggerOptions.captureMode,
        resourceLimits: loggerOptions.resourceLimits,
        processingPolicy: loggerOptions.processingPolicy,
      );
      if (existing != currentSettings) {
        widget.controller.updateSettings(currentSettings);
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
    applySettingsToLogger(widget.logger.value, settings);
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

  void _onDeselectAll(Set<String> logTypeKeys) {
    _onSettingChanged(
      widget.controller.settings.copyWith(disabledLogTypes: logTypeKeys),
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
          const SliverToBoxAdapter(child: ISpectDragHandle()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ISpectBottomSheetHeader(
                title: 'ISpect',
                subtitle: context.ispectL10n.settings,
                icon: Icons.settings_outlined,
              ),
            ),
          ),
          _GeneralSection(
            settings: currentSettings,
            onChanged: _onSettingChanged,
          ),
          _DisplaySection(
            settings: currentSettings,
            onChanged: _onSettingChanged,
          ),
          _ToolsSection(
            settings: currentSettings,
            onChanged: _onSettingChanged,
          ),
          _AdvancedSection(
            settings: currentSettings,
            onChanged: _onSettingChanged,
          ),
          if (widget.actions.isNotEmpty)
            _ActionsSection(actions: widget.actions),
          SliverToBoxAdapter(
            child: LogTypeFilterSection(
              disabledLogTypes: currentSettings.disabledLogTypes,
              onLogTypeToggled: _onLogTypeToggled,
              onSelectAll: _onSelectAll,
              onDeselectAll: _onDeselectAll,
            ),
          ),
          const SliverToBoxAdapter(child: Gap(32)),
        ],
      ),
    );
  }
}

class _GeneralSection extends StatelessWidget {
  const _GeneralSection({required this.settings, required this.onChanged});

  final ISpectSettingsState settings;
  final ValueChanged<ISpectSettingsState> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: ISpectSectionLabel(title: l10n.settings)),
        SliverToBoxAdapter(
          child: CompactToggleGrid(
            tiles: [
              ToggleSpec(
                title: l10n.enabled,
                icon: Icons.power_settings_new_rounded,
                enabled: settings.enabled,
                onChanged: (v) => onChanged(settings.copyWith(enabled: v)),
              ),
              ToggleSpec(
                title: l10n.useConsoleLogs,
                icon: Icons.terminal_rounded,
                enabled: settings.useConsoleLogs,
                canEdit: settings.enabled,
                onChanged: (v) =>
                    onChanged(settings.copyWith(useConsoleLogs: v)),
              ),
              ToggleSpec(
                title: l10n.useHistory,
                icon: Icons.history_rounded,
                enabled: settings.useHistory,
                canEdit: settings.enabled,
                onChanged: (v) => onChanged(settings.copyWith(useHistory: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DisplaySection extends StatelessWidget {
  const _DisplaySection({required this.settings, required this.onChanged});

  final ISpectSettingsState settings;
  final ValueChanged<ISpectSettingsState> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: ISpectSectionLabel(title: l10n.settingsDisplay),
        ),
        SliverToBoxAdapter(
          child: CompactToggleGrid(
            tiles: [
              ToggleSpec(
                title: l10n.expandLogs,
                icon: Icons.unfold_more_rounded,
                enabled: settings.expandedLogs,
                onChanged: (v) => onChanged(settings.copyWith(expandedLogs: v)),
              ),
              ToggleSpec(
                title: l10n.reverseLogs,
                icon: Icons.swap_vert_rounded,
                enabled: settings.isLogOrderReversed,
                onChanged: (v) =>
                    onChanged(settings.copyWith(isLogOrderReversed: v)),
              ),
              ToggleSpec(
                title: l10n.groupHttpLogs,
                icon: Icons.merge_type_rounded,
                enabled: settings.groupHttpLogs,
                onChanged: (v) =>
                    onChanged(settings.copyWith(groupHttpLogs: v)),
              ),
              ToggleSpec(
                title: l10n.relativeTime,
                icon: Icons.schedule_rounded,
                enabled: settings.useRelativeTime,
                onChanged: (v) =>
                    onChanged(settings.copyWith(useRelativeTime: v)),
              ),
              ToggleSpec(
                title: l10n.compactUrls,
                icon: Icons.link_off_rounded,
                enabled: settings.compactNetworkUrls,
                onChanged: (v) =>
                    onChanged(settings.copyWith(compactNetworkUrls: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ToolsSection extends StatelessWidget {
  const _ToolsSection({required this.settings, required this.onChanged});

  final ISpectSettingsState settings;
  final ValueChanged<ISpectSettingsState> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: ISpectSectionLabel(title: l10n.settingsTools),
        ),
        SliverToBoxAdapter(
          child: CompactToggleGrid(
            tiles: [
              ToggleSpec(
                title: l10n.logViewer,
                icon: Icons.reorder_rounded,
                enabled: settings.isLogPageEnabled,
                onChanged: (v) =>
                    onChanged(settings.copyWith(isLogPageEnabled: v)),
              ),
              ToggleSpec(
                title: l10n.performance,
                icon: Icons.monitor_heart_outlined,
                enabled: settings.isPerformanceEnabled,
                onChanged: (v) =>
                    onChanged(settings.copyWith(isPerformanceEnabled: v)),
              ),
              ToggleSpec(
                title: l10n.inspector,
                icon: Icons.format_shapes_rounded,
                enabled: settings.isInspectorEnabled,
                onChanged: (v) =>
                    onChanged(settings.copyWith(isInspectorEnabled: v)),
              ),
              ToggleSpec(
                title: l10n.colorPicker,
                icon: Icons.colorize_rounded,
                enabled: settings.isColorPickerEnabled,
                onChanged: (v) =>
                    onChanged(settings.copyWith(isColorPickerEnabled: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AdvancedSection extends StatelessWidget {
  const _AdvancedSection({required this.settings, required this.onChanged});

  final ISpectSettingsState settings;
  final ValueChanged<ISpectSettingsState> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.ispectL10n;
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: ISpectSectionLabel(title: l10n.settingsAdvanced),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                CompactToggleRow(
                  spec: ToggleSpec(
                    title: l10n.forwardErrorsToDeveloperLog,
                    icon: Icons.bug_report_rounded,
                    enabled: settings.forwardErrorToConsole,
                    canEdit: settings.enabled && settings.useConsoleLogs,
                    onChanged: (v) =>
                        onChanged(settings.copyWith(forwardErrorToConsole: v)),
                  ),
                ),
                const Gap(8),
                LimitTile(
                  label: l10n.historyCapacity,
                  description: l10n.historyCapacityDesc,
                  icon: Icons.history_toggle_off_rounded,
                  value: settings.maxHistoryItems,
                  options: const [1000, 5000, 10000, 25000, 50000],
                  formatter: formatCount,
                  onChanged: (v) =>
                      onChanged(settings.copyWith(maxHistoryItems: v)),
                ),
                const Gap(8),
                LimitTile(
                  label: l10n.consoleTruncate,
                  description: l10n.consoleTruncateDesc,
                  icon: Icons.short_text_rounded,
                  value: settings.logTruncateLength,
                  options: const [256, 1000, 4000, 10000, 40000],
                  formatter: formatCount,
                  onChanged: (v) =>
                      onChanged(settings.copyWith(logTruncateLength: v)),
                ),
                const Gap(8),
                PolicyProfileTile<DiagnosticCaptureMode>(
                  label: l10n.captureMode,
                  description: l10n.captureModeDesc,
                  icon: Icons.shield_outlined,
                  value: settings.captureMode,
                  options: [
                    PolicyProfileOption(
                      label: l10n.profileBalanced,
                      description: l10n.captureModeBalancedDesc,
                      value: DiagnosticCaptureMode.balanced,
                    ),
                    PolicyProfileOption(
                      label: l10n.captureModeStrict,
                      description: l10n.captureModeStrictDesc,
                      value: DiagnosticCaptureMode.strict,
                    ),
                  ],
                  onChanged: (value) =>
                      onChanged(settings.copyWith(captureMode: value)),
                ),
                const Gap(8),
                PolicyProfileTile<DiagnosticResourceLimits>(
                  label: l10n.resourceProfile,
                  description: l10n.resourceProfileDesc,
                  icon: Icons.memory_rounded,
                  value: settings.resourceLimits,
                  options: [
                    PolicyProfileOption(
                      label: l10n.resourceProfileConstrained,
                      description: l10n.resourceProfileConstrainedDesc,
                      value: DiagnosticResourceLimits.constrained,
                    ),
                    PolicyProfileOption(
                      label: l10n.profileBalanced,
                      description: l10n.resourceProfileBalancedDesc,
                      value: DiagnosticResourceLimits.balanced,
                    ),
                    PolicyProfileOption(
                      label: l10n.resourceProfileExtended,
                      description: l10n.resourceProfileExtendedDesc,
                      value: DiagnosticResourceLimits.extended,
                    ),
                  ],
                  onChanged: (value) =>
                      onChanged(settings.copyWith(resourceLimits: value)),
                ),
                const Gap(8),
                PolicyProfileTile<DiagnosticProcessingPolicy>(
                  label: l10n.processingProfile,
                  description: l10n.processingProfileDesc,
                  icon: Icons.speed_rounded,
                  value: settings.processingPolicy,
                  options: [
                    PolicyProfileOption(
                      label: l10n.processingProfileResponsive,
                      description: l10n.processingProfileResponsiveDesc,
                      value: DiagnosticProcessingPolicy.responsive,
                    ),
                    PolicyProfileOption(
                      label: l10n.profileBalanced,
                      description: l10n.processingProfileBalancedDesc,
                      value: DiagnosticProcessingPolicy.balanced,
                    ),
                    PolicyProfileOption(
                      label: l10n.processingProfileThroughput,
                      description: l10n.processingProfileThroughputDesc,
                      value: DiagnosticProcessingPolicy.throughput,
                    ),
                  ],
                  onChanged: (value) =>
                      onChanged(settings.copyWith(processingPolicy: value)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionsSection extends StatelessWidget {
  const _ActionsSection({required this.actions});

  final List<ISpectActionItem> actions;

  @override
  Widget build(BuildContext context) => SliverMainAxisGroup(
    slivers: [
      SliverToBoxAdapter(
        child: ISpectSectionLabel(title: context.ispectL10n.actions),
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
                children: actions
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
  );
}
