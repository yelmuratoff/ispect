import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class InspectorUtils {
  /// Returns the [RenderBox]es under [pointerOffset] (global coordinates),
  /// ordered outermost → innermost, as Flutter's pointer-routing pipeline
  /// would visit them.
  ///
  static List<RenderBox> findRenderObjectsAt(
    BuildContext context,
    Offset pointerOffset,
  ) {
    final root = context.findRenderObject();
    if (root is! RenderBox || !root.attached || !root.hasSize) {
      return const <RenderBox>[];
    }

    final localPosition = root.globalToLocal(pointerOffset);
    if (!localPosition.dx.isFinite || !localPosition.dy.isFinite) {
      return const <RenderBox>[];
    }


    final hitResult = BoxHitTestResult();
    root.hitTest(hitResult, position: localPosition);

    final boxes = <RenderBox>{};
    for (final entry in hitResult.path) {
      final target = entry.target;
      if (target is RenderBox) boxes.add(target);
    }
    if (boxes.isEmpty) return const <RenderBox>[];

    final centerRoutingParents = <RenderBox>{};
    for (final box in boxes) {
      if (_boundsContain(box, pointerOffset)) continue;
      final parent = box.parent;
      if (parent is RenderBox) centerRoutingParents.add(parent);
    }
    for (final parent in centerRoutingParents) {
      _enrichWithDescendants(parent, pointerOffset, boxes);
    }

    
    final filtered = <RenderBox>[];
    for (final box in boxes) {
      if (_boundsContain(box, pointerOffset)) filtered.add(box);
    }
    if (filtered.isEmpty) return const <RenderBox>[];

    
    filtered.sort(
        (a, b) => _depthFromRoot(a, root).compareTo(_depthFromRoot(b, root)));
    return List<RenderBox>.unmodifiable(filtered);
  }

  /// True when [box] is attached, sized, and its local bounds — after
  /// inverse-mapping [globalPosition] through every ancestor transform —
  /// contain that pointer. Conservatively false for non-invertible
  /// transforms (which would yield NaN/Infinity locals).
  static bool _boundsContain(RenderBox box, Offset globalPosition) {
    if (!box.attached || !box.hasSize) return false;
    final localPos = box.globalToLocal(globalPosition);
    if (!localPos.dx.isFinite || !localPos.dy.isFinite) return false;
    return box.size.contains(localPos);
  }

  static void _enrichWithDescendants(
    RenderBox parent,
    Offset globalPosition,
    Set<RenderBox> accumulator,
  ) {
    parent.visitChildren((child) {
      if (child is! RenderBox) return;
      if (!_boundsContain(child, globalPosition)) return;

      final localPos = child.globalToLocal(globalPosition);
      final childResult = BoxHitTestResult();
      if (child.hitTest(childResult, position: localPos)) {
        for (final entry in childResult.path) {
          final t = entry.target;
          if (t is RenderBox) accumulator.add(t);
        }
      }
    });
  }

  static int _depthFromRoot(RenderObject node, RenderObject root) {
    var depth = 0;
    RenderObject? current = node;
    while (current != null && !identical(current, root)) {
      depth++;
      current = current.parent;
    }
    return depth;
  }
}
