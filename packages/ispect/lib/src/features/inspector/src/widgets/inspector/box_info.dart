import 'package:flutter/rendering.dart';

/// Contains information about the currently selected [RenderBox].
///
/// [containerRect] may be [null].
class BoxInfo {
  BoxInfo({
    required this.targetRenderBox,
    this.containerRenderBox,
    this.overlayOffset = Offset.zero,
  });

  factory BoxInfo.fromHitTestResults(
    Iterable<RenderBox> boxes, {
    Offset overlayOffset = Offset.zero,
  }) {
    RenderBox? targetRenderBox;
    RenderBox? containerRenderBox;

    for (final box in boxes) {
      targetRenderBox ??= box;

      if (targetRenderBox.size < box.size) {
        containerRenderBox = box;
        break;
      }
    }

    return BoxInfo(
      targetRenderBox: targetRenderBox!,
      containerRenderBox: containerRenderBox,
      overlayOffset: overlayOffset,
    );
  }

  final RenderBox targetRenderBox;
  final RenderBox? containerRenderBox;

  final Offset overlayOffset;

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

  bool get isDecoratedBox =>
      targetRenderBox is RenderDecoratedBox &&
      (targetRenderBox as RenderDecoratedBox).decoration is BoxDecoration;

  BoxDecoration get _decoration =>
      (targetRenderBox as RenderDecoratedBox).decoration as BoxDecoration;

  Color? getDecoratedBoxColor() {
    assert(isDecoratedBox);
    return _decoration.color;
  }

  BorderRadiusGeometry? getDecoratedBoxBorderRadius() {
    assert(isDecoratedBox);
    return _decoration.borderRadius;
  }

  /// Gets detailed properties of the target RenderBox
  ///
  /// - Return: Map of property names to their string representations
  /// - Usage: Programmatic access to widget properties for custom analysis
  Map<String, String> getProperties() {
    final properties = <String, String>{};

    // Basic properties
    properties['type'] = targetRenderBox.runtimeType.toString();
    properties['size'] = targetRenderBox.size.toString();
    properties['hasSize'] = targetRenderBox.hasSize.toString();
    properties['attached'] = targetRenderBox.attached.toString();

    if (targetRenderBox.hasSize) {
      properties['constraints'] = targetRenderBox.constraints.toString();
    }

    if (targetRenderBox.attached) {
      try {
        final position = targetRenderBox.localToGlobal(Offset.zero);
        properties['globalPosition'] = position.toString();
      } catch (e) {
        properties['globalPosition'] = 'Unable to calculate';
      }
    }

    // Container properties if available
    if (containerRenderBox != null) {
      properties['containerType'] = containerRenderBox!.runtimeType.toString();
      properties['containerSize'] = containerRenderBox!.size.toString();
      properties['padding'] = describePadding();
    }

    // Decoration properties
    if (isDecoratedBox) {
      final color = getDecoratedBoxColor();
      if (color != null) {
        properties['decorationColor'] = color.toString();
      }

      final borderRadius = getDecoratedBoxBorderRadius();
      if (borderRadius != null) {
        properties['borderRadius'] = borderRadius.toString();
      }
    }

    return properties;
  }

  /// Gets a human-readable summary of the widget
  ///
  /// - Return: Brief, one-line description of the widget
  /// - Usage: Quick identification of widgets in lists or logs
  String getSummary() {
    final type = targetRenderBox.runtimeType.toString();
    final size = targetRenderBox.size;

    final parts = <String>[type];

    if (targetRenderBox.hasSize) {
      parts.add(
        '${size.width.toStringAsFixed(1)}×${size.height.toStringAsFixed(1)}',
      );
    }

    if (isDecoratedBox) {
      final color = getDecoratedBoxColor();
      if (color != null) {
        parts.add('color: $color');
      }
    }

    return parts.join(' ');
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
    return (insideTopEdge > padding) ? insideTopEdge : insideBottomEdge;
  } else {
    return (aboveTopEdge > padding) ? aboveTopEdge : belowTopEdge;
  }
}
