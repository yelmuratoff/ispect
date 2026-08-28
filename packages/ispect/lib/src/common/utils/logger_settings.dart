import 'package:ispect/ispect.dart';

/// Filters this helper installed, so re-enabling every log type clears only
/// ISpect's own veto and leaves a host-configured filter in place.
final Expando<ISpectFilter> _installedFilters = Expando<ISpectFilter>(
  'ispect.settingsFilter',
);

/// Applies the logger-owned half of [settings] to [logger].
///
/// Disabled log types become a filter veto, so keys the settings sheet never
/// listed — custom and adapter-registered ones — keep capturing.
void applySettingsToLogger(ISpectLogger logger, ISpectSettingsState settings) {
  logger.configure(
    options: logger.options.copyWith(
      enabled: settings.enabled,
      useConsoleLogs: settings.useConsoleLogs,
      useHistory: settings.useHistory,
      forwardErrorToConsole: settings.forwardErrorToConsole,
      maxHistoryItems: settings.maxHistoryItems,
      logTruncateLength: settings.logTruncateLength,
      captureMode: settings.captureMode,
      resourceLimits: settings.resourceLimits,
      processingPolicy: settings.processingPolicy,
    ),
  );

  if (settings.disabledLogTypes.isEmpty) {
    if (_installedFilters[logger] != null) {
      _installedFilters[logger] = null;
      logger.clearFilter();
    }
    return;
  }

  final filter = ISpectFilter(
    excludedLogTypeKeys: settings.disabledLogTypes,
    resourceLimits: settings.resourceLimits,
  );
  _installedFilters[logger] = filter;
  logger.configure(filter: filter);
}
