import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/core/res/constants/ispect_constants.dart';
import 'package:ispect/src/features/ispect/presentation/widgets/base_card.dart';

/// A widget that displays a list of log types with toggle switches
/// to enable/disable specific log types for filtering.
class LogTypeFilterSection extends StatelessWidget {
  const LogTypeFilterSection({
    required this.enabledLogTypes,
    required this.onLogTypeToggled,
    super.key,
  });

  /// Set of currently enabled log type keys.
  /// If empty, all log types are enabled.
  final Set<String> enabledLogTypes;

  /// Callback when a log type is toggled.
  final void Function(String logTypeKey, {required bool enabled})
      onLogTypeToggled;

  /// Returns true if all log types are enabled.
  bool get _isAllEnabled => enabledLogTypes.isEmpty;

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
                onPressed: _isAllEnabled ? _selectAll : _deselectAll,
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
    final isEnabled = _isAllEnabled || enabledLogTypes.contains(logType.key);

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
                  Container(
                    width: 6,
                    height: 24,
                    decoration: BoxDecoration(
                      color: context.iSpect.theme
                          .getTypeColor(context, key: logType.key),
                      borderRadius: const BorderRadius.all(
                        Radius.circular(ISpectConstants.standardBorderRadius),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    logType.key,
                    style: TextStyle(
                      color: context.ispectTheme.textColor,
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

  void _selectAll() {
    // Enable all log types by clearing the set
    for (final logType in ISpectLogType.values) {
      onLogTypeToggled(logType.key, enabled: true);
    }
  }

  void _deselectAll() {
    // Disable all log types
    for (final logType in ISpectLogType.values) {
      onLogTypeToggled(logType.key, enabled: false);
    }
  }
}
