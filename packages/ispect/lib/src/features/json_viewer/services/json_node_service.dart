import 'dart:collection';

import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/json_tree_flattener.dart';

/// Base mixin providing common node manipulation utilities.
///
/// This mixin follows DRY principle by centralizing shared logic
/// for getting direct children from nodes.
mixin NodeHelperMixin {
  /// Gets direct children of a node based on its type.
  Object? getDirectChildrenHelper(NodeViewModelState node) =>
      switch ((node.kind, node.value)) {
        (ClassNodeKind(), final Map<String, NodeViewModelState> map) => map,
        (ArrayNodeKind(), final List<NodeViewModelState> list) => list,
        _ => null,
      };

  /// Counts visible children in any iterable collection.
  int countChildrenInIterable(
    Iterable<NodeViewModelState> children,
    int Function(NodeViewModelState) counter,
  ) => children.fold(0, (sum, child) => sum + counter(child));
}

/// Concrete implementation for node expansion operations
class DefaultNodeExpansionService with NodeHelperMixin {
  List<NodeViewModelState> expandNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) {
    if (!node.isCollapsed || !node.isRoot) {
      return displayNodes;
    }

    final index = displayNodes.indexOf(node);
    if (index == -1) return displayNodes;

    final nodeIndex = index + 1;
    final children = getDirectChildrenHelper(node);
    final flatChildren = JsonTreeFlattener.flatten(children);

    node.expand();
    displayNodes.insertAll(nodeIndex, flatChildren);
    return displayNodes;
  }

  List<NodeViewModelState> collapseNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) {
    if (node.isCollapsed || !node.isRoot) {
      return displayNodes;
    }

    final index = displayNodes.indexOf(node);
    if (index == -1) return displayNodes;

    final nodeIndex = index + 1;
    final childrenCount = _countVisibleChildren(node) - 1;
    final endIndex = (nodeIndex + childrenCount).clamp(
      nodeIndex,
      displayNodes.length,
    );

    displayNodes.removeRange(nodeIndex, endIndex);
    node.collapse();
    return displayNodes;
  }

  int _countVisibleChildren(NodeViewModelState node) {
    if (!node.isRoot) return 1;
    if (node.isCollapsed) return 1;

    return 1 + countChildrenInIterable(node.children, _countVisibleChildren);
  }
}

/// Concrete implementation for bulk node operations
class DefaultBulkNodeService {
  List<NodeViewModelState> expandAll(
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) {
    for (final node in allNodes) {
      node.expand();
    }
    return List<NodeViewModelState>.from(allNodes);
  }

  List<NodeViewModelState> collapseAll(
    List<NodeViewModelState> displayNodes,
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) {
    // Collapse all nodes first to avoid recalculating children counts
    for (final node in allNodes) {
      node.collapse();
    }

    // Filter to keep only root nodes
    final rootNodes = displayNodes
        .where((node) => node.treeDepth == 0)
        .toList(growable: false);

    displayNodes
      ..clear()
      ..addAll(rootNodes);

    return displayNodes;
  }
}

/// Facade combining the node expansion and bulk operations used by the store.
class JsonNodeService {
  final DefaultNodeExpansionService _expansionService =
      DefaultNodeExpansionService();
  final DefaultBulkNodeService _bulkService = DefaultBulkNodeService();

  List<NodeViewModelState> expandNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) => _expansionService.expandNode(node, displayNodes);

  List<NodeViewModelState> collapseNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) => _expansionService.collapseNode(node, displayNodes);

  List<NodeViewModelState> expandAll(
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) => _bulkService.expandAll(allNodes);

  List<NodeViewModelState> collapseAll(
    List<NodeViewModelState> displayNodes,
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) => _bulkService.collapseAll(displayNodes, allNodes);
}
