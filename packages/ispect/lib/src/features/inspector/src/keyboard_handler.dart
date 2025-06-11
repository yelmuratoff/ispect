import 'package:flutter/services.dart';

/// Handles keyboard shortcuts for inspector, color picker, and zoom functionality
///
/// This class manages keyboard event listeners and provides callbacks
/// for inspector state changes, color picker activation, and zoom operations.
/// It supports customizable key combinations and ensures proper resource cleanup.
///
/// - Parameters:
///   - [onInspectorStateChanged]: Callback when inspector state toggles
///   - [onColorPickerStateChanged]: Callback when color picker state toggles
///   - [onZoomStateChanged]: Callback when zoom state toggles
///   - [inspectorStateKeys]: Keys that toggle inspector (default: Alt keys)
///   - [colorPickerStateKeys]: Keys that toggle color picker (default: Shift keys)
///   - [zoomStateKeys]: Keys that toggle zoom mode (default: Z key)
///
/// - Usage example:
///   ```dart
///   final handler = KeyboardHandler(
///     onInspectorStateChanged: ({required bool value}) => print('Inspector: $value'),
///     onColorPickerStateChanged: ({required bool value}) => print('Color Picker: $value'),
///     onZoomStateChanged: ({required bool value}) => print('Zoom: $value'),
///   );
///   handler.register();
///   // ... later
///   handler.dispose();
///   ```
///
/// - Edge case notes:
///   - Key repeat events are ignored to prevent rapid state changes
///   - Safe to call register() and dispose() multiple times
///   - All three modes (inspector, color picker, zoom) can be active simultaneously
class KeyboardHandler {
  /// Creates a keyboard handler with customizable key configurations
  KeyboardHandler({
    required this.onInspectorStateChanged,
    required this.onZoomStateChanged,
    this.inspectorStateKeys = const [
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
    ],
    this.zoomStateKeys = const [
      LogicalKeyboardKey.keyZ,
    ],
  });

  /// Callback triggered when inspector state changes
  ///
  /// Called with [value] true on key down, false on key up
  final void Function({required bool value}) onInspectorStateChanged;

  /// Callback triggered when zoom state changes
  ///
  /// Called with [value] true on key down, false on key up
  final void Function({required bool value}) onZoomStateChanged;

  /// Keys that toggle the inspector state (default: Alt keys)
  final List<LogicalKeyboardKey> inspectorStateKeys;

  /// Keys that toggle zoom mode (default: Z key)
  final List<LogicalKeyboardKey> zoomStateKeys;

  /// Tracks whether keyboard handler is currently registered
  bool _isRegistered = false;

  /// Registers the keyboard event handler
  ///
  /// Safe to call multiple times - will only register once.
  /// Must be called before keyboard events can be handled.
  void register() {
    if (_isRegistered) return;

    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _isRegistered = true;
  }

  /// Unregisters the keyboard event handler and cleans up resources
  ///
  /// Safe to call multiple times - will only unregister if currently registered.
  /// Should be called when the handler is no longer needed to prevent memory leaks.
  void dispose() {
    if (!_isRegistered) return;

    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _isRegistered = false;
  }

  /// Handles incoming keyboard events and triggers appropriate callbacks
  ///
  /// Returns false to allow other handlers to process the event.
  /// Ignores key repeat events to prevent rapid state changes.
  bool _handleKeyEvent(KeyEvent event) {
    // Ignore key repeat events to prevent rapid state toggling
    if (event is KeyRepeatEvent) return false;

    final pressedKey = event.logicalKey;
    final isKeyDown = event is! KeyUpEvent;

    // Check if pressed key is an inspector toggle key
    if (inspectorStateKeys.contains(pressedKey)) {
      onInspectorStateChanged(value: isKeyDown);
      return false;
    }

    // Check if pressed key is a zoom toggle key
    if (zoomStateKeys.contains(pressedKey)) {
      onZoomStateChanged(value: isKeyDown);
      return false;
    }

    // Allow other handlers to process unhandled keys
    return false;
  }
}
