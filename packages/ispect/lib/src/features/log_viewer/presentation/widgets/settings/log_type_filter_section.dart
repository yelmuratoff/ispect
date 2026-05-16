import 'package:flutter/material.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/log_viewer/domain/models/log_description.dart';
import 'package:ispectify/ispectify.dart';

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
    final theme = context.ispectTheme;
    final builtInDescriptions = ISpectConstants.defaultLogDescriptions(context);

    // Merge custom types from theme — convert ISpectLogType → LogDescription
    final customDescriptions = theme.customLogTypes.map(
      (t) => LogDescription(key: t.key, title: t.title),
    );
    final logDescriptions = [...builtInDescriptions, ...customDescriptions];

    // Group by category
    final groups = _groupLogTypes(context, logDescriptions);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.ispectL10n.iSpectifyLogsInfo.toUpperCase(),
                  style: context.appTheme.textTheme.labelSmall?.copyWith(
                    color: context.appTheme.textColor.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                Semantics(
                  button: true,
                  label: _isAllEnabled
                      ? context.ispectL10n.deselectAll
                      : context.ispectL10n.selectAll,
                  onTap: _isAllEnabled ? onDeselectAll : onSelectAll,
                  child: GestureDetector(
                    excludeFromSemantics: true,
                    onTap: _isAllEnabled ? onDeselectAll : onSelectAll,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      child: Text(
                        _isAllEnabled
                            ? context.ispectL10n.deselectAll
                            : context.ispectL10n.selectAll,
                        style: context.appTheme.textTheme.labelSmall?.copyWith(
                          color: context.appTheme.textColor
                              .withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        ),
                      ),
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
    BuildContext context,
    List<LogDescription> descriptions,
  ) {
    final logCategories = context.ispectTheme.logCategories;
    final categoryLabels = context.ispectTheme.categoryLabels;
    final groups = <String, List<LogDescription>>{};
    for (final desc in descriptions) {
      final categoryId = _resolveCategory(desc.key, logCategories);
      final label = _categoryLabel(context, categoryId, categoryLabels);
      (groups[label] ??= []).add(desc);
    }
    return groups;
  }

  /// Resolves category ID from log key.
  /// Priority: theme.logCategories > ISpectLogType.category > prefix heuristic.
  static String _resolveCategory(
    String key,
    Map<String, String> logCategories,
  ) {
    // Theme override
    final themeCategory = logCategories[key];
    if (themeCategory != null) return themeCategory;
    // Enum lookup
    final logType = ISpectLogType.fromKey(key);
    if (logType != null) return logType.category;
    // Prefix heuristic for custom keys
    for (final id in TraceCategoryIds.builtIn) {
      if (key.startsWith('$id-')) return id;
    }
    return TraceCategoryIds.general;
  }

  /// Human-readable label for category ID.
  /// Theme's categoryLabels override defaults.
  static String _categoryLabel(
    BuildContext context,
    String categoryId,
    Map<String, String> categoryLabels,
  ) {
    // Theme override
    final themeLabel = categoryLabels[categoryId];
    if (themeLabel != null) return themeLabel;
    // Built-in labels
    final l10n = context.ispectL10n;
    return switch (categoryId) {
      TraceCategoryIds.network => l10n.groupHttp,
      TraceCategoryIds.state => l10n.groupBloc,
      TraceCategoryIds.ws => l10n.groupWebSocket,
      TraceCategoryIds.db => l10n.groupDatabase,
      TraceCategoryIds.navigation => l10n.groupNavigation,
      TraceCategoryIds.auth => l10n.categoryAuth,
      TraceCategoryIds.storage => l10n.categoryStorage,
      TraceCategoryIds.push => l10n.categoryPush,
      TraceCategoryIds.payment => l10n.categoryPayment,
      TraceCategoryIds.analytics => l10n.categoryAnalytics,
      TraceCategoryIds.sse => l10n.categorySse,
      TraceCategoryIds.grpc => l10n.categoryGrpc,
      TraceCategoryIds.graphql => l10n.categoryGraphql,
      _ => l10n.groupGeneral,
    };
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
    final cardColor = context.ispectRowCardColor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
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
              const Gap(4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: logTypes.map((logType) {
                  final isEnabled = !disabledLogTypes.contains(logType.key);
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
    final typeColor =
        context.iSpect.theme.getTypeColor(context, key: logType.key);
    final typeIcon =
        context.iSpect.theme.getTypeIcon(context, key: logType.key);
    final description =
        context.iSpect.theme.getTypeDescription(context, key: logType.key);
    final effectiveColor = isEnabled
        ? typeColor
        : context.appTheme.textColor.withValues(alpha: 0.25);

    Widget chip = Semantics(
      toggled: isEnabled,
      label: logType.displayTitle,
      onTap: onToggled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          excludeFromSemantics: true,
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
                  logType.displayTitle,
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
