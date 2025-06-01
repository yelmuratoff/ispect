import 'package:flutter/rendering.dart';

/// Contains information about the currently selected `RenderBox`.
///
/// `containerRect` may be `null`.
class BoxInfo {
  const BoxInfo({
    required this.targetRenderBox,
    this.containerRenderBox,
    this.overlayOffset = Offset.zero,
    this.decorationRenderBox,
  });

  factory BoxInfo.fromHitTestResults(
    Iterable<RenderBox> boxes, {
    Offset overlayOffset = Offset.zero,
  }) {
    RenderBox? targetRenderBox;
    RenderBox? containerRenderBox;
    RenderDecoratedBox? decorationRenderBox;

    for (final box in boxes) {
      targetRenderBox ??= box;
      if (targetRenderBox.size < box.size) {
        containerRenderBox = box;
        break;
      }
    }

    decorationRenderBox = boxes.firstWhere(
      (box) => box is RenderDecoratedBox && (box.decoration is BoxDecoration),
      orElse: () => RenderDecoratedBox(
        decoration: const BoxDecoration(),
      ),
    ) as RenderDecoratedBox?;

    return BoxInfo(
      targetRenderBox: targetRenderBox!,
      containerRenderBox: containerRenderBox,
      overlayOffset: overlayOffset,
      decorationRenderBox: decorationRenderBox,
    );
  }

  final RenderBox targetRenderBox;
  final RenderBox? containerRenderBox;
  final Offset overlayOffset;
  final RenderDecoratedBox? decorationRenderBox;

  // --- Decoration logic ---

  BoxDecoration? get boxDecoration =>
      decorationRenderBox?.decoration is BoxDecoration
          ? decorationRenderBox!.decoration as BoxDecoration
          : null;

  Decoration? get decoration => decorationRenderBox?.decoration;

  // --- Padding/margin logic (unchanged) ---
  Rect get targetRect => getRectFromRenderBox(targetRenderBox)!;
  Rect get targetRectShifted => targetRect.shift(-overlayOffset);

  Rect? get containerRect => containerRenderBox != null
      ? getRectFromRenderBox(containerRenderBox!)
      : null;

  Rect get containerRectShifted => targetRect.shift(-overlayOffset);

  double? get paddingLeft => paddingRectLeft?.width;
  double? get paddingRight => paddingRectRight?.width;
  double? get paddingTop => paddingRectTop?.height;
  double? get paddingBottom => paddingRectBottom?.height;

  Rect? get paddingRectLeft => containerRect != null
      ? Rect.fromLTRB(
          containerRect!.left,
          containerRect!.top,
          targetRect.left,
          containerRect!.bottom,
        )
      : null;

  Rect? get paddingRectTop => containerRect != null
      ? Rect.fromLTRB(
          targetRect.left,
          containerRect!.top,
          targetRect.right,
          targetRect.top,
        )
      : null;

  Rect? get paddingRectRight => containerRect != null
      ? Rect.fromLTRB(
          targetRect.right,
          containerRect!.top,
          containerRect!.right,
          containerRect!.bottom,
        )
      : null;

  Rect? get paddingRectBottom => containerRect != null
      ? Rect.fromLTRB(
          targetRect.left,
          targetRect.bottom,
          targetRect.right,
          containerRect!.bottom,
        )
      : null;

  String describePadding() {
    assert(containerRect != null);

    final left = paddingLeft!.toStringAsFixed(1);
    final top = paddingTop!.toStringAsFixed(1);
    final right = paddingRight!.toStringAsFixed(1);
    final bottom = paddingBottom!.toStringAsFixed(1);

    return '$left, $top, $right, $bottom';
  }

  // --- BoxDecoration info getters ---
  Color? getDecoratedBoxColor() => boxDecoration?.color;
  BorderRadiusGeometry? getDecoratedBoxBorderRadius() =>
      boxDecoration?.borderRadius;
  BoxBorder? getDecoratedBoxBorder() => boxDecoration?.border;
  BoxShape? getDecoratedBoxShape() => boxDecoration?.shape;
  List<BoxShadow>? getDecoratedBoxShadow() => boxDecoration?.boxShadow;
  Gradient? getDecoratedBoxGradient() => boxDecoration?.gradient;
  BlendMode? getDecoratedBoxBackgroundBlendMode() =>
      boxDecoration?.backgroundBlendMode;
  DecorationImage? getDecoratedBoxImage() => boxDecoration?.image;

  Map<String, dynamic>? getBoxDecorationInfo() {
    final decoration = boxDecoration;
    if (decoration == null) return null;
    return {
      'color': decoration.color,
      'borderRadius': decoration.borderRadius,
      'border': decoration.border,
      'shape': decoration.shape,
      'boxShadow': decoration.boxShadow,
      'gradient': decoration.gradient,
      'backgroundBlendMode': decoration.backgroundBlendMode,
      'image': decoration.image,
    };
  }

  Map<String, dynamic>? getDecorationInfo() {
    final dec = decoration;
    if (dec == null) return null;
    if (dec is BoxDecoration) {
      return getBoxDecorationInfo();
    }
    return {
      'type': dec.runtimeType.toString(),
    };
  }
}

Rect? getRectFromRenderBox(RenderBox renderBox) => renderBox.attached
    ? (renderBox.localToGlobal(Offset.zero)) & renderBox.size
    : null;

double calculateBoxPosition({
  required Rect rect,
  required double height,
  double padding = 8.0,
}) {
  final preferredHeight = height;

  // Position when the overlay is placed inside the container
  final insideTopEdge = rect.top + padding;
  final insideBottomEdge = rect.bottom - padding - preferredHeight;

  // Position when the overlay is placed above the container
  final aboveTopEdge = rect.top - padding - preferredHeight;

  // Position when the overlay is placed below the container
  final belowTopEdge = rect.bottom + padding;

  final minHeightToBeInsideContainer = (height + padding) * 2;

  final isInsideContainer = rect.height > minHeightToBeInsideContainer;

  if (isInsideContainer) {
    return (insideTopEdge >= padding) ? insideTopEdge : insideBottomEdge;
  } else {
    return (aboveTopEdge > padding) ? aboveTopEdge : belowTopEdge;
  }
}
