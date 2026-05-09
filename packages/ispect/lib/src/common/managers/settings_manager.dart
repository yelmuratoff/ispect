import 'package:ispect/ispect.dart';

/// Owns the active [ISpectSettingsState] snapshot.
///
/// `onChanged` fans out into the controller's merged listenable;
/// `onUserSettingsChanged` is forwarded to the host app so it can persist
/// the snapshot.
class SettingsManager {
  SettingsManager({
    ISpectSettingsState? initialSettings,
    void Function()? onChanged,
    ISpectSettingsChangedCallback? onUserSettingsChanged,
  })  : _settings = initialSettings ??
            const ISpectSettingsState(
              enabled: true,
              useConsoleLogs: true,
              useHistory: true,
            ),
        _onChanged = onChanged,
        _onUserSettingsChanged = onUserSettingsChanged;

  ISpectSettingsState _settings;
  final void Function()? _onChanged;
  final ISpectSettingsChangedCallback? _onUserSettingsChanged;

  ISpectSettingsState get settings => _settings;

  void updateSettings(ISpectSettingsState newSettings) {
    if (_settings == newSettings) return;
    _settings = newSettings;
    final cb = _onChanged;
    if (cb != null) cb();
    _onUserSettingsChanged?.call(newSettings);
  }
}
