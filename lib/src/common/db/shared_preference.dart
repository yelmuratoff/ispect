import 'package:shared_preferences/shared_preferences.dart';

/// Singleton instance of the [SharedPreferenceHelper] class.
final SharedPreferenceHelper sharedPreference =
    SharedPreferenceHelper._internal();

class SharedPreferenceHelper {
  /// Factory constructor to return the same instance.
  factory SharedPreferenceHelper() => sharedPreference;

  /// Private constructor for Singleton implementation.
  SharedPreferenceHelper._internal();
  SharedPreferences? _sharedPreference;

  /// Initializes the `SharedPreferences` instance if not already initialized.
  Future<void> init() async {
    _sharedPreference = await SharedPreferences.getInstance();
  }

  bool get isInitialized => _sharedPreference != null;

  /// A getter that returns the `_sharedPreference` instance.
  SharedPreferences? get prefs => _sharedPreference;

  /// A method that clears all values in the `_sharedPreference` instance.
  Future<void> clearAll() async {
    await _sharedPreference?.clear();
  }

  /// Methods for setting and getting `DraggableButton` position.
  double get draggableButtonOx =>
      _sharedPreference?.getDouble(Preferences.draggableButtonOx) ?? 0.0;

  double get draggableButtonOy =>
      _sharedPreference?.getDouble(Preferences.draggableButtonOy) ?? 600;

  Future<void> setDraggableButtonOx(double value) async {
    await _sharedPreference?.setDouble(Preferences.draggableButtonOx, value);
  }

  Future<void> setDraggableButtonOy(double value) async {
    await _sharedPreference?.setDouble(Preferences.draggableButtonOy, value);
  }
}

final class Preferences {
  const Preferences._();

  static const String draggableButtonOx = 'ISpect.draggableButtonOx';
  static const String draggableButtonOy = 'ISpect.draggableButtonOy';
}
