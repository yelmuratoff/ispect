import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'utils.dart';
import 'widgets/color_picker/color_picker_snackbar.dart';
import 'widgets/color_picker/utils.dart';
import 'widgets/inspector/box_info.dart';

enum InspectorMode {
  none,
  inspector,
  inspectAndCompare,
  compareSelect,
  colorPicker,
  zoom,
}

class InspectorController {
  InspectorController({
    this.isEnabled = true,
    this.isWidgetInspectorEnabled = true,
    this.isWidgetInspectAndCompareEnabled = true,
    this.isColorPickerEnabled = true,
    this.isColorSchemeHintEnabled = true,
    this.isZoomEnabled = true,
    this.decimalPlaces = 1,
    this.widgetInspectorShortcuts,
    this.widgetInspectAndCompareShortcuts,
    this.colorPickerShortcuts,
    this.zoomShortcuts,
    this.widgetInspectorShortcutActivators,
    this.widgetInspectAndCompareShortcutActivators,
    this.colorPickerShortcutActivators,
    this.zoomShortcutActivators,
  }) : assert(decimalPlaces >= 0, 'decimalPlaces must be >= 0');

  final bool isEnabled;
  final bool isWidgetInspectorEnabled;
  final bool isWidgetInspectAndCompareEnabled;
  final bool isColorPickerEnabled;
  final bool isColorSchemeHintEnabled;
  final bool isZoomEnabled;
  final int decimalPlaces;

  /// Deprecated. Use [widgetInspectorShortcutActivators] — it supports
  /// multi-key chords and the full [ShortcutActivator] API. Will be removed
  /// in 5.1.0.
  @Deprecated(
      'Use widgetInspectorShortcutActivators. Will be removed in 5.1.0.')
  final List<LogicalKeyboardKey>? widgetInspectorShortcuts;

  @Deprecated(
      'Use widgetInspectAndCompareShortcutActivators. Will be removed in 5.1.0.')
  final List<LogicalKeyboardKey>? widgetInspectAndCompareShortcuts;

  @Deprecated('Use colorPickerShortcutActivators. Will be removed in 5.1.0.')
  final List<LogicalKeyboardKey>? colorPickerShortcuts;

  @Deprecated('Use zoomShortcutActivators. Will be removed in 5.1.0.')
  final List<LogicalKeyboardKey>? zoomShortcuts;

  final List<ShortcutActivator>? widgetInspectorShortcutActivators;
  final List<ShortcutActivator>? widgetInspectAndCompareShortcutActivators;
  final List<ShortcutActivator>? colorPickerShortcutActivators;
  final List<ShortcutActivator>? zoomShortcutActivators;

  final GlobalKey stackKey = GlobalKey();
  final GlobalKey repaintBoundaryKey = GlobalKey();
  final GlobalKey ignoringPointerKey = GlobalKey();

  final modeNotifier = ValueNotifier<InspectorMode>(InspectorMode.none);

  final byteDataStateNotifier = ValueNotifier<ByteData?>(null);

  final currentRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);
  final hoveredRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);
  final comparedRenderBoxNotifier = ValueNotifier<BoxInfo?>(null);

  final selectedColorOffsetNotifier = ValueNotifier<Offset?>(null);
  final selectedColorStateNotifier = ValueNotifier<Color?>(null);
  final selectedColorImageOffsetNotifier = ValueNotifier<Offset?>(null);

  final zoomImageOffsetNotifier = ValueNotifier<Offset?>(null);
  final zoomScaleNotifier = ValueNotifier<double>(2.0);
  final zoomOverlayOffsetNotifier = ValueNotifier<Offset?>(null);

  ui.Image? _image;
  ui.Image? get image => _image;
  Offset? _pointerHoverPosition;
  bool _isDisposed = false;
  int _imageCaptureEpoch = 0;

  void dispose() {
    _isDisposed = true;
    _imageCaptureEpoch++;
    _image?.dispose();
    modeNotifier.dispose();
    byteDataStateNotifier.dispose();
    currentRenderBoxNotifier.dispose();
    hoveredRenderBoxNotifier.dispose();
    comparedRenderBoxNotifier.dispose();
    selectedColorOffsetNotifier.dispose();
    selectedColorStateNotifier.dispose();
    selectedColorImageOffsetNotifier.dispose();
    zoomImageOffsetNotifier.dispose();
    zoomScaleNotifier.dispose();
    zoomOverlayOffsetNotifier.dispose();
  }

  List<ShortcutActivator> get effectiveWidgetInspectorShortcutActivators =>
      _resolveShortcutActivators(
        explicit: widgetInspectorShortcutActivators,
        // ignore: deprecated_member_use_from_same_package
        legacyKeys: widgetInspectorShortcuts,
        defaultActivators: const [
          SingleActivator(
            LogicalKeyboardKey.keyW,
            alt: true,
            includeRepeats: false,
          ),
        ],
      );

  List<ShortcutActivator>
      get effectiveWidgetInspectAndCompareShortcutActivators =>
          _resolveShortcutActivators(
            explicit: widgetInspectAndCompareShortcutActivators,
            // ignore: deprecated_member_use_from_same_package
            legacyKeys: widgetInspectAndCompareShortcuts,
            defaultActivators: const [
              SingleActivator(
                LogicalKeyboardKey.keyY,
                alt: true,
                includeRepeats: false,
              ),
            ],
            legacyFactory: _legacyToggleActivator,
          );

  List<ShortcutActivator> get effectiveColorPickerShortcutActivators =>
      _resolveShortcutActivators(
        explicit: colorPickerShortcutActivators,
        // ignore: deprecated_member_use_from_same_package
        legacyKeys: colorPickerShortcuts,
        defaultActivators: const [
          SingleActivator(
            LogicalKeyboardKey.keyC,
            alt: true,
            includeRepeats: false,
          ),
        ],
      );

  List<ShortcutActivator> get effectiveZoomShortcutActivators =>
      _resolveShortcutActivators(
        explicit: zoomShortcutActivators,
        // ignore: deprecated_member_use_from_same_package
        legacyKeys: zoomShortcuts,
        defaultActivators: const [
          SingleActivator(
            LogicalKeyboardKey.keyZ,
            alt: true,
            includeRepeats: false,
          ),
        ],
      );

  bool acceptsWidgetInspectorShortcut(KeyEvent event, HardwareKeyboard state) =>
      _matchesAnyShortcut(
        effectiveWidgetInspectorShortcutActivators,
        event,
        state,
      );

  bool acceptsCompareShortcut(KeyEvent event, HardwareKeyboard state) =>
      _matchesAnyShortcut(
        effectiveWidgetInspectAndCompareShortcutActivators,
        event,
        state,
      );

  bool acceptsColorPickerShortcut(KeyEvent event, HardwareKeyboard state) =>
      _matchesAnyShortcut(
        effectiveColorPickerShortcutActivators,
        event,
        state,
      );

  bool acceptsZoomShortcut(KeyEvent event, HardwareKeyboard state) =>
      _matchesAnyShortcut(
        effectiveZoomShortcutActivators,
        event,
        state,
      );

  bool isWidgetInspectorShortcutStillPressed(HardwareKeyboard state) =>
      _isAnyShortcutPressed(
        effectiveWidgetInspectorShortcutActivators,
        state,
      );

  bool isColorPickerShortcutStillPressed(HardwareKeyboard state) =>
      _isAnyShortcutPressed(
        effectiveColorPickerShortcutActivators,
        state,
      );

  bool isZoomShortcutStillPressed(HardwareKeyboard state) =>
      _isAnyShortcutPressed(
        effectiveZoomShortcutActivators,
        state,
      );

  void handleInspectorShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.inspector);

  void handleCompareShortcut() =>
      _toggleMode(true, InspectorMode.inspectAndCompare);

  void handleColorPickerShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.colorPicker);

  void handleZoomShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.zoom);

  List<ShortcutActivator> _resolveShortcutActivators({
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

  bool _matchesAnyShortcut(
    List<ShortcutActivator> activators,
    KeyEvent event,
    HardwareKeyboard state,
  ) {
    for (final activator in activators) {
      if (activator.accepts(event, state)) return true;
    }
    return false;
  }

  bool _isAnyShortcutPressed(
    List<ShortcutActivator> activators,
    HardwareKeyboard state,
  ) {
    for (final activator in activators) {
      if (_isShortcutPressed(activator, state)) return true;
    }
    return false;
  }

  bool _isShortcutPressed(ShortcutActivator activator, HardwareKeyboard state) {
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

    return false;
  }

  static ShortcutActivator _legacyHoldActivator(LogicalKeyboardKey key) {
    if (_isModifierKey(key)) {
      return LogicalKeySet(key);
    }
    return SingleActivator(key, includeRepeats: false);
  }

  static ShortcutActivator _legacyToggleActivator(LogicalKeyboardKey key) =>
      SingleActivator(key, includeRepeats: false);

  static bool _isModifierKey(LogicalKeyboardKey key) => _modifierKeys.contains(
        LogicalKeyboardKey.collapseSynonyms(<LogicalKeyboardKey>{key}).single,
      );

  void _toggleMode(bool enable, InspectorMode targetMode) {
    if (targetMode == InspectorMode.inspectAndCompare) {
      if (enable) {
        if (modeNotifier.value == InspectorMode.compareSelect) {
          exitCompareMode();
        } else {
          enterCompareMode();
        }
      }
      return;
    }

    if (enable) {
      setMode(targetMode);
    } else if (modeNotifier.value == targetMode) {
      setMode(InspectorMode.none);
    }
  }

  /// Enter compare mode: wait for the user to tap a second widget.
  ///
  /// Requires a prior selection. Without one we surface a short snackbar
  /// via [stackKey]'s context if it's available, so the user gets visible
  /// feedback instead of silent no-op.
  void enterCompareMode() {
    if (currentRenderBoxNotifier.value == null) {
      final context = stackKey.currentContext;
      if (context != null) {
        final messenger = ScaffoldMessenger.maybeOf(context);
        messenger?.clearSnackBars();
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('Select a widget first, then press Compare.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }
    setMode(InspectorMode.compareSelect);
  }

  /// Exit compare mode and reset compare state.
  void exitCompareMode() {
    setMode(InspectorMode.inspector);
  }

  void setMode(InspectorMode mode, {BuildContext? context}) {
    if (mode == modeNotifier.value) return;

    // Check if mode is enabled
    switch (mode) {
      case InspectorMode.inspector:
        if (!isWidgetInspectorEnabled) return;
        break;
      case InspectorMode.inspectAndCompare:
        if (!isWidgetInspectorEnabled || !isWidgetInspectAndCompareEnabled) {
          return;
        }
        break;
      case InspectorMode.compareSelect:
        if (!isWidgetInspectorEnabled || !isWidgetInspectAndCompareEnabled) {
          return;
        }
        if (currentRenderBoxNotifier.value == null) return;
        break;
      case InspectorMode.colorPicker:
        if (!isColorPickerEnabled) return;
        break;
      case InspectorMode.zoom:
        if (!isZoomEnabled) return;
        break;
      case InspectorMode.none:
        break;
    }

    // Cleanup previous mode
    _cleanupMode(modeNotifier.value, mode, context);

    modeNotifier.value = mode;

    // Setup new mode
    _setupMode(mode);
  }

  void _cleanupMode(
      InspectorMode oldMode, InspectorMode newMode, BuildContext? context) {
    switch (oldMode) {
      case InspectorMode.inspector:
      case InspectorMode.inspectAndCompare:
      case InspectorMode.compareSelect:
        if (newMode != InspectorMode.inspector &&
            newMode != InspectorMode.inspectAndCompare &&
            newMode != InspectorMode.compareSelect) {
          currentRenderBoxNotifier.value = null;
          hoveredRenderBoxNotifier.value = null;
          comparedRenderBoxNotifier.value = null;
        } else {
          hoveredRenderBoxNotifier.value = null;
          comparedRenderBoxNotifier.value = null;
        }
        break;
      case InspectorMode.colorPicker:
        if (selectedColorStateNotifier.value != null && context != null) {
          showColorPickerResultSnackbar(
            context: context,
            color: selectedColorStateNotifier.value!,
          );
        }
        _cleanupImage();
        selectedColorOffsetNotifier.value = null;
        selectedColorStateNotifier.value = null;
        selectedColorImageOffsetNotifier.value = null;
        break;
      case InspectorMode.zoom:
        _cleanupImage();
        zoomImageOffsetNotifier.value = null;
        zoomOverlayOffsetNotifier.value = null;
        zoomScaleNotifier.value = 2.0;
        break;
      case InspectorMode.none:
        break;
    }
  }

  void _setupMode(InspectorMode mode) {
    switch (mode) {
      case InspectorMode.inspector:
      case InspectorMode.inspectAndCompare:
      case InspectorMode.compareSelect:
        break;
      case InspectorMode.colorPicker:
        final captureEpoch = ++_imageCaptureEpoch;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _extractByteData(captureEpoch);
        });
        break;
      case InspectorMode.zoom:
        final captureEpoch = ++_imageCaptureEpoch;
        zoomScaleNotifier.value = 2.0;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _extractByteData(captureEpoch);
          if (_isDisposed || captureEpoch != _imageCaptureEpoch) return;
          if (_pointerHoverPosition != null &&
              stackKey.currentContext != null) {
            _onZoomHover(_pointerHoverPosition!, stackKey.currentContext!);
          }
        });
        break;
      case InspectorMode.none:
        break;
    }
  }

  void _cleanupImage() {
    _imageCaptureEpoch++;
    _image?.dispose();
    _image = null;
    if (_isDisposed) return;
    byteDataStateNotifier.value = null;
  }

  void onTap(Offset? pointerOffset, BuildContext context) {
    final mode = modeNotifier.value;
    if (mode == InspectorMode.none) return;

    if (mode == InspectorMode.colorPicker) {
      if (pointerOffset != null) {
        _onColorPickerHover(pointerOffset, context);
      }
      setMode(InspectorMode.none, context: context);
      return;
    }

    if (mode == InspectorMode.zoom) {
      setMode(InspectorMode.none);
      return;
    }

    if (mode == InspectorMode.compareSelect) {
      if (pointerOffset == null) return;
      final compared = _computeBoxInfoAt(pointerOffset);
      setMode(InspectorMode.inspector);
      if (compared != null &&
          compared.targetRenderBox !=
              currentRenderBoxNotifier.value?.targetRenderBox) {
        comparedRenderBoxNotifier.value = compared;
      }
      return;
    }

    if (mode == InspectorMode.inspector ||
        mode == InspectorMode.inspectAndCompare) {
      if (pointerOffset == null) return;
      hoveredRenderBoxNotifier.value = null;
      comparedRenderBoxNotifier.value = null;
      currentRenderBoxNotifier.value = _computeBoxInfoAt(
        pointerOffset,
        findContainer: true,
      );
    }
  }

  void onPointerMove(Offset pointerOffset, BuildContext context) {
    _pointerHoverPosition = pointerOffset;
    final mode = modeNotifier.value;

    if (mode == InspectorMode.colorPicker) {
      _onColorPickerHover(pointerOffset, context);
    } else if (mode == InspectorMode.zoom) {
      _onZoomHover(pointerOffset, context);
    }
  }

  void onPointerHoverDebounced(Offset pointerOffset, BuildContext context) {
    _onPointerHover(pointerOffset);
  }

  void _onPointerHover(Offset pointerOffset) {
    _pointerHoverPosition = pointerOffset;
    final mode = modeNotifier.value;

    if (mode == InspectorMode.zoom) {
      final context = stackKey.currentContext;
      if (context != null) {
        _onZoomHover(pointerOffset, context);
      }
      return;
    }

    if (mode == InspectorMode.inspector ||
        mode == InspectorMode.inspectAndCompare ||
        mode == InspectorMode.compareSelect) {
      if (mode == InspectorMode.inspectAndCompare) {
        hoveredRenderBoxNotifier.value = null;
        final compare = _computeBoxInfoAt(pointerOffset);
        if (compare?.targetRenderBox !=
            currentRenderBoxNotifier.value?.targetRenderBox) {
          comparedRenderBoxNotifier.value = compare;
        } else {
          comparedRenderBoxNotifier.value = null;
        }
      } else {
        final hover = _computeBoxInfoAt(pointerOffset);
        if (hover?.targetRenderBox !=
            currentRenderBoxNotifier.value?.targetRenderBox) {
          hoveredRenderBoxNotifier.value = hover;
        } else {
          hoveredRenderBoxNotifier.value = null;
        }
      }
    }
  }

  void onPointerExit(Offset pointerOffset) {
    hoveredRenderBoxNotifier.value = null;
  }

  void onPointerScroll(PointerScrollEvent scrollEvent) {
    if (modeNotifier.value == InspectorMode.zoom) {
      final newValue =
          zoomScaleNotifier.value + 1.0 * -scrollEvent.scrollDelta.dy.sign;

      if (newValue < 1.0) {
        return;
      }

      zoomScaleNotifier.value = newValue;
    }
  }

  BoxInfo? _computeBoxInfoAt(Offset offset, {bool findContainer = false}) {
    if (ignoringPointerKey.currentContext == null) return null;

    final boxes = InspectorUtils.findRenderObjectsAt(
        ignoringPointerKey.currentContext!, offset);

    if (boxes.isEmpty) return null;

    if (stackKey.currentContext == null) return null;

    final overlayOffset =
        (stackKey.currentContext!.findRenderObject()! as RenderBox)
            .localToGlobal(Offset.zero);

    return BoxInfo.fromHitTestResults(
      boxes,
      overlayOffset: overlayOffset,
      findContainer: findContainer,
    );
  }

  Future<void> _extractByteData(int captureEpoch) async {
    if (_isDisposed || captureEpoch != _imageCaptureEpoch) return;
    if (_image != null) return;
    if (repaintBoundaryKey.currentContext == null) return;

    final boundary = repaintBoundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;

    final context = repaintBoundaryKey.currentContext!;
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    if (_isDisposed || captureEpoch != _imageCaptureEpoch) {
      image.dispose();
      return;
    }

    final byteData = await image.toByteData();
    if (_isDisposed || captureEpoch != _imageCaptureEpoch) {
      image.dispose();
      return;
    }

    _image = image;
    byteDataStateNotifier.value = byteData;
  }

  Offset _extractShiftedOffset(Offset offset, BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    if (repaintBoundaryKey.currentContext == null) return Offset.zero;

    var offset0 = (repaintBoundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary)
        .globalToLocal(offset);

    offset0 *= pixelRatio;

    return offset0;
  }

  /// Clamps the pointer to the screen rect so color picker / zoom keep
  /// tracking the nearest valid pixel when the finger drifts off-screen
  /// instead of freezing or flying the overlay out of view.
  Offset _clampToScreen(Offset offset, BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.isEmpty) return offset;
    return Offset(
      offset.dx.clamp(0.0, size.width),
      offset.dy.clamp(0.0, size.height),
    );
  }

  void _onColorPickerHover(Offset offset, BuildContext context) {
    if (_image == null || byteDataStateNotifier.value == null) return;

    final clamped = _clampToScreen(offset, context);
    final shiftedOffset = _extractShiftedOffset(clamped, context);
    final x = shiftedOffset.dx.round().clamp(0, _image!.width - 1);
    final y = shiftedOffset.dy.round().clamp(0, _image!.height - 1);

    final color = getPixelFromByteData(
      byteDataStateNotifier.value!,
      width: _image!.width,
      height: _image!.height,
      x: x,
      y: y,
    );

    if (color == null) return;

    selectedColorStateNotifier.value = color;
    selectedColorImageOffsetNotifier.value = shiftedOffset;

    if (stackKey.currentContext == null) return;

    final overlayOffset =
        (stackKey.currentContext!.findRenderObject()! as RenderBox)
            .localToGlobal(Offset.zero);

    selectedColorOffsetNotifier.value = clamped - overlayOffset;
  }

  void _onZoomHover(Offset offset, BuildContext context) {
    if (_image == null || byteDataStateNotifier.value == null) return;

    final clamped = _clampToScreen(offset, context);
    final shiftedOffset = _extractShiftedOffset(clamped, context);

    if (stackKey.currentContext == null) return;

    final overlayOffset =
        (stackKey.currentContext!.findRenderObject()! as RenderBox)
            .localToGlobal(Offset.zero);

    zoomImageOffsetNotifier.value = Offset(
      shiftedOffset.dx.clamp(0.0, _image!.width.toDouble()),
      shiftedOffset.dy.clamp(0.0, _image!.height.toDouble()),
    );
    zoomOverlayOffsetNotifier.value = clamped - overlayOffset;
  }
}

final _modifierKeys = <LogicalKeyboardKey>{
  LogicalKeyboardKey.alt,
  LogicalKeyboardKey.control,
  LogicalKeyboardKey.meta,
  LogicalKeyboardKey.shift,
};
