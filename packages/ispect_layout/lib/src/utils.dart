import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class InspectorUtils {
  /// Returns the [RenderBox]es under [pointerOffset] (global coordinates),
  /// ordered outermost → innermost, as Flutter's pointer-routing pipeline
  /// would visit them.
  ///
  /// Built on [RenderBox.hitTest] rather than a manual `visitChildren`
  /// walk so that routes beneath the active one in the Navigator stack,
  /// modal barriers, [Offstage], [IgnorePointer]/[AbsorbPointer], and
  /// hit-test opacity are honoured automatically. A naive descend-and
  /// rect-contains traversal would expose render boxes from inactive
  /// routes, since they remain attached and laid out (Overlay's
  /// `_RenderTheatre` only skips them in `paint` and `hitTestChildren`).
  ///
  /// Returns an empty list when [context]'s render object is not an
  /// attached, sized [RenderBox]; when [pointerOffset] cannot be
  /// transformed into the root's local space (non-invertible ancestor
  /// transform); or when nothing at that point is hit-testable.
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

    final result = BoxHitTestResult();
    root.hitTest(result, position: localPosition);

    // BoxInfo.fromHitTestResults expects outer→inner order — innermost
    // wins the tie-break on equal sizes via "later iteration wins". hitTest
    // gives innermost first, so the result is reversed.
    final boxes = <RenderBox>[];
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderBox) {
        boxes.add(target);
      }
    }
    return boxes.reversed.toList(growable: false);
  }
}
