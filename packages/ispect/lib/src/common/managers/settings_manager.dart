import 'package:ispect/ispect.dart';

/// Handles ISpect settings state and updates.
class SettingsManager {
  SettingsManager({
    ISpectSettingsState? initialSettings,
    void Function()? onChanged,
  })  : _settings = initialSettings ??
            const ISpectSettingsState(
              enabled: true,
              useConsoleLogs: true,
              useHistory: true,
            ),
        _onChanged = onChanged;

  ISpectSettingsState _settings;
  final void Function()? _onChanged;

  ISpectSettingsState get settings => _settings;

  void updateSettings(ISpectSettingsState newSettings) {
    if (_settings == newSettings) return;
    _settings = newSettings;
    final cb = _onChanged;
    if (cb != null) cb();
  }
}
