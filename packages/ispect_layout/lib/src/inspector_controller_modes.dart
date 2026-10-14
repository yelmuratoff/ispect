part of 'inspector_controller.dart';

enum InspectorMode {
  none,
  inspector,
  @Deprecated(
    'Use enterCompareMode(), which selects InspectorMode.compareSelect. '
    'Will be removed in 8.0.0.',
  )
  inspectAndCompare,
  compareSelect,
  colorPicker,
  zoom;

  bool get isInspecting => switch (this) {
    InspectorMode.inspector ||
    // ignore: deprecated_member_use_from_same_package
    InspectorMode.inspectAndCompare ||
    InspectorMode.compareSelect => true,
    InspectorMode.none ||
    InspectorMode.colorPicker ||
    InspectorMode.zoom => false,
  };
}

extension InspectorControllerModes on InspectorController {
  void handleInspectorShortcut(bool isPressed) =>
      _toggleMode(isPressed, InspectorMode.inspector);

  void handleCompareShortcut() {
    if (modeNotifier.value == InspectorMode.compareSelect) {
      exitCompareMode();
    } else {
      enterCompareMode();
    }
  }

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
    if (!isEnabled) return;
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
    if (!isEnabled) return;
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
    if (!isEnabled) return;
    if (mode == modeNotifier.value) return;

    switch (mode) {
      case InspectorMode.inspector:
        if (!isWidgetInspectorEnabled) return;
        break;
      // ignore: deprecated_member_use_from_same_package
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

    _hoverHandledThisFrame = false;
    _pendingHover = null;
    _batchStateUpdates(() {
      _cleanupMode(modeNotifier.value, mode, context);
      modeNotifier.value = mode;
      _setupMode(mode);
    });
  }

  void _toggleMode(bool enable, InspectorMode targetMode) {
    if (enable) {
      setMode(targetMode);
    } else if (modeNotifier.value == targetMode) {
      setMode(InspectorMode.none);
    }
  }

  void _cleanupMode(
    InspectorMode oldMode,
    InspectorMode newMode,
    BuildContext? context,
  ) {
    switch (oldMode) {
      case InspectorMode.inspector:
      // ignore: deprecated_member_use_from_same_package
      case InspectorMode.inspectAndCompare:
      case InspectorMode.compareSelect:
        if (!newMode.isInspecting) {
          currentRenderBoxNotifier.value = null;
          hoveredRenderBoxNotifier.value = null;
          comparedRenderBoxNotifier.value = null;
        } else {
          hoveredRenderBoxNotifier.value = null;
          comparedRenderBoxNotifier.value = null;
        }
        break;
      case InspectorMode.colorPicker:
        // Snackbar surfaces only via confirmCurrentSelection - closing the
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
      // ignore: deprecated_member_use_from_same_package
      case InspectorMode.inspectAndCompare:
      case InspectorMode.compareSelect:
        break;
      case InspectorMode.colorPicker:
        final captureEpoch = ++_imageCaptureEpoch;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _resampleAfterCapture(captureEpoch),
        );
        break;
      case InspectorMode.zoom:
        final captureEpoch = ++_imageCaptureEpoch;
        zoomScaleNotifier.value = _initialZoomScale;
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _resampleAfterCapture(captureEpoch),
        );
        break;
      case InspectorMode.none:
        break;
    }
  }
}
