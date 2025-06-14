import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/inspector/src/utils.dart';

/// Contains information about the currently selected [RenderBox].
///
/// Provides access to target and container render boxes with computed
/// rectangles, padding information, and decoration properties.
/// Used for widget inspection and overlay positioning.
///
/// - Parameters:
///   - [targetRenderBox]: The primary render box being inspected
///   - [containerRenderBox]: Optional parent container for padding calculations
///   - [overlayOffset]: Offset for positioning overlays relative to screen
///   - [boxes]: All render boxes found during hit testing
///   - [elements]: Associated widget elements for inspection
/// - Usage: Created from hit test results during widget inspection
/// - Edge cases: [containerRect] may be null if no container is found
class BoxInfo {
  const BoxInfo({
    required this.targetRenderBox,
    this.containerRenderBox,
    this.overlayOffset = Offset.zero,
    this.boxes = const [],
    this.elements = const [],
  });

  /// Creates BoxInfo from hit test results
  ///
  /// Finds the smallest render box as target and largest as container.
  /// Collects associated elements for widget inspection.
  ///
  /// - Parameters:
  ///   - [boxes]: Render boxes from hit test, ordered by depth
  ///   - [overlayOffset]: Global offset for overlay positioning
  /// - Return: BoxInfo with target/container boxes and elements
  /// - Edge cases: Returns null target if boxes is empty (assertion will fail)
  factory BoxInfo.fromHitTestResults(
    Iterable<RenderBox> boxes, {
    Offset overlayOffset = Offset.zero,
  }) {
    RenderBox? targetRenderBox;
    RenderBox? containerRenderBox;
    final elements = <Element>[];

    for (final box in boxes) {
      targetRenderBox ??= box;
      final tempElement = InspectorUtils.getElementFromRenderBox(box);
      if (tempElement != null) {
        elements.add(tempElement);
      }

      if (targetRenderBox.size < box.size) {
        containerRenderBox = box;
        break;
      }
    }

    return BoxInfo(
      targetRenderBox: targetRenderBox!,
      containerRenderBox: containerRenderBox,
      overlayOffset: overlayOffset,
      boxes: boxes.toList(growable: false),
      elements: elements,
    );
  }

  final RenderBox targetRenderBox;
  final RenderBox? containerRenderBox;
  final Offset overlayOffset;
  final List<RenderBox> boxes;
  final List<Element> elements;

  /// Global rectangle of the target render box
  Rect get targetRect => getRectFromRenderBox(targetRenderBox)!;

  /// Target rectangle shifted by overlay offset for positioning
  Rect get targetRectShifted => targetRect.shift(-overlayOffset);

  /// Global rectangle of the container render box, if available
  Rect? get containerRect => containerRenderBox != null
      ? getRectFromRenderBox(containerRenderBox!)
      : null;

  /// Container rectangle shifted by overlay offset for positioning
  Rect? get containerRectShifted => containerRect?.shift(-overlayOffset);

  // Padding calculations - optimized for performance and null safety
  double? get paddingLeft => _computePaddingLeft();
  double? get paddingRight => _computePaddingRight();
  double? get paddingTop => _computePaddingTop();
  double? get paddingBottom => _computePaddingBottom();

  /// Padding rectangles for visual overlay rendering
  Rect? get paddingRectLeft => _buildPaddingRect(_PaddingSide.left);
  Rect? get paddingRectTop => _buildPaddingRect(_PaddingSide.top);
  Rect? get paddingRectRight => _buildPaddingRect(_PaddingSide.right);
  Rect? get paddingRectBottom => _buildPaddingRect(_PaddingSide.bottom);

  /// Describes padding in CSS-like format: "left, top, right, bottom"
  ///
  /// - Return: Formatted string with 1 decimal place precision
  /// - Usage: For debugging and UI display
  /// - Edge cases: Asserts that containerRect is not null
  String describePadding() {
    assert(containerRect != null, 'Container rect must not be null');

    final left = paddingLeft!.toStringAsFixed(1);
    final top = paddingTop!.toStringAsFixed(1);
    final right = paddingRight!.toStringAsFixed(1);
    final bottom = paddingBottom!.toStringAsFixed(1);

    return '$left, $top, $right, $bottom';
  }

  /// Whether the target render box is a decorated box with BoxDecoration
  bool get isDecoratedBox =>
      targetRenderBox is RenderDecoratedBox &&
      (targetRenderBox as RenderDecoratedBox).decoration is BoxDecoration;

  /// Gets the decoration color if available
  ///
  /// - Return: Color from BoxDecoration, or null if not available
  /// - Usage: For color picker and inspection tools
  /// - Edge cases: Asserts that render box is a decorated box
  Color? getDecoratedBoxColor() {
    assert(isDecoratedBox, 'Target must be a decorated box');
    return _boxDecoration?.color;
  }

  /// Gets the border radius if available
  ///
  /// - Return: BorderRadiusGeometry from BoxDecoration, or null
  /// - Usage: For visual inspection and overlay rendering
  /// - Edge cases: Asserts that render box is a decorated box
  BorderRadiusGeometry? getDecoratedBoxBorderRadius() {
    assert(isDecoratedBox, 'Target must be a decorated box');
    return _boxDecoration?.borderRadius;
  }

  // Private helpers for optimized calculations

  BoxDecoration? get _boxDecoration => isDecoratedBox
      ? (targetRenderBox as RenderDecoratedBox).decoration as BoxDecoration?
      : null;

  double? _computePaddingLeft() {
    final container = containerRect;
    return container != null ? targetRect.left - container.left : null;
  }

  double? _computePaddingRight() {
    final container = containerRect;
    return container != null ? container.right - targetRect.right : null;
  }

  double? _computePaddingTop() {
    final container = containerRect;
    return container != null ? targetRect.top - container.top : null;
  }

  double? _computePaddingBottom() {
    final container = containerRect;
    return container != null ? container.bottom - targetRect.bottom : null;
  }

  Rect? _buildPaddingRect(_PaddingSide side) {
    final container = containerRect;
    if (container == null) return null;

    final target = targetRect;

    return switch (side) {
      _PaddingSide.left => Rect.fromLTRB(
          container.left,
          container.top,
          target.left,
          container.bottom,
        ),
      _PaddingSide.top => Rect.fromLTRB(
          target.left,
          container.top,
          target.right,
          target.top,
        ),
      _PaddingSide.right => Rect.fromLTRB(
          target.right,
          container.top,
          container.right,
          container.bottom,
        ),
      _PaddingSide.bottom => Rect.fromLTRB(
          target.left,
          target.bottom,
          target.right,
          container.bottom,
        ),
    };
  }
}

/// Internal enum for padding side calculations
enum _PaddingSide { left, top, right, bottom }

/// Calculates the global rectangle for a render box
///
/// - Parameters:
///   - [renderBox]: The render box to get rectangle from
/// - Return: Global Rect if attached, null if detached
/// - Usage: Used for positioning overlays and calculating bounds
/// - Edge cases: Returns null if render box is not attached to render tree
Rect? getRectFromRenderBox(RenderBox renderBox) => renderBox.attached
    ? renderBox.localToGlobal(Offset.zero) & renderBox.size
    : null;

/// Calculates optimal vertical position for overlay boxes
///
/// Determines whether to place overlay inside, above, or below the target rect
/// based on available space and minimum height requirements.
///
/// - Parameters:
///   - [rect]: Target rectangle to position overlay relative to
///   - [height]: Required height of the overlay content
///   - [padding]: Minimum padding around overlay (default: 8.0)
/// - Return: Optimal top position for overlay
/// - Usage: Used by overlay widgets to avoid screen edge clipping
/// - Edge cases: Handles small containers and screen boundaries gracefully
double calculateBoxPosition({
  required Rect rect,
  required double height,
  double padding = 8.0,
}) {
  // Pre-calculate position options for performance
  final insideTopEdge = rect.top + padding;
  final insideBottomEdge = rect.bottom - padding - height;
  final aboveTopEdge = rect.top - padding - height;
  final belowTopEdge = rect.bottom + padding;

  // Determine if container is large enough for internal positioning
  final minHeightForInternalPlacement = (height + padding) * 2;
  final canFitInside = rect.height > minHeightForInternalPlacement;

  if (canFitInside) {
    // Prefer top-aligned inside, fallback to bottom-aligned inside
    return (insideTopEdge > padding) ? insideTopEdge : insideBottomEdge;
  } else {
    // Prefer above container, fallback to below container
    return (aboveTopEdge > padding) ? aboveTopEdge : belowTopEdge;
  }
}
