import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Resolves shortcut configuration into concrete [ShortcutActivator]s and
/// answers accept / still-pressed queries.
///
/// Three configuration layers, in priority order:
/// 1. An explicit [ShortcutActivator] list (modern API).
/// 2. A [LogicalKeyboardKey] list (legacy API; deprecated on the controller).
/// 3. A built-in default.
class InspectorShortcuts {
  InspectorShortcuts({
    required this.inspectorActivators,
    required this.inspectorLegacyKeys,
    required this.compareActivators,
    required this.compareLegacyKeys,
    required this.colorPickerActivators,
    required this.colorPickerLegacyKeys,
    required this.zoomActivators,
    required this.zoomLegacyKeys,
  });

  final List<ShortcutActivator>? inspectorActivators;
  final List<LogicalKeyboardKey>? inspectorLegacyKeys;

  final List<ShortcutActivator>? compareActivators;
  final List<LogicalKeyboardKey>? compareLegacyKeys;

  final List<ShortcutActivator>? colorPickerActivators;
  final List<LogicalKeyboardKey>? colorPickerLegacyKeys;

  final List<ShortcutActivator>? zoomActivators;
  final List<LogicalKeyboardKey>? zoomLegacyKeys;

  static const _defaultInspector = [
    SingleActivator(LogicalKeyboardKey.keyW, alt: true, includeRepeats: false),
  ];
  static const _defaultCompare = [
    SingleActivator(LogicalKeyboardKey.keyY, alt: true, includeRepeats: false),
  ];
  static const _defaultColorPicker = [
    SingleActivator(LogicalKeyboardKey.keyC, alt: true, includeRepeats: false),
  ];
  static const _defaultZoom = [
    SingleActivator(LogicalKeyboardKey.keyZ, alt: true, includeRepeats: false),
  ];

  List<ShortcutActivator> get effectiveInspectorActivators => _resolve(
        explicit: inspectorActivators,
        legacyKeys: inspectorLegacyKeys,
        defaultActivators: _defaultInspector,
      );

  List<ShortcutActivator> get effectiveCompareActivators => _resolve(
        explicit: compareActivators,
        legacyKeys: compareLegacyKeys,
        defaultActivators: _defaultCompare,
        legacyFactory: _legacyToggleActivator,
      );

  List<ShortcutActivator> get effectiveColorPickerActivators => _resolve(
        explicit: colorPickerActivators,
        legacyKeys: colorPickerLegacyKeys,
        defaultActivators: _defaultColorPicker,
      );

  List<ShortcutActivator> get effectiveZoomActivators => _resolve(
        explicit: zoomActivators,
        legacyKeys: zoomLegacyKeys,
        defaultActivators: _defaultZoom,
      );

  bool acceptsInspector(KeyEvent event, HardwareKeyboard state) =>
      _matchesAny(effectiveInspectorActivators, event, state);

  bool acceptsCompare(KeyEvent event, HardwareKeyboard state) =>
      _matchesAny(effectiveCompareActivators, event, state);

  bool acceptsColorPicker(KeyEvent event, HardwareKeyboard state) =>
      _matchesAny(effectiveColorPickerActivators, event, state);

  bool acceptsZoom(KeyEvent event, HardwareKeyboard state) =>
      _matchesAny(effectiveZoomActivators, event, state);

  bool inspectorStillPressed(HardwareKeyboard state) =>
      _anyStillPressed(effectiveInspectorActivators, state);

  bool colorPickerStillPressed(HardwareKeyboard state) =>
      _anyStillPressed(effectiveColorPickerActivators, state);

  bool zoomStillPressed(HardwareKeyboard state) =>
      _anyStillPressed(effectiveZoomActivators, state);

  static List<ShortcutActivator> _resolve({
    required List<ShortcutActivator>? explicit,
    required List<LogicalKeyboardKey>? legacyKeys,
    required List<ShortcutActivator> defaultActivators,
    ShortcutActivator Function(LogicalKeyboardKey key)? legacyFactory,
  }) {
    if (explicit != null) return List.unmodifiable(explicit);
    if (legacyKeys != null) {
      return List.unmodifiable(
        legacyKeys.map(legacyFactory ?? _legacyHoldActivator),
      );
    }
    return defaultActivators;
  }

  static bool _matchesAny(
    List<ShortcutActivator> activators,
    KeyEvent event,
    HardwareKeyboard state,
  ) {
    for (final activator in activators) {
      if (activator.accepts(event, state)) return true;
    }
    return false;
  }

  static bool _anyStillPressed(
    List<ShortcutActivator> activators,
    HardwareKeyboard state,
  ) {
    for (final activator in activators) {
      if (_isPressed(activator, state)) return true;
    }
    return false;
  }

  static bool _isPressed(ShortcutActivator activator, HardwareKeyboard state) {
    final pressed = state.logicalKeysPressed;

    if (activator is SingleActivator) {
      return pressed.contains(activator.trigger) &&
          activator.control == state.isControlPressed &&
          activator.shift == state.isShiftPressed &&
          activator.alt == state.isAltPressed &&
          activator.meta == state.isMetaPressed;
    }

    if (activator is LogicalKeySet) {
      final requiredKeys = activator.keys
          .map(
            (key) =>
                LogicalKeyboardKey.collapseSynonyms(<LogicalKeyboardKey>{key})
                    .single,
          )
          .toSet();
      final pressedKeys = LogicalKeyboardKey.collapseSynonyms(pressed);
      return requiredKeys.every(pressedKeys.contains);
    }

    // Fallback for custom ShortcutActivator subclasses: while every trigger
    // key is still down, consider the shortcut active. Better than the
    // blanket `false` an earlier version returned, which silently broke
    // hold-to-activate for custom activators.
    final triggers = activator.triggers;
    if (triggers != null && triggers.isNotEmpty) {
      return triggers.every(pressed.contains);
    }

    return false;
  }

  static ShortcutActivator _legacyHoldActivator(LogicalKeyboardKey key) {
    if (_modifierKeys.contains(
      LogicalKeyboardKey.collapseSynonyms(<LogicalKeyboardKey>{key}).single,
    )) {
      return LogicalKeySet(key);
    }
    return SingleActivator(key, includeRepeats: false);
  }

  static ShortcutActivator _legacyToggleActivator(LogicalKeyboardKey key) =>
      SingleActivator(key, includeRepeats: false);
}

final _modifierKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.shift,
};
