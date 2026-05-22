part of 'inspector_controller.dart';

extension InspectorControllerShortcuts on InspectorController {
  List<ShortcutActivator> get effectiveWidgetInspectorShortcutActivators =>
      _shortcuts.effectiveInspectorActivators;

  List<ShortcutActivator>
      get effectiveWidgetInspectAndCompareShortcutActivators =>
          _shortcuts.effectiveCompareActivators;

  List<ShortcutActivator> get effectiveColorPickerShortcutActivators =>
      _shortcuts.effectiveColorPickerActivators;

  List<ShortcutActivator> get effectiveZoomShortcutActivators =>
      _shortcuts.effectiveZoomActivators;

  bool acceptsWidgetInspectorShortcut(KeyEvent event, HardwareKeyboard state) =>
      _shortcuts.acceptsInspector(event, state);

  bool acceptsCompareShortcut(KeyEvent event, HardwareKeyboard state) =>
      _shortcuts.acceptsCompare(event, state);

  bool acceptsColorPickerShortcut(KeyEvent event, HardwareKeyboard state) =>
      _shortcuts.acceptsColorPicker(event, state);

  bool acceptsZoomShortcut(KeyEvent event, HardwareKeyboard state) =>
      _shortcuts.acceptsZoom(event, state);

  bool isWidgetInspectorShortcutStillPressed(HardwareKeyboard state) =>
      _shortcuts.inspectorStillPressed(state);

  bool isColorPickerShortcutStillPressed(HardwareKeyboard state) =>
      _shortcuts.colorPickerStillPressed(state);

  bool isZoomShortcutStillPressed(HardwareKeyboard state) =>
      _shortcuts.zoomStillPressed(state);
}
