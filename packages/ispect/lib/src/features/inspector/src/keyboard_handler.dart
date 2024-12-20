import 'package:flutter/services.dart';

class KeyboardHandler {
  KeyboardHandler({
    required this.onInspectorStateChanged,
    required this.onZoomStateChanged,
    this.inspectorStateKeys = const [
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
    ],
    this.colorPickerStateKeys = const [
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
    ],
    this.zoomStateKeys = const [
      LogicalKeyboardKey.keyZ,
    ],
  });

  final void Function({required bool value}) onInspectorStateChanged;
  final void Function({required bool value}) onZoomStateChanged;
  final List<LogicalKeyboardKey> inspectorStateKeys;
  final List<LogicalKeyboardKey> colorPickerStateKeys;
  final List<LogicalKeyboardKey> zoomStateKeys;

  bool _isRegistered = false;

  void register() {
    if (_isRegistered) return;

    HardwareKeyboard.instance.addHandler(_handler);
    _isRegistered = true;
  }

  void dispose() {
    if (!_isRegistered) return;

    HardwareKeyboard.instance.removeHandler(_handler);
    _isRegistered = false;
  }

  bool _handler(KeyEvent event) {
    if (event is KeyRepeatEvent) return false;

    if (inspectorStateKeys.contains(event.logicalKey)) {
      onInspectorStateChanged(value: event is! KeyUpEvent);
    } else if (zoomStateKeys.contains(event.logicalKey)) {
      onZoomStateChanged(value: event is! KeyUpEvent);
    }

    return false;
  }
}
