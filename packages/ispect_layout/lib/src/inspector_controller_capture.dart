part of 'inspector_controller.dart';

const double _initialZoomScale = 4.0;
const double _minZoomScale = 1.0;
const double _maxZoomScale = 20.0;
const double _zoomStep = 1.0;

extension InspectorControllerCapture on InspectorController {
  double get minZoomScale => _minZoomScale;
  double get maxZoomScale => _maxZoomScale;

  void zoomIn() => _setZoomScale(zoomScaleNotifier.value + _zoomStep);

  void zoomOut() => _setZoomScale(zoomScaleNotifier.value - _zoomStep);

  void _setZoomScale(double next) {
    final clamped = next.clamp(_minZoomScale, _maxZoomScale);
    if (clamped == zoomScaleNotifier.value) return;
    zoomScaleNotifier.value = clamped;
  }

  void _cleanupImage() {
    _imageCaptureEpoch++;
    _image?.dispose();
    _image = null;
    if (_isDisposed) return;
    byteDataStateNotifier.value = null;
  }

  /// Drops the cached pixel snapshot and re-captures it on the next frame
  /// while the user stays in [InspectorMode.colorPicker] / [InspectorMode.zoom].
  ///
  /// Called when the surface the snapshot was taken from changes size or
  /// layout (window resize on desktop / web, orientation change, side panels
  /// opening). Without this the loupe keeps showing stale pixels at stale
  /// positions and the picker effectively desyncs from the live UI.
  void invalidateCapturedImage() {
    final mode = modeNotifier.value;
    if (mode != InspectorMode.colorPicker && mode != InspectorMode.zoom) {
      return;
    }
    _cleanupImage();
    final captureEpoch = ++_imageCaptureEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _extractByteData(captureEpoch);
      if (_isDisposed || captureEpoch != _imageCaptureEpoch) return;
      if (_pointerHoverPosition == null || stackKey.currentContext == null) {
        return;
      }
      switch (modeNotifier.value) {
        case InspectorMode.zoom:
          _onZoomHover(_pointerHoverPosition!, stackKey.currentContext!);
          break;
        case InspectorMode.colorPicker:
          _onColorPickerHover(_pointerHoverPosition!, stackKey.currentContext!);
          break;
        case InspectorMode.none:
        case InspectorMode.inspector:
        case InspectorMode.inspectAndCompare:
        case InspectorMode.compareSelect:
          break;
      }
    });
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
