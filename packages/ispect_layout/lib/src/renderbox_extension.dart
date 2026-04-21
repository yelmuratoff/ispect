import 'package:flutter/cupertino.dart';

extension RenderboxExtension on RenderBox {
  /// Be careful, this method can be expensive if the render box tree is deep.
  bool isDescendantOf(RenderBox potentialAncestor) {
    RenderObject? current = this;
    while (current != null) {
      if (current == potentialAncestor) return true;
      current = current.parent;
    }
    return false;
  }
}
