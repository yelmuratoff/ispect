import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/base_card.dart';

/// A widget that displays a list of log types with toggle switches
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
    final iSpect = ISpect.read(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.ispectL10n.iSpectifyLogsInfo,
                style: context.ispectTheme.textTheme.titleMedium?.copyWith(
                  color: context.ispectTheme.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: _isAllEnabled ? onDeselectAll : onSelectAll,
                child: Text(
                  _isAllEnabled ? 'Deselect All' : 'Select All',
                  style: TextStyle(
                    color: context.ispectTheme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...ISpectConstants.defaultLogDescriptions(context).map(
          (entry) => _buildLogTypeItem(
            context,
            iSpect,
            entry,
          ),
        ),
      ],
    );
  }

  Widget _buildLogTypeItem(
    BuildContext context,
    ISpectScopeModel iSpect,
    LogDescription logType,
  ) {
    // Type is enabled if NOT in disabled set
    final isEnabled = !disabledLogTypes.contains(logType.key);

    return Column(
      children: [
        ISpectBaseCard(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          color: iSpect.theme.dividerColor(context) ??
              context.ispectTheme.dividerColor,
          backgroundColor: context.ispectTheme.cardColor,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              visualDensity: VisualDensity.compact,
              title: Row(
                spacing: 4,
                children: [
                  SizedBox.square(
                    dimension: 24,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.iSpect.theme
                            .getTypeColor(context, key: logType.key)
                            ?.withValues(alpha: 0.2),
                        borderRadius: const BorderRadius.all(
                          Radius.circular(ISpectConstants.standardBorderRadius),
                        ),
                      ),
                      child: Icon(
                        context.iSpect.theme
                            .getTypeIcon(context, key: logType.key),
                        size: 16,
                        color: context.iSpect.theme
                            .getTypeColor(context, key: logType.key),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    logType.key,
                    style: TextStyle(
                      color: context.iSpect.theme
                          .getTypeColor(context, key: logType.key),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (logType.description != null) ...[
                    const SizedBox(width: 4),
                    Tooltip(
                      message: logType.description,
                      child: const Icon(
                        Icons.info_outline,
                        size: 14,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: Switch(
                value: isEnabled,
                onChanged: (value) =>
                    onLogTypeToggled(logType.key, enabled: value),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
