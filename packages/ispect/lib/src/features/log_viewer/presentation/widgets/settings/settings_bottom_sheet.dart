import 'package:flutter/material.dart';

import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/controllers/ispect_view_controller.dart';
import 'package:ispect/src/common/controllers/logger_notifier.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/adaptive_sheet.dart';
import 'package:ispect/src/common/widgets/bottom_sheet_header.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/settings/log_type_filter_section.dart';

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
            child: _CompactToggleGrid(
              tiles: [
                _ToggleSpec(
                  title: context.ispectL10n.enabled,
                  icon: Icons.power_settings_new_rounded,
                  enabled: currentSettings.enabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(enabled: v),
                  ),
                ),
                _ToggleSpec(
                  title: context.ispectL10n.useConsoleLogs,
                  icon: Icons.terminal_rounded,
                  enabled: currentSettings.useConsoleLogs,
                  canEdit: currentSettings.enabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(useConsoleLogs: v),
                  ),
                ),
                _ToggleSpec(
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
            child: _CompactToggleGrid(
              tiles: [
                _ToggleSpec(
                  title: 'Expand logs',
                  icon: Icons.unfold_more_rounded,
                  enabled: currentSettings.expandedLogs,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(expandedLogs: v),
                  ),
                ),
                _ToggleSpec(
                  title: 'Newest first',
                  icon: Icons.swap_vert_rounded,
                  enabled: currentSettings.isLogOrderReversed,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isLogOrderReversed: v),
                  ),
                ),
                _ToggleSpec(
                  title: 'Group HTTP',
                  icon: Icons.merge_type_rounded,
                  enabled: currentSettings.groupHttpLogs,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(groupHttpLogs: v),
                  ),
                ),
                _ToggleSpec(
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
            child: _CompactToggleGrid(
              tiles: [
                _ToggleSpec(
                  title: 'Log viewer',
                  icon: Icons.reorder_rounded,
                  enabled: currentSettings.isLogPageEnabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isLogPageEnabled: v),
                  ),
                ),
                _ToggleSpec(
                  title: 'Performance',
                  icon: Icons.monitor_heart_outlined,
                  enabled: currentSettings.isPerformanceEnabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isPerformanceEnabled: v),
                  ),
                ),
                _ToggleSpec(
                  title: 'Inspector',
                  icon: Icons.format_shapes_rounded,
                  enabled: currentSettings.isInspectorEnabled,
                  onChanged: (v) => _onSettingChanged(
                    currentSettings.copyWith(isInspectorEnabled: v),
                  ),
                ),
                _ToggleSpec(
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
                  _CompactToggleRow(
                    spec: _ToggleSpec(
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
                  _LimitTile(
                    label: 'History capacity',
                    description: 'Logs kept in memory',
                    icon: Icons.history_toggle_off_rounded,
                    value: currentSettings.maxHistoryItems,
                    options: const [1000, 5000, 10000, 25000, 50000],
                    formatter: _formatCount,
                    onChanged: (v) => _onSettingChanged(
                      currentSettings.copyWith(maxHistoryItems: v),
                    ),
                  ),
                  const Gap(8),
                  _LimitTile(
                    label: 'Console truncate',
                    description: 'Max chars per console line',
                    icon: Icons.short_text_rounded,
                    value: currentSettings.logTruncateLength,
                    options: const [256, 1000, 4000, 10000, 40000],
                    formatter: _formatCount,
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
                              child: _ActionTile(action: action),
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

String _formatCount(int value) {
  if (value >= 1000 && value % 1000 == 0) return '${value ~/ 1000}k';
  return value.toString();
}

class _ToggleSpec {
  const _ToggleSpec({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.onChanged,
    this.canEdit = true,
  });

  final String title;
  final IconData icon;
  final bool enabled;
  final bool canEdit;
  final ValueChanged<bool> onChanged;
}

class _CompactToggleGrid extends StatelessWidget {
  const _CompactToggleGrid({required this.tiles});

  final List<_ToggleSpec> tiles;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_ToggleSpec>>[];
    for (var i = 0; i < tiles.length; i += 2) {
      rows.add(tiles.sublist(i, (i + 2).clamp(0, tiles.length)));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) const Gap(6),
            Row(
              children: [
                Expanded(child: _CompactToggleRow(spec: row[0])),
                const Gap(6),
                Expanded(
                  child: row.length > 1
                      ? _CompactToggleRow(spec: row[1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CompactToggleRow extends StatelessWidget {
  const _CompactToggleRow({required this.spec});

  final _ToggleSpec spec;

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final textColor = context.appTheme.textColor;
    final outlineColor =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.08);

    final disabled = !spec.canEdit;
    final enabled = spec.enabled;

    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Semantics(
        toggled: enabled,
        label: '${spec.title} ${enabled ? "enabled" : "disabled"}',
        onTap: disabled ? null : () => spec.onChanged(!enabled),
        child: Material(
          color: enabled ? primaryColor.withValues(alpha: 0.1) : cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          child: InkWell(
            excludeFromSemantics: true,
            onTap: disabled ? null : () => spec.onChanged(!enabled),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: enabled
                      ? primaryColor.withValues(alpha: 0.45)
                      : outlineColor,
                  width: enabled ? 1.2 : 1,
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      spec.icon,
                      size: 16,
                      color: enabled
                          ? primaryColor
                          : textColor.withValues(alpha: 0.55),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        spec.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.appTheme.textTheme.labelMedium?.copyWith(
                          color: enabled
                              ? primaryColor
                              : textColor.withValues(alpha: 0.7),
                          fontWeight:
                              enabled ? FontWeight.w600 : FontWeight.w500,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const Gap(8),
                    _CompactSwitch(
                      enabled: enabled,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactSwitch extends StatelessWidget {
  const _CompactSwitch({required this.enabled, required this.primaryColor});

  final bool enabled;
  final Color primaryColor;

  static const double _trackWidth = 24;
  static const double _trackHeight = 13;
  static const double _thumbSize = 9;
  static const double _thumbPadding = 2;

  @override
  Widget build(BuildContext context) {
    final trackOff =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.18);
    final thumbOff =
        context.appTheme.colorScheme.onSurface.withValues(alpha: 0.55);

    return ExcludeSemantics(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeInOut,
        width: _trackWidth,
        height: _trackHeight,
        decoration: BoxDecoration(
          color: enabled ? primaryColor : trackOff,
          borderRadius: const BorderRadius.all(Radius.circular(_trackHeight)),
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeInOut,
              top: _thumbPadding,
              left: enabled
                  ? _trackWidth - _thumbSize - _thumbPadding
                  : _thumbPadding,
              child: Container(
                width: _thumbSize,
                height: _thumbSize,
                decoration: BoxDecoration(
                  color: enabled ? Colors.white : thumbOff,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LimitTile extends StatelessWidget {
  const _LimitTile({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.options,
    required this.formatter,
    required this.onChanged,
  });

  final String label;
  final String description;
  final IconData icon;
  final int value;
  final List<int> options;
  final String Function(int value) formatter;
  final ValueChanged<int> onChanged;

  Future<void> _openEditor(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _LimitEditorDialog(
        label: label,
        description: description,
        icon: icon,
        value: value,
        presets: options,
        formatter: formatter,
      ),
    );
    if (result != null && result != value) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;
    final textColor = context.appTheme.textColor;

    return Material(
      color: cardColor,
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      child: InkWell(
        onTap: () => _openEditor(context),
        borderRadius: const BorderRadius.all(Radius.circular(10)),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: context.appTheme.colorScheme.onSurface.withValues(
                alpha: 0.08,
              ),
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: primaryColor),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: context.appTheme.textTheme.labelLarge?.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        description,
                        style: context.appTheme.textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatter(value),
                        style: context.appTheme.textTheme.labelMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: primaryColor,
                      ),
                    ],
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

class _LimitEditorDialog extends StatefulWidget {
  const _LimitEditorDialog({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.presets,
    required this.formatter,
  });

  final String label;
  final String description;
  final IconData icon;
  final int value;
  final List<int> presets;
  final String Function(int value) formatter;

  @override
  State<_LimitEditorDialog> createState() => _LimitEditorDialogState();
}

class _LimitEditorDialogState extends State<_LimitEditorDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.value.toString());
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _selectPreset(int preset) {
    _controller.text = preset.toString();
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    setState(() => _error = null);
  }

  void _submit() {
    final raw = _controller.text.trim();
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 0) {
      setState(() => _error = 'Enter a non-negative integer');
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.ispectTheme.primary?.resolve(context) ??
        context.appTheme.colorScheme.primary;

    return AlertDialog(
      icon: Icon(widget.icon, color: primaryColor),
      title: Text(widget.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.description,
            style: context.appTheme.textTheme.bodySmall?.copyWith(
              color: context.appTheme.textColor.withValues(alpha: 0.65),
            ),
          ),
          const Gap(12),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Value',
              hintText: '0 disables this limit',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const Gap(12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final preset in widget.presets)
                ActionChip(
                  label: Text(widget.formatter(preset)),
                  onPressed: () => _selectPreset(preset),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Apply'),
        ),
      ],
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Icon(
                  action.icon,
                  size: 14,
                  color: primaryColor,
                ),
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
