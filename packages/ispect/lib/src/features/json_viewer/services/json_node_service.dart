import 'dart:collection';

import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/json_tree_flattener.dart';

/// Service responsible for node operations in JSON tree
class JsonNodeService {
  /// Expands a node and updates the display list
  static List<NodeViewModelState> expandNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) {
    if (!node.isCollapsed || !node.isRoot) {
      return displayNodes;
    }

    final nodeIndex = displayNodes.indexOf(node) + 1;
    final children = getDirectChildren(node);
    final flatChildren = JsonTreeFlattener.flatten(children);

    node.expand();

    final newDisplayNodes = List<NodeViewModelState>.from(displayNodes)
    ..insertAll(
        nodeIndex, flatChildren.cast<NodeViewModelState>(),);

    return newDisplayNodes;
  }

  /// Collapses a node and updates the display list
  static List<NodeViewModelState> collapseNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) {
    if (node.isCollapsed || !node.isRoot) {
      return displayNodes;
    }

    final nodeIndex = displayNodes.indexOf(node) + 1;
    final children = countVisibleChildren(node) - 1;

    node.collapse();

    final newDisplayNodes = List<NodeViewModelState>.from(displayNodes)
    ..removeRange(nodeIndex, nodeIndex + children);

    return newDisplayNodes;
  }

  /// Collapses all nodes in the tree
  static List<NodeViewModelState> collapseAll(
    List<NodeViewModelState> displayNodes,
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) {
    final rootNodes = displayNodes.where(
      (node) => node.treeDepth == 0 && !node.isCollapsed,
    );

    final collapsedNodes = List<NodeViewModelState>.from(displayNodes);

    for (final node in rootNodes) {
      final nodeIndex = collapsedNodes.indexOf(node) + 1;
      final children = countVisibleChildren(node) - 1;
      collapsedNodes.removeRange(nodeIndex, nodeIndex + children);
    }

    for (final node in allNodes) {
      node.collapse();
    }

    return collapsedNodes;
  }

  /// Expands all nodes in the tree
  static List<NodeViewModelState> expandAll(
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) {
    for (final node in allNodes) {
      node.expand();
    }

    return List<NodeViewModelState>.from(allNodes);
  }

  /// Expands all parent nodes of a given node
  static void expandParentNodes(NodeViewModelState node) {
    final parent = node.parent;
    if (parent == null) return;

    expandParentNodes(parent);
    parent.expand();
  }

  /// Expands all parent nodes for each search result
  static void expandSearchResults(List<SearchResult> searchResults) {
    for (final searchResult in searchResults) {
      expandParentNodes(searchResult.node);
    }
  }

  /// Gets direct children of a node
  static Object? getDirectChildren(NodeViewModelState node) {
    if (node.isClass) {
      return node.value as Map<String, NodeViewModelState>?;
    } else if (node.isArray) {
      return node.value as List<NodeViewModelState>?;
    }
    return null;
  }

  /// Counts visible children of a node (recursive)
  static int countVisibleChildren(NodeViewModelState node) {
    if (!node.isRoot) {
      return 1;
    }

    var count = 1;

    if (node.isClass && !node.isCollapsed) {
      final children = node.value! as Map<String, NodeViewModelState>;
      for (final child in children.values) {
        count += countVisibleChildren(child);
      }
    } else if (node.isArray && !node.isCollapsed) {
      final children = node.value! as List<NodeViewModelState>;
      for (final child in children) {
        count += countVisibleChildren(child);
      }
    }

    return count;
  }

  /// Optimized version of countVisibleChildren with caching
  static int countVisibleChildrenCached(
    NodeViewModelState node,
    Map<int, int> cache,
  ) {
    final nodeHash = node.hashCode;
    final cached = cache[nodeHash];
    if (cached != null) {
      return cached;
    }

    final count = countVisibleChildren(node);
    cache[nodeHash] = count;
    return count;
  }
}
