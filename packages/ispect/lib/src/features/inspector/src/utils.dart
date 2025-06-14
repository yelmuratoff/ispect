import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Utility class for Flutter widget inspector functionality
///
/// Provides static methods for render tree traversal, hit testing,
/// and widget inspection operations. Used primarily for debugging
/// and development tools.
class InspectorUtils {
  const InspectorUtils._();

  /// Recursively finds the nearest ancestor RenderViewport in the render tree
  ///
  /// - Parameters:
  ///   - box: The starting RenderObject to traverse from
  /// - Return: RenderViewport if found, null otherwise
  /// - Usage: Used to locate scrollable containers for inspection
  /// - Edge case: Returns null if no viewport ancestor exists
  static RenderViewport? findAncestorViewport(RenderObject box) {
    // Direct match - return immediately
    if (box is RenderViewport) return box;

    // Recursive traversal with null safety
    final parent = box.parent;
    if (parent != null) {
      return findAncestorViewport(parent);
    }

    return null;
  }

  /// Bypasses RenderAbsorbPointer widgets to access underlying render objects
  ///
  /// - Parameters:
  ///   - renderObject: The starting RenderProxyBox to traverse
  /// - Return: First non-AbsorbPointer child, or null if none found
  /// - Usage: Enables hit testing through pointer-absorbing overlays
  /// - Edge case: Returns null if no valid child found or infinite loop detected
  static RenderBox? _bypassAbsorbPointer(RenderProxyBox renderObject) {
    RenderBox? current = renderObject;
    var depthGuard = 0;
    const maxDepth = 100;

    // Traverse until we find a non-AbsorbPointer or hit depth limit
    while (current != null &&
        current is! RenderAbsorbPointer &&
        depthGuard < maxDepth) {
      if (current is RenderProxyBox) {
        current = current.child;
      } else {
        break;
      }

      depthGuard++;
    }

    // Return the child of the AbsorbPointer (if we found one)
    return (current is RenderAbsorbPointer) ? current.child : current;
  }

  /// Performs hit testing at a given screen coordinate and returns all intersected RenderBox objects
  ///
  /// - Parameters:
  ///   - context: BuildContext to start hit testing from (must be mounted)
  ///   - pointerOffset: Global screen coordinate to test
  /// - Return: Iterable of RenderBox objects at the tap location, ordered by render tree depth
  /// - Usage: Used to identify tappable widgets during inspection
  /// - Edge case: Returns empty iterable if context unmounted or no valid render objects
  static Iterable<RenderBox> onTap(BuildContext context, Offset pointerOffset) {
    // Early exit for unmounted context
    if (!context.mounted) {
      return const <RenderBox>[];
    }

    // Get the render object, safely cast to RenderProxyBox
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderProxyBox) {
      return const <RenderBox>[];
    }

    // Bypass any AbsorbPointer widgets to enable hit testing
    final targetRenderObject = _bypassAbsorbPointer(renderObject);
    if (targetRenderObject == null) {
      return const <RenderBox>[];
    }

    // Perform hit test at the specified global coordinate
    final hitTestResult = BoxHitTestResult();
    final localPosition = targetRenderObject.globalToLocal(pointerOffset);

    targetRenderObject.hitTest(hitTestResult, position: localPosition);

    // Extract RenderBox objects from hit test results
    return hitTestResult.path
        .map((entry) => entry.target)
        .whereType<RenderBox>();
  }

  /// Finds the associated Element from a given RenderBox
  ///
  /// - Parameters:
  ///   - renderBox: The RenderBox to find the Element for
  /// - Return: Element if found, null otherwise
  /// - Usage: Used to get widget element during inspection for accessing widget properties
  /// - Edge case: Returns null if RenderBox has no associated Element or is disposed
  static Element? getElementFromRenderBox(RenderBox renderBox) {
    // Fallback: traverse the element tree to find matching render object
    Element? result;

    void visitor(Element element) {
      // Check if this element's render object matches our target
      if (element.renderObject == renderBox) {
        result = element;
        return;
      }

      // Continue traversing children if no match found
      element.visitChildren(visitor);
    }

    // Start traversal from the root element if we can find it
    final binding = WidgetsBinding.instance;
    final rootElement = binding.rootElement;
    if (rootElement != null) {
      visitor(rootElement);
    }

    return result;
  }
}
