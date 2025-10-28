import 'dart:collection';

import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/json_tree_flattener.dart';

/// Interface for node expansion operations
abstract interface class NodeExpansionService {
  List<NodeViewModelState> expandNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  );

  List<NodeViewModelState> collapseNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  );
}

/// Interface for bulk node operations
abstract interface class BulkNodeService {
  List<NodeViewModelState> expandAll(
    UnmodifiableListView<NodeViewModelState> allNodes,
  );

  List<NodeViewModelState> collapseAll(
    List<NodeViewModelState> displayNodes,
    UnmodifiableListView<NodeViewModelState> allNodes,
  );
}

/// Interface for node navigation operations
abstract interface class NodeNavigationService {
  void expandParentNodes(NodeViewModelState node);
  void expandSearchResults(List<SearchResult> searchResults);
}

/// Interface for node analysis operations
abstract interface class NodeAnalysisService {
  Object? getDirectChildren(NodeViewModelState node);
  int countVisibleChildren(NodeViewModelState node);
  int countVisibleChildrenCached(NodeViewModelState node, Map<int, int> cache);
}

/// Concrete implementation for node expansion operations
class DefaultNodeExpansionService implements NodeExpansionService {
  @override
  List<NodeViewModelState> expandNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) {
    if (!node.isCollapsed || !node.isRoot) {
      return displayNodes;
    }

    final nodeIndex = displayNodes.indexOf(node) + 1;
    final children = _getDirectChildren(node);
    final flatChildren = JsonTreeFlattener.flatten(children);

    node.expand();
    displayNodes.insertAll(nodeIndex, flatChildren);
    return displayNodes;
  }

  @override
  List<NodeViewModelState> collapseNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) {
    if (node.isCollapsed || !node.isRoot) {
      return displayNodes;
    }

    final nodeIndex = displayNodes.indexOf(node) + 1;
    final childrenCount = _countVisibleChildren(node) - 1;

    node.collapse();
    displayNodes.removeRange(nodeIndex, nodeIndex + childrenCount);
    return displayNodes;
  }

  Object? _getDirectChildren(NodeViewModelState node) => switch (node) {
        _ when node.isClass => node.value as Map<String, NodeViewModelState>?,
        _ when node.isArray => node.value as List<NodeViewModelState>?,
        _ => null,
      };

  int _countVisibleChildren(NodeViewModelState node) {
    if (!node.isRoot) return 1;

    return 1 +
        switch (node) {
          _ when node.isClass && !node.isCollapsed => _countChildrenInMap(
              node.value! as Map<String, NodeViewModelState>,
            ),
          _ when node.isArray && !node.isCollapsed => _countChildrenInList(
              node.value! as List<NodeViewModelState>,
            ),
          _ => 0,
        };
  }

  int _countChildrenInMap(Map<String, NodeViewModelState> children) =>
      children.values.fold(0, (sum, child) => sum + _countVisibleChildren(child));

  int _countChildrenInList(List<NodeViewModelState> children) =>
      children.fold(0, (sum, child) => sum + _countVisibleChildren(child));
}

/// Concrete implementation for bulk node operations
class DefaultBulkNodeService implements BulkNodeService {
  @override
  List<NodeViewModelState> expandAll(
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) {
    for (final node in allNodes) {
      node.expand();
    }
    return List<NodeViewModelState>.from(allNodes);
  }

  @override
  List<NodeViewModelState> collapseAll(
    List<NodeViewModelState> displayNodes,
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) {
    // Collapse all nodes first to avoid recalculating children counts
    for (final node in allNodes) {
      node.collapse();
    }

    // Filter to keep only root nodes
    final rootNodes =
        displayNodes.where((node) => node.treeDepth == 0).toList();

    displayNodes
      ..clear()
      ..addAll(rootNodes);

    return displayNodes;
  }
}

/// Concrete implementation for node navigation operations
class DefaultNodeNavigationService implements NodeNavigationService {
  @override
  void expandParentNodes(NodeViewModelState node) {
    final parent = node.parent;
    if (parent == null) return;

    expandParentNodes(parent);
    parent.expand();
  }

  @override
  void expandSearchResults(List<SearchResult> searchResults) {
    for (final searchResult in searchResults) {
      expandParentNodes(searchResult.node);
    }
  }
}

/// Concrete implementation for node analysis operations
class DefaultNodeAnalysisService implements NodeAnalysisService {
  @override
  Object? getDirectChildren(NodeViewModelState node) => switch (node) {
        _ when node.isClass => node.value as Map<String, NodeViewModelState>?,
        _ when node.isArray => node.value as List<NodeViewModelState>?,
        _ => null,
      };

  @override
  int countVisibleChildren(NodeViewModelState node) {
    if (!node.isRoot) return 1;

    return 1 +
        switch (node) {
          _ when node.isClass && !node.isCollapsed => _countMapChildren(
              node.value! as Map<String, NodeViewModelState>,
            ),
          _ when node.isArray && !node.isCollapsed => _countListChildren(
              node.value! as List<NodeViewModelState>,
            ),
          _ => 0,
        };
  }

  int _countMapChildren(Map<String, NodeViewModelState> children) =>
      children.values.fold(0, (sum, child) => sum + countVisibleChildren(child));

  int _countListChildren(List<NodeViewModelState> children) =>
      children.fold(0, (sum, child) => sum + countVisibleChildren(child));

  @override
  int countVisibleChildrenCached(
    NodeViewModelState node,
    Map<int, int> cache,
  ) =>
      cache.putIfAbsent(node.hashCode, () => countVisibleChildren(node));
}

/// Facade service that combines all node operations following Facade pattern
class JsonNodeService
    implements
        NodeExpansionService,
        BulkNodeService,
        NodeNavigationService,
        NodeAnalysisService {
  JsonNodeService({
    NodeExpansionService? expansionService,
    BulkNodeService? bulkService,
    NodeNavigationService? navigationService,
    NodeAnalysisService? analysisService,
  })  : _expansionService = expansionService ?? DefaultNodeExpansionService(),
        _bulkService = bulkService ?? DefaultBulkNodeService(),
        _navigationService =
            navigationService ?? DefaultNodeNavigationService(),
        _analysisService = analysisService ?? DefaultNodeAnalysisService();

  // Singleton instance for static methods
  static final JsonNodeService _instance = JsonNodeService();

  final NodeExpansionService _expansionService;
  final BulkNodeService _bulkService;
  final NodeNavigationService _navigationService;
  final NodeAnalysisService _analysisService;

  // Delegate to expansion service
  @override
  List<NodeViewModelState> expandNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) =>
      _expansionService.expandNode(node, displayNodes);

  @override
  List<NodeViewModelState> collapseNode(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) =>
      _expansionService.collapseNode(node, displayNodes);

  // Delegate to bulk service
  @override
  List<NodeViewModelState> expandAll(
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) =>
      _bulkService.expandAll(allNodes);

  @override
  List<NodeViewModelState> collapseAll(
    List<NodeViewModelState> displayNodes,
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) =>
      _bulkService.collapseAll(displayNodes, allNodes);

  // Delegate to navigation service
  @override
  void expandParentNodes(NodeViewModelState node) =>
      _navigationService.expandParentNodes(node);

  @override
  void expandSearchResults(List<SearchResult> searchResults) =>
      _navigationService.expandSearchResults(searchResults);

  // Delegate to analysis service
  @override
  Object? getDirectChildren(NodeViewModelState node) =>
      _analysisService.getDirectChildren(node);

  @override
  int countVisibleChildren(NodeViewModelState node) =>
      _analysisService.countVisibleChildren(node);

  @override
  int countVisibleChildrenCached(
    NodeViewModelState node,
    Map<int, int> cache,
  ) =>
      _analysisService.countVisibleChildrenCached(node, cache);

  // Static methods delegate to singleton instance to avoid duplication
  static List<NodeViewModelState> expandNodeStatic(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) =>
      _instance.expandNode(node, displayNodes);

  static List<NodeViewModelState> collapseNodeStatic(
    NodeViewModelState node,
    List<NodeViewModelState> displayNodes,
  ) =>
      _instance.collapseNode(node, displayNodes);

  static List<NodeViewModelState> expandAllStatic(
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) =>
      _instance.expandAll(allNodes);

  static List<NodeViewModelState> collapseAllStatic(
    List<NodeViewModelState> displayNodes,
    UnmodifiableListView<NodeViewModelState> allNodes,
  ) =>
      _instance.collapseAll(displayNodes, allNodes);

  static void expandParentNodesStatic(NodeViewModelState node) =>
      _instance.expandParentNodes(node);

  static void expandSearchResultsStatic(List<SearchResult> searchResults) =>
      _instance.expandSearchResults(searchResults);

  static Object? getDirectChildrenStatic(NodeViewModelState node) =>
      _instance.getDirectChildren(node);

  static int countVisibleChildrenStatic(NodeViewModelState node) =>
      _instance.countVisibleChildren(node);

  static int countVisibleChildrenCachedStatic(
    NodeViewModelState node,
    Map<int, int> cache,
  ) =>
      _instance.countVisibleChildrenCached(node, cache);
}
