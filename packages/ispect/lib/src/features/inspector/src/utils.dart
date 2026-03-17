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

  /// Finds all [RenderBox] objects at a given screen coordinate using direct
  /// render tree traversal instead of hit testing.
  ///
  /// This approach bypasses pointer event handling, making it possible to
  /// select boxes that aren't hit-testable but are visible on screen
  /// (e.g. widgets behind [AbsorbPointer] or [IgnorePointer]).
  ///
  /// - Parameters:
  ///   - context: BuildContext to start traversal from (must be mounted)
  ///   - pointerOffset: Global screen coordinate to test
  /// - Return: List of RenderBox objects at the offset, deepest first
  /// - Edge case: Returns empty list if context unmounted or no render objects found
  static List<RenderBox> findRenderBoxesAt(
    BuildContext context,
    Offset pointerOffset,
  ) {
    if (!context.mounted) return const <RenderBox>[];

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderProxyBox) return const <RenderBox>[];

    final targetRenderObject = _bypassAbsorbPointer(renderObject);
    if (targetRenderObject == null) return const <RenderBox>[];

    final results = <RenderBox>[];
    _collectRenderBoxesAt(targetRenderObject, pointerOffset, results);
    return results;
  }

  /// Recursively collects [RenderBox] objects that contain [offset].
  ///
  /// Handles special container types:
  /// - [RenderViewportBase]: only traverses [RenderSliver] children
  /// - [RenderStack]: reverses child order for correct z-ordering
  /// - Generic containers: visits children in paint order
  static void _collectRenderBoxesAt(
    RenderObject renderObject,
    Offset offset,
    List<RenderBox> results,
  ) {
    // Early bounds check using paintBounds (accounts for transforms/clips).
    // Only for RenderBox — non-box objects (slivers, etc.) are always visited.
    if (renderObject is RenderBox) {
      final localOffset = renderObject.globalToLocal(offset);
      if (!renderObject.paintBounds.contains(localOffset)) return;
    }

    if (renderObject is RenderViewportBase) {
      // Viewports: traverse only RenderSliver children
      renderObject.visitChildren((child) {
        if (child is RenderSliver) {
          _collectRenderBoxesAt(child, offset, results);
        }
      });
    } else if (renderObject is RenderStack) {
      // Stacks: reverse order so topmost (last painted) comes first
      final children = <RenderObject>[];
      renderObject.visitChildren(children.add);
      for (final child in children.reversed) {
        _collectRenderBoxesAt(child, offset, results);
      }
    } else {
      // Generic containers
      renderObject.visitChildren((child) {
        _collectRenderBoxesAt(child, offset, results);
      });
    }

    // Add this box to results (children are already added above)
    if (renderObject is RenderBox && renderObject.attached) {
      results.add(renderObject);
    }
  }

  /// Finds the associated Element from a given RenderBox
  ///
  /// - Parameters:
  ///   - renderBox: The RenderBox to find the Element for
  /// - Return: Element if found, null otherwise
  /// - Usage: Used to get widget element during inspection for accessing widget properties
  /// - Edge case: Returns null if RenderBox has no associated Element or is disposed
  static Element? getElementFromRenderBox(RenderBox renderBox) {
    Element? result;

    void visitor(Element element) {
      if (result != null) return;

      if (element.renderObject == renderBox) {
        result = element;
        return;
      }

      element.visitChildren(visitor);
    }

    final rootElement = WidgetsBinding.instance.rootElement;
    if (rootElement != null) {
      visitor(rootElement);
    }

    return result;
  }
}
