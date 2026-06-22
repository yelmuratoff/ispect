part of 'inspector_controller.dart';

extension InspectorControllerPointer on InspectorController {
  void onTap(Offset? pointerOffset, BuildContext context) {
    final mode = modeNotifier.value;
    if (mode == InspectorMode.none) return;

    if (mode == InspectorMode.colorPicker) {
      final sampleOffset = _pointerHoverPosition ?? pointerOffset;
      if (sampleOffset != null) {
        _onColorPickerHover(sampleOffset, context);
      }
      if (selectedColorStateNotifier.value != null) {
        HapticFeedback.selectionClick();
      }
      return;
    }

    if (mode == InspectorMode.zoom) {
      final sampleOffset = _pointerHoverPosition ?? pointerOffset;
      if (sampleOffset != null) {
        final ctx = stackKey.currentContext ?? context;
        _onZoomHover(sampleOffset, ctx);
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

  void onPointerExit(Offset pointerOffset) {
    hoveredRenderBoxNotifier.value = null;
  }

  /// Replaces the current selection with [newTarget], which must be present
  /// in the active hit-test path. No-op when no selection is active, when
  /// the target is not on the path, or when the render box has detached
  /// (e.g. after navigation). Powers the breadcrumb in the inspector panel.
  void selectFromPath(RenderBox newTarget) {
    final current = currentRenderBoxNotifier.value;
    if (current == null) return;
    if (!newTarget.attached) return;
    if (!current.hitTestPath.contains(newTarget)) return;
    if (identical(current.targetRenderBox, newTarget)) return;
    hoveredRenderBoxNotifier.value = null;
    currentRenderBoxNotifier.value = current.withTarget(newTarget);
  }

  void onPointerScroll(PointerScrollEvent scrollEvent) {
    if (modeNotifier.value == InspectorMode.zoom) {
      _setZoomScale(
        zoomScaleNotifier.value + _zoomStep * -scrollEvent.scrollDelta.dy.sign,
      );
    }
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
}
