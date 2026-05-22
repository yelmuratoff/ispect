import 'dart:math' as math;

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
    for (final box in boxes) {
      if (box.size.isSmallerThan(targetRenderBox.size)) {
        targetRenderBox = box;
      } else if (box.size == targetRenderBox.size) {
        if (_isStronglyMeaningfulRenderBox(box)) targetRenderBox = box;
      }
    }

    return BoxInfo(
      targetRenderBox: targetRenderBox,
      containerRenderBox: findContainer
          ? _findContainerFor(hitTestPath, targetRenderBox)
          : null,
      overlayOffset: overlayOffset,
      hitTestPath: hitTestPath,
    );
  }

  /// Returns a new [BoxInfo] with [newTarget] as the selected render box,
  /// preserving the original hit-test path and overlay offset. The container
  /// is recomputed against the new target. Used by the breadcrumb to let the
  /// user pick any ancestor from the hit-test path (Row/Column/Stack/Padding)
  /// without re-running pointer detection.
  BoxInfo withTarget(RenderBox newTarget) => BoxInfo(
        targetRenderBox: newTarget,
        containerRenderBox: _findContainerFor(hitTestPath, newTarget),
        overlayOffset: overlayOffset,
        hitTestPath: hitTestPath,
      );

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

  /// Hit-test path filtered to render boxes worth surfacing as breadcrumb
  /// entries (visual/layout-shaping types only — proxy wrappers like
  /// [RenderRepaintBoundary] or `_RenderInkFeatures` are dropped).
  ///
  /// Consecutive entries that share a [Size] are collapsed to a single chip;
  /// the innermost wins, with a tie-break that prefers strongly meaningful
  /// boxes (e.g. [RenderDecoratedBox]) over layout helpers (e.g.
  /// [RenderPadding]). Returned in outer→inner order.
  List<RenderBox> get meaningfulPath {
    final result = <RenderBox>[];
    for (final box in hitTestPath) {
      final isStrong = _isStronglyMeaningfulRenderBox(box);
      final isHelper = _isLayoutHelperRenderBox(box);
      final isTarget = identical(box, targetRenderBox);
      if (!isStrong && !isHelper && !isTarget) continue;

      if (result.isNotEmpty && result.last.size == box.size) {
        final prev = result.last;
        if (identical(prev, targetRenderBox)) continue;
        final prevStrong = _isStronglyMeaningfulRenderBox(prev);
        if (isTarget || isStrong || !prevStrong) {
          result[result.length - 1] = box;
        }
      } else {
        result.add(box);
      }
    }
    return result;
  }

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

  /// The original (logical) padding between the container and target render boxes.
  EdgeInsets get originalPadding => _calculateOriginalPadding();

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

/// Render objects that carry meaningful visual/layout information. Used to
/// break selection ties when two boxes share the same size: a meaningful type
/// beats a plain proxy wrapper. Also drives the breadcrumb path filter.
bool _isStronglyMeaningfulRenderBox(RenderBox box) =>
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

/// Layout-only wrappers that don't paint anything but shape the layout. They
/// are the answer to "why is my widget positioned/sized like this?" and so
/// belong in the breadcrumb even though they are not strongly meaningful.
bool _isLayoutHelperRenderBox(RenderBox box) =>
    box is RenderPadding ||
    box is RenderConstrainedBox ||
    box is RenderPositionedBox;

/// Walks the parent chain of [target] to build an ancestor set, then picks
/// the smallest box in [hitTestPath] that strictly contains the target and
/// is one of its ancestors. Mirrors the original inline logic from
/// [BoxInfo.fromHitTestResults] so [BoxInfo.withTarget] can recompute the
/// container on demand.
RenderBox? _findContainerFor(List<RenderBox> hitTestPath, RenderBox target) {
  final ancestors = <RenderObject>{};
  for (RenderObject? node = target.parent; node != null; node = node.parent) {
    ancestors.add(node);
  }

  RenderBox? container;
  for (final box in hitTestPath) {
    if (box.size >= target.size && box.size.isGreaterThan(target.size)) {
      if ((container == null || box.size.isSmallerThan(container.size)) &&
          ancestors.contains(box)) {
        container = box;
      }
    }
  }
  return container;
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

  final w = renderBox.size.width;
  final h = renderBox.size.height;
  final tl = renderBox.localToGlobal(Offset.zero);
  final tr = renderBox.localToGlobal(Offset(w, 0));
  final bl = renderBox.localToGlobal(Offset(0, h));
  final br = renderBox.localToGlobal(Offset(w, h));

  final minX = math.min(math.min(tl.dx, tr.dx), math.min(bl.dx, br.dx));
  final maxX = math.max(math.max(tl.dx, tr.dx), math.max(bl.dx, br.dx));
  final minY = math.min(math.min(tl.dy, tr.dy), math.min(bl.dy, br.dy));
  final maxY = math.max(math.max(tl.dy, tr.dy), math.max(bl.dy, br.dy));

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

double calculateBoxPosition({
  required Rect rect,
  required double height,
  double padding = 8.0,
}) {
  final aboveTopEdge = rect.top - padding - height;
  final insideTopEdge = rect.top + padding;

  // Prefer above the widget so the label never overlaps the content.
  if (aboveTopEdge >= padding) return aboveTopEdge;
  // Fall back to inside-at-top when there's no room above.
  return insideTopEdge;
}
