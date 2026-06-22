import 'package:flutter/widgets.dart';

/// Finds the [Element] that created [target] by searching the live element
/// tree from its root.
///
/// [RenderObject.debugCreator] would be a direct shortcut, but Flutter assigns
/// it inside an `assert`, so it is null in profile/release. The element tree,
/// by contrast, is present in every build mode — making this the release-safe
/// way to recover widget-level information (image provider, SVG source) from a
/// hit-tested render object.
///
/// Returns `null` before the first frame or when no element owns [target] (a
/// detached render object). The walk stops at the first match.
Element? elementForRenderObject(RenderObject target) {
  final root = WidgetsBinding.instance.rootElement;
  if (root == null) return null;

  Element? owner;
  void visit(Element element) {
    if (owner != null) return;
    if (element is RenderObjectElement && element.renderObject == target) {
      owner = element;
      return;
    }
    element.visitChildren(visit);
  }

  visit(root);
  return owner;
}
