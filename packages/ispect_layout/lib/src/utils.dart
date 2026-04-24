import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class InspectorUtils {
  static Iterable<RenderBox> findRenderObjectsAt(
    BuildContext context,
    Offset pointerOffset,
  ) sync* {
    final root = context.findRenderObject();
    if (root == null) return;

    yield* _collectAt(root, pointerOffset);
  }

  static Iterable<RenderBox> _collectAt(
    RenderObject renderObject,
    Offset globalOffset,
  ) sync* {
    if (renderObject is RenderBox && renderObject.hasSize) {
      final globalRect = MatrixUtils.transformRect(
        renderObject.getTransformTo(null),
        Offset.zero & renderObject.size,
      );

      if (globalRect.isFinite &&
          !globalRect.isEmpty &&
          globalRect.contains(globalOffset)) {
        yield renderObject;
      }
    }

    final children = <RenderObject>[];
    renderObject.visitChildren(children.add);

    // Reverse order for Stack like ordering
    for (final child in children.reversed) {
      yield* _collectAt(child, globalOffset);
    }
  }
}
