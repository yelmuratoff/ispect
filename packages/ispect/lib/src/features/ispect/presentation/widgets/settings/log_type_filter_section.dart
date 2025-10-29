import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
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

    // Group log types by category for better UX
    final groupedLogTypes = _groupLogTypes();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Log Type Filters',
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
        ...groupedLogTypes.entries.map(
          (entry) => _buildCategorySection(
            context,
            iSpect,
            entry.key,
            entry.value,
          ),
        ),
      ],
    );
  }

  /// Groups log types by category for better organization.
  Map<String, List<ISpectLogType>> _groupLogTypes() => {
        'General': [
          ISpectLogType.debug,
          ISpectLogType.info,
          ISpectLogType.warning,
          ISpectLogType.error,
          ISpectLogType.critical,
          ISpectLogType.exception,
          ISpectLogType.verbose,
          ISpectLogType.good,
          ISpectLogType.print,
        ],
        'HTTP': [
          ISpectLogType.httpRequest,
          ISpectLogType.httpResponse,
          ISpectLogType.httpError,
        ],
        'BLoC': [
          ISpectLogType.blocEvent,
          ISpectLogType.blocTransition,
          ISpectLogType.blocState,
          ISpectLogType.blocCreate,
          ISpectLogType.blocClose,
          ISpectLogType.blocDone,
          ISpectLogType.blocError,
        ],
        'Riverpod': [
          ISpectLogType.riverpodAdd,
          ISpectLogType.riverpodUpdate,
          ISpectLogType.riverpodDispose,
          ISpectLogType.riverpodFail,
        ],
        'Database': [
          ISpectLogType.dbQuery,
          ISpectLogType.dbResult,
          ISpectLogType.dbError,
        ],
        'Other': [
          ISpectLogType.route,
          ISpectLogType.analytics,
          ISpectLogType.provider,
        ],
      };

  Widget _buildCategorySection(
    BuildContext context,
    ISpectScopeModel iSpect,
    String category,
    List<ISpectLogType> logTypes,
  ) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.ispectTheme.cardColor,
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.fromBorderSide(
              BorderSide(
                color: iSpect.theme.dividerColor(context) ??
                    context.ispectTheme.dividerColor,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12).copyWith(bottom: 8),
                child: Text(
                  category,
                  style: context.ispectTheme.textTheme.labelLarge?.copyWith(
                    color: context.ispectTheme.textColor.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...logTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final logType = entry.value;
                final isLast = index == logTypes.length - 1;

                return _buildLogTypeItem(
                  context,
                  iSpect,
                  logType,
                  !isLast,
                );
              }),
            ],
          ),
        ),
      );

  Widget _buildLogTypeItem(
    BuildContext context,
    ISpectScopeModel iSpect,
    ISpectLogType logType,
    bool showDivider,
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
              leading: Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: context.iSpect.theme
                      .getTypeColor(context, key: logType.key),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              title: Text(
                _formatLogTypeName(logType.key),
                style: TextStyle(
                  color: context.ispectTheme.textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Switch(
                value: isEnabled,
                onChanged: (value) =>
                    onLogTypeToggled(logType.key, enabled: value),
              ),
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Divider(
              color: iSpect.theme.dividerColor(context) ??
                  context.ispectTheme.dividerColor,
              height: 1,
            ),
          ),
      ],
    );
  }

  /// Formats log type key for display.
  String _formatLogTypeName(String key) => key
      .split('-')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

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
