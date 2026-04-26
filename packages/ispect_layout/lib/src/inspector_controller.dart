import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'inspector_state.dart';
import 'pixel_capture.dart';
import 'shortcut_registry.dart';
import 'theme.dart';
import 'utils.dart';
import 'widgets/color_picker/color_picker_snackbar.dart';
import 'widgets/color_picker/utils.dart';
import 'widgets/inspector/box_info.dart';

export 'inspector_state.dart';

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
    this.theme = InspectorTheme.defaults,
    this.widgetInspectorShortcuts,
    this.widgetInspectAndCompareShortcuts,
    this.colorPickerShortcuts,
    this.zoomShortcuts,
    this.widgetInspectorShortcutActivators,
    this.widgetInspectAndCompareShortcutActivators,
    this.colorPickerShortcutActivators,
    this.zoomShortcutActivators,
  }) : assert(decimalPlaces >= 0, 'decimalPlaces must be >= 0') {
    // Keep the sealed `stateNotifier` in sync with the legacy granular
    // notifiers. Legacy notifiers remain the mutation surface — internal
    // logic writes to them, and we recompute the union state here.
    for (final l in _allStateInputs) {
      l.addListener(_recomputeStateNotifier);
    }
  }

  final bool isEnabled;
  final bool isWidgetInspectorEnabled;
  final bool isWidgetInspectAndCompareEnabled;
  final bool isColorPickerEnabled;
  final bool isColorSchemeHintEnabled;
  final bool isZoomEnabled;
  final int decimalPlaces;
  final InspectorTheme theme;

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
  final zoomScaleNotifier = ValueNotifier<double>(_initialZoomScale);
  final zoomOverlayOffsetNotifier = ValueNotifier<Offset?>(null);

  static const double _initialZoomScale = 4.0;
  static const double _minZoomScale = 1.0;
  static const double _maxZoomScale = 20.0;
  static const double _zoomStep = 1.0;

  double get minZoomScale => _minZoomScale;
  double get maxZoomScale => _maxZoomScale;

  void zoomIn() => _setZoomScale(zoomScaleNotifier.value + _zoomStep);

  void zoomOut() => _setZoomScale(zoomScaleNotifier.value - _zoomStep);

  void _setZoomScale(double next) {
    final clamped = next.clamp(_minZoomScale, _maxZoomScale);
    if (clamped == zoomScaleNotifier.value) return;
    zoomScaleNotifier.value = clamped;
  }

  /// Consolidated sealed-state view. Updated automatically whenever any of
  /// the legacy granular notifiers changes.
  ///
  /// Exists alongside the legacy notifiers for callers who prefer
  /// exhaustive `switch` over composing multiple listeners.
  final stateNotifier =
      ValueNotifier<InspectorUiState>(const InspectorIdleState());

  late final List<Listenable> _allStateInputs = [
    modeNotifier,
    byteDataStateNotifier,
    currentRenderBoxNotifier,
    hoveredRenderBoxNotifier,
    comparedRenderBoxNotifier,
    selectedColorOffsetNotifier,
    selectedColorStateNotifier,
    selectedColorImageOffsetNotifier,
    zoomImageOffsetNotifier,
    zoomScaleNotifier,
    zoomOverlayOffsetNotifier,
  ];

  void _recomputeStateNotifier() {
    if (_isDisposed) return;
    stateNotifier.value = _computeStateSnapshot();
  }

  InspectorUiState _computeStateSnapshot() {
    switch (modeNotifier.value) {
      case InspectorMode.none:
        return const InspectorIdleState();
      case InspectorMode.inspector:
      case InspectorMode.inspectAndCompare:
      case InspectorMode.compareSelect:
        return InspectorInspectState(
          selected: currentRenderBoxNotifier.value,
          hovered: hoveredRenderBoxNotifier.value,
          compared: comparedRenderBoxNotifier.value,
          comparing: modeNotifier.value == InspectorMode.compareSelect,
        );
      case InspectorMode.colorPicker:
        return InspectorColorPickerState(
          image: _image,
          byteData: byteDataStateNotifier.value,
          pointerOffset: selectedColorOffsetNotifier.value,
          imageOffset: selectedColorImageOffsetNotifier.value,
          pickedColor: selectedColorStateNotifier.value,
        );
      case InspectorMode.zoom:
        return InspectorZoomState(
          image: _image,
          byteData: byteDataStateNotifier.value,
          pointerOffset: zoomOverlayOffsetNotifier.value,
          imageOffset: zoomImageOffsetNotifier.value,
          scale: zoomScaleNotifier.value,
        );
    }
  }

  ui.Image? _image;
  ui.Image? get image => _image;
  Offset? _pointerHoverPosition;
  bool _isDisposed = false;
  int _imageCaptureEpoch = 0;

  void dispose() {
    _isDisposed = true;
    _imageCaptureEpoch++;
    _image?.dispose();
    for (final l in _allStateInputs) {
      l.removeListener(_recomputeStateNotifier);
    }
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
    stateNotifier.dispose();
  }

  /// Shortcut configuration + accept/isPressed logic. The controller
  /// delegates here for all keyboard-shortcut work — see [InspectorShortcuts].
  late final InspectorShortcuts _shortcuts = InspectorShortcuts(
    inspectorActivators: widgetInspectorShortcutActivators,
    // ignore: deprecated_member_use_from_same_package
    inspectorLegacyKeys: widgetInspectorShortcuts,
    compareActivators: widgetInspectAndCompareShortcutActivators,
    // ignore: deprecated_member_use_from_same_package
    compareLegacyKeys: widgetInspectAndCompareShortcuts,
    colorPickerActivators: colorPickerShortcutActivators,
    // ignore: deprecated_member_use_from_same_package
    colorPickerLegacyKeys: colorPickerShortcuts,
    zoomActivators: zoomShortcutActivators,
    // ignore: deprecated_member_use_from_same_package
    zoomLegacyKeys: zoomShortcuts,
  );

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

  void handleInspectorShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.inspector);

  void handleCompareShortcut() =>
      _toggleMode(true, InspectorMode.inspectAndCompare);

  void handleColorPickerShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.colorPicker);

  void handleZoomShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.zoom);

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

  /// Commit the current selection for the active inspection mode and exit.
  ///
  /// Color picker: surfaces the result snackbar with the locked colour.
  /// Zoom: there is nothing to commit, so this just exits the mode.
  void confirmCurrentSelection({required BuildContext context}) {
    final mode = modeNotifier.value;
    if (mode == InspectorMode.colorPicker) {
      final color = selectedColorStateNotifier.value;
      if (color != null) {
        HapticFeedback.selectionClick();
        showColorPickerResultSnackbar(
          context: context,
          color: color,
          showColorSchemeMatch: isColorSchemeHintEnabled,
        );
      }
    }
    setMode(InspectorMode.none);
  }

  /// Exit the active inspection mode without committing anything.
  void cancelCurrentMode() {
    setMode(InspectorMode.none);
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
        // Snackbar is now surfaced only via confirmCurrentSelection — closing
        // the mode through cancel / panel toggle should not commit anything.
        _cleanupImage();
        selectedColorOffsetNotifier.value = null;
        selectedColorStateNotifier.value = null;
        selectedColorImageOffsetNotifier.value = null;
        break;
      case InspectorMode.zoom:
        _cleanupImage();
        zoomImageOffsetNotifier.value = null;
        zoomOverlayOffsetNotifier.value = null;
        zoomScaleNotifier.value = _initialZoomScale;
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
        zoomScaleNotifier.value = _initialZoomScale;
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
      // Lock the sampled colour at the tap point but keep the mode active —
      // user explicitly confirms / cancels via the bottom action bar.
      if (pointerOffset != null) {
        _onColorPickerHover(pointerOffset, context);
      }
      if (selectedColorStateNotifier.value != null) {
        HapticFeedback.selectionClick();
      }
      return;
    }

    if (mode == InspectorMode.zoom) {
      // Same idea for zoom: the loupe stays anchored where the user tapped,
      // and they leave via the bottom action bar.
      if (pointerOffset != null) {
        final ctx = stackKey.currentContext ?? context;
        _onZoomHover(pointerOffset, ctx);
      }
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
      _setZoomScale(
        zoomScaleNotifier.value + _zoomStep * -scrollEvent.scrollDelta.dy.sign,
      );
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

    final captured = await PixelCapture.capture(repaintBoundaryKey);
    if (captured == null) return;

    if (_isDisposed || captureEpoch != _imageCaptureEpoch) {
      captured.image.dispose();
      return;
    }

    _image = captured.image;
    byteDataStateNotifier.value = captured.byteData;
  }

  Offset _extractShiftedOffset(Offset offset, BuildContext context) =>
      PixelCapture.globalToImagePx(
        boundaryKey: repaintBoundaryKey,
        globalOffset: offset,
        context: context,
      );

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
