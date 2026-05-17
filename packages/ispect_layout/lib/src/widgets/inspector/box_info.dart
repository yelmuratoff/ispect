import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ispect_layout/src/number_format.dart';
import 'package:ispect_layout/src/size_extension.dart';

/// Contains information about the currently selected [RenderBox].
///
/// [containerRect] may be [null].
class BoxInfo {
  BoxInfo({
    required this.targetRenderBox,
    this.containerRenderBox,
    this.overlayOffset = Offset.zero,
    this.hitTestPath = const <RenderBox>[],
  });

  factory BoxInfo.fromHitTestResults(
    Iterable<RenderBox> boxes, {
    Offset overlayOffset = Offset.zero,
    bool findContainer = false,
  }) {
    final hitTestPath = List<RenderBox>.unmodifiable(boxes);

    RenderBox targetRenderBox = boxes.first;
    RenderBox? containerRenderBox;

    // Returns true for render objects that carry meaningful visual/layout
    // information. Used to break ties when two boxes share the same size:
    // a meaningful type beats a plain proxy wrapper.
    bool isMeaningful(RenderBox box) =>
        box is RenderDecoratedBox ||
        box is RenderPhysicalShape ||
        box is RenderPhysicalModel ||
        box is RenderStack ||
        box is RenderFlex ||
        box is RenderWrap ||
        box is RenderParagraph ||
        box is RenderImage ||
        box is RenderEditable ||
        box is RenderOpacity ||
        box is RenderAnimatedOpacity ||
        box is RenderClipRect ||
        box is RenderClipRRect ||
        box is RenderClipRSuperellipse ||
        box is RenderClipOval ||
        box is RenderClipPath ||
        box is RenderCustomPaint ||
        box is RenderTransform ||
        box is RenderFittedBox ||
        box is RenderAspectRatio ||
        box is RenderBackdropFilter;

    for (final box in boxes) {
      if (box.size.isSmallerThan(targetRenderBox.size)) {
        targetRenderBox = box;
      } else if (box.size == targetRenderBox.size) {
        // On a tie, only update when the new box is meaningful:
        // non→non keeps the first hit (e.g. _RenderColoredBox before RenderPadding),
        // meaningful→non is skipped, and meaningful→meaningful prefers the innermost.
        if (isMeaningful(box)) targetRenderBox = box;
      }
    }

    if (findContainer) {
      // Precompute target's ancestor set once, so the descendant check is
      // O(1) per candidate instead of walking the parent chain each time
      // (previously O(n*depth), visible on deep trees).
      final ancestors = <RenderObject>{};
      for (RenderObject? node = targetRenderBox.parent;
          node != null;
          node = node.parent) {
        ancestors.add(node);
      }

      // The >= is used to check whether the item is fully contained by the other box.
      // The isGreaterThan is used to avoid selecting the same box as the target box.
      for (final box in boxes) {
        if (box.size >= targetRenderBox.size &&
            box.size.isGreaterThan(targetRenderBox.size)) {
          if ((containerRenderBox == null ||
                  box.size.isSmallerThan(containerRenderBox.size)) &&
              ancestors.contains(box)) {
            containerRenderBox = box;
          }
        }
      }
    }

    return BoxInfo(
      targetRenderBox: targetRenderBox,
      containerRenderBox: containerRenderBox,
      overlayOffset: overlayOffset,
      hitTestPath: hitTestPath,
    );
  }

  final RenderBox targetRenderBox;
  final RenderBox? containerRenderBox;

  final Offset overlayOffset;

  /// Render boxes found under the pointer during hit-testing, in traversal order.
  ///
  /// This is intentionally kept separate from [targetRenderBox] selection logic
  /// so UI panels can derive additional context (e.g., nearest decorated box).
  final List<RenderBox> hitTestPath;

  Rect get targetRect => getRectFromRenderBox(targetRenderBox)!;

  Rect get targetRectShifted => targetRect.shift(-overlayOffset);

  Rect? get containerRect => containerRenderBox != null
      ? getRectFromRenderBox(containerRenderBox!)
      : null;

  /// Calculate original padding by comparing positions in local coordinates
  EdgeInsets _calculateOriginalPadding() {
    if (containerRenderBox == null) return EdgeInsets.zero;

    // Get the target's position relative to the container
    final targetOffset = targetRenderBox.localToGlobal(Offset.zero);
    final containerOffset = containerRenderBox!.localToGlobal(Offset.zero);

    // Calculate scale factor from the transformation
    final scaledTargetSize = targetRect.size;
    final originalTargetSize = targetRenderBox.size;
    final scale = originalTargetSize.width > 0
        ? scaledTargetSize.width / originalTargetSize.width
        : 1.0;

    // Calculate padding in original coordinates
    final left = (targetOffset.dx - containerOffset.dx) / scale;
    final top = (targetOffset.dy - containerOffset.dy) / scale;
    final right =
        containerRenderBox!.size.width - originalTargetSize.width - left;
    final bottom =
        containerRenderBox!.size.height - originalTargetSize.height - top;

    // Snap sub-pixel floating-point noise to zero.
    double snap(double v) => v.abs() < 0.5 ? 0.0 : v;
    return EdgeInsets.fromLTRB(
        snap(left), snap(top), snap(right), snap(bottom));
  }

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

  /// Describes the original (logical) padding without zoom transformation.
  String describeOriginalPadding({int decimalPlaces = 1}) {
    final padding = _calculateOriginalPadding();

    return 'L:${formatInspectorDouble(padding.left, decimalPlaces: decimalPlaces)}'
        '  T:${formatInspectorDouble(padding.top, decimalPlaces: decimalPlaces)}'
        '  R:${formatInspectorDouble(padding.right, decimalPlaces: decimalPlaces)}'
        '  B:${formatInspectorDouble(padding.bottom, decimalPlaces: decimalPlaces)}';
  }

  /// True when the detected container is a flex layout (Row/Column).
  bool get isContainerFlex => containerRenderBox is RenderFlex;

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

  /// The nearest [RenderDecoratedBox] with [BoxDecoration] relevant to the
  /// selected target. Checks the target directly, then the hit-test path,
  /// then the target's direct child — in that priority order.
  RenderDecoratedBox? get decoratedBoxForDisplay =>
      _findSelectedDecoratedBox() ??
      _findNearestDecoratedBoxFromHitTestPath() ??
      _findChildDecoratedBoxFromTarget();

  RenderDecoratedBox? _findSelectedDecoratedBox() =>
      targetRenderBox is RenderDecoratedBox
          ? targetRenderBox as RenderDecoratedBox
          : null;

  RenderDecoratedBox? _findNearestDecoratedBoxFromHitTestPath() {
    for (final box in hitTestPath) {
      if (box.size != targetRenderBox.size) continue;
      if (box is RenderDecoratedBox) return box;
    }
    return null;
  }

  RenderDecoratedBox? _findChildDecoratedBoxFromTarget() {
    if (targetRenderBox is RenderProxyBoxMixin) {
      final child = (targetRenderBox as RenderProxyBoxMixin).child;
      if (child != null &&
          child.size == targetRenderBox.size &&
          child is RenderDecoratedBox) {
        return child;
      }
    }
    return null;
  }

  /// The fill color of a [ColoredBox] that is or wraps the target, if any.
  ///
  /// `_RenderColoredBox` is a private Flutter class, so dynamic dispatch on
  /// `.color` is used. Discrimination is done via [_coloredBoxRuntimeType] —
  /// see its declaration for the rationale.
  Color? get coloredBoxColor =>
      _tryColoredBoxColor(targetRenderBox) ??
      (targetRenderBox is RenderProxyBoxMixin
          ? _tryColoredBoxColorFromProxy(targetRenderBox as RenderProxyBoxMixin)
          : null);

  Color? _tryColoredBoxColorFromProxy(RenderProxyBoxMixin proxy) {
    final child = proxy.child;
    if (child is RenderBox && child.size == targetRenderBox.size) {
      return _tryColoredBoxColor(child);
    }
    return null;
  }

  Color? _tryColoredBoxColor(RenderBox box) {
    if (box.runtimeType != _coloredBoxRuntimeType) return null;
    try {
      return (box as dynamic).color as Color;
    } catch (_) {
      return null;
    }
  }
}

/// Captures `_RenderColoredBox`'s runtime [Type] without referencing its
/// private name. We construct a [ColoredBox] widget and call its
/// `createRenderObject` directly — Flutter's implementation ignores the
/// passed [BuildContext], so a `noSuchMethod` stub is sufficient.
/// Returns `null` if Flutter ever changes that contract; the caller then
/// gracefully degrades and the [ColoredBox] color simply isn't surfaced.
final Type? _coloredBoxRuntimeType = (() {
  try {
    return const ColoredBox(color: Color(0x00000000))
        .createRenderObject(_NoopBuildContext())
        .runtimeType;
  } catch (_) {
    return null;
  }
})();

class _NoopBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Rect? getRectFromRenderBox(RenderBox renderBox) {
  if (!renderBox.attached) return null;

  final topLeft = renderBox.localToGlobal(Offset.zero);
  final bottomRight = renderBox.localToGlobal(
    Offset(renderBox.size.width, renderBox.size.height),
  );

  return Rect.fromPoints(topLeft, bottomRight);
}

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
