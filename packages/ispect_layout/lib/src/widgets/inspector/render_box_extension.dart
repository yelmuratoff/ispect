import 'package:flutter/rendering.dart';

extension RenderBoxExtension on RenderBox {
  /// When a [RenderBox] is a child of a [RenderFittedBox], its size is scaled to fit the parent.
  Size get displaySize {
    if (parent case final RenderFittedBox fittedBox
        when fittedBox.child == this && fittedBox.paintsChild(this)) {
      final transform = Matrix4.identity();
      fittedBox.applyPaintTransform(this, transform);
      return MatrixUtils.transformRect(transform, Offset.zero & size).size;
    }
    return size;
  }
}
