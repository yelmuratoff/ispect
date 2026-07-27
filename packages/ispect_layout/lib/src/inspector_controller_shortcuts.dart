part of 'inspector_controller.dart';

extension InspectorControllerShortcuts on InspectorController {
  List<ShortcutActivator> get effectiveWidgetInspectorShortcutActivators =>
      isEnabled
          ? _shortcuts.effectiveInspectorActivators
          : const <ShortcutActivator>[];

  List<ShortcutActivator>
      get effectiveWidgetInspectAndCompareShortcutActivators => isEnabled
          ? _shortcuts.effectiveCompareActivators
          : const <ShortcutActivator>[];

  List<ShortcutActivator> get effectiveColorPickerShortcutActivators =>
      isEnabled
          ? _shortcuts.effectiveColorPickerActivators
          : const <ShortcutActivator>[];

  List<ShortcutActivator> get effectiveZoomShortcutActivators => isEnabled
      ? _shortcuts.effectiveZoomActivators
      : const <ShortcutActivator>[];

  bool acceptsWidgetInspectorShortcut(KeyEvent event, HardwareKeyboard state) =>
      isEnabled && _shortcuts.acceptsInspector(event, state);

  bool acceptsCompareShortcut(KeyEvent event, HardwareKeyboard state) =>
      isEnabled && _shortcuts.acceptsCompare(event, state);

  bool acceptsColorPickerShortcut(KeyEvent event, HardwareKeyboard state) =>
      isEnabled && _shortcuts.acceptsColorPicker(event, state);

  bool acceptsZoomShortcut(KeyEvent event, HardwareKeyboard state) =>
      isEnabled && _shortcuts.acceptsZoom(event, state);

  bool isWidgetInspectorShortcutStillPressed(HardwareKeyboard state) =>
      isEnabled && _shortcuts.inspectorStillPressed(state);

  bool isColorPickerShortcutStillPressed(HardwareKeyboard state) =>
      isEnabled && _shortcuts.colorPickerStillPressed(state);

  bool isZoomShortcutStillPressed(HardwareKeyboard state) =>
      isEnabled && _shortcuts.zoomStillPressed(state);
}
