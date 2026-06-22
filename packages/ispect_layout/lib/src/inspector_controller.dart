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

part 'inspector_controller_modes.dart';
part 'inspector_controller_shortcuts.dart';
part 'inspector_controller_pointer.dart';
part 'inspector_controller_capture.dart';

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

  /// Consolidated sealed-state view. Updated automatically whenever any of
  /// the legacy granular notifiers changes. Exists alongside the legacy
  /// notifiers for callers who prefer exhaustive `switch`.
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

  /// Shortcut configuration + accept/isPressed logic. Forwarding accessors
  /// live in `inspector_controller_shortcuts.dart`.
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
}
