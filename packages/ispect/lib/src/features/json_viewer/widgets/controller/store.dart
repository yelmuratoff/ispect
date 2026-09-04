import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'package:ispect/src/common/utils/debug_report.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/json_cache_service.dart';
import 'package:ispect/src/features/json_viewer/services/json_node_builder.dart';
import 'package:ispect/src/features/json_viewer/services/json_node_service.dart';
import 'package:ispect/src/features/json_viewer/services/json_search_service.dart';
import 'package:ispect/src/features/json_viewer/services/json_tree_flattener.dart';
import 'package:ispectify/ispectify.dart';

/// Handles the data and manages the state of a json explorer.
///
/// This class has been refactored to use separate services for better
/// separation of concerns and improved maintainability.
class JsonExplorerStore extends ChangeNotifier {
  JsonExplorerStore({
    this.processingPolicy = DiagnosticProcessingPolicy.balanced,
  }) {
    processingPolicy.validate();
  }

  final DiagnosticProcessingPolicy processingPolicy;

  List<NodeViewModelState> _displayNodes = [];
  UnmodifiableListView<NodeViewModelState> _allNodes = UnmodifiableListView([]);

  final List<SearchResult> _searchResults = <SearchResult>[];
  String _searchTerm = '';
  var _focusedSearchResultIndex = 0;
  int _buildGeneration = 0;
  int _searchGeneration = 0;
  bool _isSearching = false;
  NodeViewModelState? _selectedNode;
  Timer? _currentSearchOperation;
  bool _mounted = true;

  // Services for better separation of concerns
  final NodeHierarchyCacheService _hierarchyCacheService =
      NodeHierarchyCacheService();
  JsonNodeService? _nodeService;
  JsonSearchService? _searchService;

  bool get mounted => _mounted;

  /// Gets the list of nodes to be displayed.
  UnmodifiableListView<NodeViewModelState> get displayNodes =>
      UnmodifiableListView(_displayNodes);

  /// Whether the tree contains at least one expandable (object/array) node.
  bool get hasExpandableNodes => _allNodes.any((n) => n.isRoot);

  /// Whether an async search is currently in progress.
  bool get isSearching => _isSearching;

  /// Gets the current search term.
  String get searchTerm => _searchTerm;

  /// Gets the currently selected node (for breadcrumb display).
  NodeViewModelState? get selectedNode => _selectedNode;

  /// Selects a node to display its path in the breadcrumb.
  void selectNode(NodeViewModelState? node) {
    if (_selectedNode == node) return;
    _selectedNode = node;
    notifyListeners();
  }

  /// Gets a list containing the nodes found by the current search term.
  UnmodifiableListView<SearchResult> get searchResults =>
      UnmodifiableListView(_searchResults);

  /// Gets the current focused search node index.
  int get focusedSearchResultIndex => _focusedSearchResultIndex;

  /// Gets the current focused search result, or `null` if no results exist.
  SearchResult? get focusedSearchResult {
    if (_searchResults.isEmpty) return null;
    if (_focusedSearchResultIndex >= _searchResults.length) {
      _focusedSearchResultIndex = _searchResults.length - 1;
    }
    return _searchResults[_focusedSearchResultIndex];
  }

  /// Collapses the given `node` so its children won't be visible.
  void collapseNode(NodeViewModelState node) {
    final nodeService = _nodeService;
    if (!_mounted || nodeService == null || node.isCollapsed || !node.isRoot) {
      return;
    }

    _displayNodes = nodeService.collapseNode(node, _displayNodes);
    _hierarchyCacheService.clear();
    notifyListeners();
  }

  /// Collapses all nodes.
  void collapseAll() {
    final nodeService = _nodeService;
    if (!_mounted || nodeService == null) return;
    _displayNodes = nodeService.collapseAll(_displayNodes, _allNodes);
    _hierarchyCacheService.clear();
    notifyListeners();
  }

  /// Expands the given `node` so its children become visible.
  void expandNode(NodeViewModelState node) {
    if (!_mounted || !node.isCollapsed || !node.isRoot) {
      return;
    }

    final index = _displayNodes.indexOf(node);
    if (index == -1) return;

    final nodeIndex = index + 1;
    final nodes = JsonTreeFlattener.flatten(node.value);
    _displayNodes.insertAll(nodeIndex, nodes);
    node.expand();
    _hierarchyCacheService.clear();
    notifyListeners();
  }

  /// Expands all nodes.
  void expandAll() {
    final nodeService = _nodeService;
    if (!_mounted || nodeService == null) return;
    _displayNodes = nodeService.expandAll(_allNodes);
    _hierarchyCacheService.clear();
    notifyListeners();
  }

  /// Searches for the given `term` in all nodes.
  void search(String term) {
    final normalizedTerm = term.trim().toLowerCase();

    if (_searchTerm == normalizedTerm) return;

    final generation = _invalidateSearch(clearTerm: false);
    _searchTerm = normalizedTerm;

    if (normalizedTerm.isEmpty) {
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();
    unawaited(
      _doSearch(generation).catchError((Object error) {
        if (mounted && generation == _searchGeneration) {
          _isSearching = false;
          notifyListeners();
        }
        debugReportFailure('JsonExplorerStore: search failed', error);
      }),
    );
  }

  /// Sets the focus on the next search result.
  void focusNextSearchResult({bool loop = false}) {
    if (!_mounted || searchResults.isEmpty) return;

    if (_focusedSearchResultIndex < _searchResults.length - 1) {
      _focusedSearchResultIndex += 1;
      notifyListeners();
    } else if (loop) {
      _focusedSearchResultIndex = 0;
      notifyListeners();
    }
  }

  /// Sets the focus on the previous search result.
  void focusPreviousSearchResult({bool loop = false}) {
    if (!_mounted || searchResults.isEmpty) return;

    if (_focusedSearchResultIndex > 0) {
      _focusedSearchResultIndex -= 1;
      notifyListeners();
    } else if (loop) {
      _focusedSearchResultIndex = _searchResults.length - 1;
      notifyListeners();
    }
  }

  /// Uses the given `jsonObject` to build the [displayNodes] list.
  Future<void> buildNodes(
    JsonInputSnapshot snapshot, {
    bool areAllCollapsed = false,
  }) async {
    if (!mounted) return;

    final generation = ++_buildGeneration;
    _hierarchyCacheService.clear();

    final invalidatedSearchGeneration = _invalidateSearch();

    // For large JSON objects, process asynchronously
    final jsonObject = snapshot.value;
    final threshold = processingPolicy.viewerBuildYieldThreshold;
    final isLargeJson =
        (jsonObject is Map && jsonObject.length > threshold) ||
        (jsonObject is List && jsonObject.length > threshold);

    if (isLargeJson) {
      // Give UI thread a chance to update before heavy processing
      await Future<void>.delayed(processingPolicy.viewerBuildYieldDelay);
      if (!mounted || generation != _buildGeneration) return;
    }

    final builtNodes = JsonNodeBuilder.buildSnapshotViewModelNodes(snapshot);
    final flatList = JsonTreeFlattener.flatten(builtNodes);

    if (!mounted || generation != _buildGeneration) return;
    if (_searchGeneration != invalidatedSearchGeneration) {
      _invalidateSearch();
    }

    _allNodes = UnmodifiableListView(flatList);
    _displayNodes = List<NodeViewModelState>.of(flatList);

    _nodeService = JsonNodeService();
    _searchService = JsonSearchService(processingPolicy: processingPolicy);

    if (!mounted) return;

    if (areAllCollapsed) {
      collapseAll();
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _hierarchyCacheService.clear();
    _invalidateSearch();
    _buildGeneration++;
    _mounted = false;

    // Dispose all nodes to free up resources
    for (final node in _allNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Future<void> _doSearch(int generation) async {
    final searchService = _searchService;
    if (searchService == null) {
      if (mounted && generation == _searchGeneration) {
        _isSearching = false;
        notifyListeners();
      }
      return;
    }

    _searchResults.clear();

    final results = await searchService.searchInNodes(
      allNodes: _allNodes,
      searchTerm: _searchTerm,
      isMounted: () => mounted && generation == _searchGeneration,
      onProgressUpdate: () {
        if (mounted && generation == _searchGeneration) notifyListeners();
      },
    );

    // Discard stale results from a superseded search
    if (!mounted || generation != _searchGeneration) return;

    _searchResults.addAll(results.cast<SearchResult>());
    if (_searchResults.isNotEmpty) {
      _focusedSearchResultIndex = _focusedSearchResultIndex.clamp(
        0,
        _searchResults.length - 1,
      );
    } else {
      _focusedSearchResultIndex = 0;
    }

    // Re-check generation after updating results, in case a new search
    // was triggered while we were processing.
    if (!mounted || generation != _searchGeneration) return;

    _isSearching = false;
    expandSearchResults();
    notifyListeners();
  }

  int _invalidateSearch({bool clearTerm = true}) {
    _currentSearchOperation?.cancel();
    _currentSearchOperation = null;
    final generation = ++_searchGeneration;
    _isSearching = false;
    _searchResults.clear();
    _focusedSearchResultIndex = 0;
    if (clearTerm) _searchTerm = '';
    return generation;
  }

  /// Expands all the parent nodes of each search result.
  void expandSearchResults() {
    for (final result in _searchResults) {
      expandParentNodes(result.node);
    }
  }

  /// Expands all collapsed ancestors of [node] top-down,
  /// inserting their children into [_displayNodes].
  void expandParentNodes(NodeViewModelState node) {
    final collapsedAncestors = <NodeViewModelState>[];
    for (var current = node.parent; current != null; current = current.parent) {
      if (current.isCollapsed) {
        collapsedAncestors.add(current);
      }
    }
    // Expand top-down so each parent exists in displayNodes before its children
    for (final ancestor in collapsedAncestors.reversed) {
      expandNode(ancestor);
    }
  }
}
