part of 'inspector_controller.dart';

enum InspectorMode {
  none,
  inspector,
  inspectAndCompare,
  compareSelect,
  colorPicker,
  zoom,
}

extension InspectorControllerModes on InspectorController {
  void handleInspectorShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.inspector);

  void handleCompareShortcut() =>
      _toggleMode(true, InspectorMode.inspectAndCompare);

  void handleColorPickerShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.colorPicker);

  void handleZoomShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.zoom);

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
  /// Zoom: nothing to commit, so this just exits the mode.
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

  void cancelCurrentMode() {
    setMode(InspectorMode.none);
  }

  void setMode(InspectorMode mode, {BuildContext? context}) {
    if (mode == modeNotifier.value) return;

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

    _cleanupMode(modeNotifier.value, mode, context);
    modeNotifier.value = mode;
    _setupMode(mode);
  }

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
        // Snackbar surfaces only via confirmCurrentSelection — closing the
        // mode through cancel / panel toggle should not commit anything.
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
}
