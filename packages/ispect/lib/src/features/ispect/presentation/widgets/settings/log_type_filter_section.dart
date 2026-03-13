import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/ispect/domain/models/log_description.dart';

/// A widget that displays a grid of log type chips
/// to enable/disable specific log types for filtering.
class LogTypeFilterSection extends StatelessWidget {
  const LogTypeFilterSection({
    required this.disabledLogTypes,
    required this.onLogTypeToggled,
    required this.onSelectAll,
    required this.onDeselectAll,
    super.key,
  });

  /// Set of disabled log type keys. If empty, all log types are enabled.
  final Set<String> disabledLogTypes;

  /// Callback when a log type is toggled.
  final void Function(String logTypeKey, {required bool enabled})
      onLogTypeToggled;

  /// Callback to select all log types.
  final VoidCallback onSelectAll;

  /// Callback to deselect all log types.
  final VoidCallback onDeselectAll;

  /// Returns true if all log types are enabled (no disabled types).
  bool get _isAllEnabled => disabledLogTypes.isEmpty;

  @override
  Widget build(BuildContext context) {
    final logDescriptions = ISpectConstants.defaultLogDescriptions(context);

    // Group by category
    final groups = _groupLogTypes(logDescriptions);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.ispectL10n.iSpectifyLogsInfo.toUpperCase(),
                  style: context.appTheme.textTheme.labelSmall?.copyWith(
                    color:
                        context.appTheme.textColor.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                GestureDetector(
                  onTap: _isAllEnabled ? onDeselectAll : onSelectAll,
                  child: Text(
                    _isAllEnabled ? 'Deselect All' : 'Select All',
                    style: context.appTheme.textTheme.labelSmall?.copyWith(
                      color: context.ispectTheme.primary?.resolve(context) ??
                          context.appTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...groups.entries.map(
            (entry) => _LogTypeGroup(
              title: entry.key,
              logTypes: entry.value,
              disabledLogTypes: disabledLogTypes,
              onLogTypeToggled: onLogTypeToggled,
            ),
          ),
          const Gap(12),
        ],
      ),
    );
  }

  Map<String, List<LogDescription>> _groupLogTypes(
    List<LogDescription> descriptions,
  ) {
    final groups = <String, List<LogDescription>>{};
    for (final desc in descriptions) {
      final key = desc.key;
      String group;
      if (key.startsWith('http-')) {
        group = 'HTTP';
      } else if (key.startsWith('bloc-')) {
        group = 'Bloc';
      } else if (key.startsWith('riverpod-')) {
        group = 'Riverpod';
      } else if (key.startsWith('ws-')) {
        group = 'WebSocket';
      } else if (key.startsWith('db-')) {
        group = 'Database';
      } else if (key == 'route') {
        group = 'Navigation';
      } else {
        group = 'General';
      }
      (groups[group] ??= []).add(desc);
    }
    return groups;
  }
}

class _LogTypeGroup extends StatelessWidget {
  const _LogTypeGroup({
    required this.title,
    required this.logTypes,
    required this.disabledLogTypes,
    required this.onLogTypeToggled,
  });

  final String title;
  final List<LogDescription> logTypes;
  final Set<String> disabledLogTypes;
  final void Function(String logTypeKey, {required bool enabled})
      onLogTypeToggled;

  @override
  Widget build(BuildContext context) {
    final cardColor = context.ispectTheme.card?.resolve(context) ??
        context.appTheme.cardColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.appTheme.textTheme.labelMedium?.copyWith(
                  color: context.appTheme.textColor.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Gap(8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: logTypes.map((logType) {
                  final isEnabled =
                      !disabledLogTypes.contains(logType.key);
                  return _LogTypeChip(
                    logType: logType,
                    isEnabled: isEnabled,
                    onToggled: () => onLogTypeToggled(
                      logType.key,
                      enabled: !isEnabled,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogTypeChip extends StatelessWidget {
  const _LogTypeChip({
    required this.logType,
    required this.isEnabled,
    required this.onToggled,
  });

  final LogDescription logType;
  final bool isEnabled;
  final VoidCallback onToggled;

  @override
  Widget build(BuildContext context) {
    final typeColor = context.iSpect.theme
        .getTypeColor(context, key: logType.key);
    final typeIcon = context.iSpect.theme
        .getTypeIcon(context, key: logType.key);
    final description = context.iSpect.theme
        .getTypeDescription(context, key: logType.key);
    final effectiveColor = isEnabled
        ? typeColor
        : context.appTheme.textColor.withValues(alpha: 0.25);

    Widget chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggled,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isEnabled
                ? effectiveColor?.withValues(alpha: 0.12)
                : context.appTheme.colorScheme.onSurface
                    .withValues(alpha: 0.04),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(
              color: isEnabled
                  ? effectiveColor?.withValues(alpha: 0.3) ??
                      Colors.transparent
                  : context.appTheme.colorScheme.onSurface
                      .withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                typeIcon,
                size: 14,
                color: effectiveColor,
              ),
              const SizedBox(width: 4),
              Text(
                logType.key,
                style: TextStyle(
                  color: effectiveColor,
                  fontSize: 12,
                  fontWeight: isEnabled ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (description != null) {
      chip = Tooltip(
        message: description,
        child: chip,
      );
    }

    return chip;
  }
}
