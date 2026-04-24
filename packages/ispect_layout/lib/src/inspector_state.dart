import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'widgets/inspector/box_info.dart';

/// Consolidated inspector state — exposed as a single observable surface
/// alongside the individual legacy [ValueNotifier]s on [InspectorController].
///
/// Use this when you want `switch`-exhaustive handling for free:
/// ```dart
/// ValueListenableBuilder<InspectorUiState>(
///   valueListenable: controller.stateNotifier,
///   builder: (_, state, __) => switch (state) {
///     InspectorIdleState()       => const SizedBox.shrink(),
///     InspectorInspectState s    => _buildInspect(s),
///     InspectorColorPickerState s=> _buildPicker(s),
///     InspectorZoomState s       => _buildZoom(s),
///   },
/// );
/// ```
///
/// The legacy notifiers (`currentRenderBoxNotifier`, `hoveredRenderBoxNotifier`,
/// ...) remain the mutation surface — internal logic continues to write into
/// them, and the sealed state is recomputed on each change.
sealed class InspectorUiState {
  const InspectorUiState();
}

/// Inspector is off — no selection, no overlays, no color picker, no zoom.
class InspectorIdleState extends InspectorUiState {
  const InspectorIdleState();

  @override
  bool operator ==(Object other) => other is InspectorIdleState;

  @override
  int get hashCode => 0;
}

/// Widget inspection is active. [selected] is the locked-in target;
/// [hovered] tracks pointer movement; [compared] and [comparing] capture
/// the compare-mode sub-state.
@immutable
class InspectorInspectState extends InspectorUiState {
  const InspectorInspectState({
    this.selected,
    this.hovered,
    this.compared,
    this.comparing = false,
  });

  final BoxInfo? selected;
  final BoxInfo? hovered;
  final BoxInfo? compared;

  /// True while the user is picking the second widget (compareSelect mode).
  final bool comparing;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectorInspectState &&
          selected == other.selected &&
          hovered == other.hovered &&
          compared == other.compared &&
          comparing == other.comparing;

  @override
  int get hashCode => Object.hash(selected, hovered, compared, comparing);
}

/// Color picker is active; [pickedColor] tracks the current pointer pixel.
/// [image]/[byteData] may be null while the frame capture is still pending.
@immutable
class InspectorColorPickerState extends InspectorUiState {
  const InspectorColorPickerState({
    this.image,
    this.byteData,
    this.pointerOffset,
    this.imageOffset,
    this.pickedColor,
  });

  final ui.Image? image;
  final ByteData? byteData;
  final Offset? pointerOffset;
  final Offset? imageOffset;
  final Color? pickedColor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectorColorPickerState &&
          image == other.image &&
          byteData == other.byteData &&
          pointerOffset == other.pointerOffset &&
          imageOffset == other.imageOffset &&
          pickedColor == other.pickedColor;

  @override
  int get hashCode =>
      Object.hash(image, byteData, pointerOffset, imageOffset, pickedColor);
}

/// Zoom loupe is active. [image]/[byteData] may be null while the frame
/// capture is still pending.
@immutable
class InspectorZoomState extends InspectorUiState {
  const InspectorZoomState({
    this.image,
    this.byteData,
    this.pointerOffset,
    this.imageOffset,
    this.scale = 2.0,
  });

  final ui.Image? image;
  final ByteData? byteData;
  final Offset? pointerOffset;
  final Offset? imageOffset;
  final double scale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InspectorZoomState &&
          image == other.image &&
          byteData == other.byteData &&
          pointerOffset == other.pointerOffset &&
          imageOffset == other.imageOffset &&
          scale == other.scale;

  @override
  int get hashCode =>
      Object.hash(image, byteData, pointerOffset, imageOffset, scale);
}
