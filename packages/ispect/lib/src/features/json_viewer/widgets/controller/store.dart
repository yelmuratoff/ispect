import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';

import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/json_cache_service.dart';
import 'package:ispect/src/features/json_viewer/services/json_node_builder.dart';
import 'package:ispect/src/features/json_viewer/services/json_node_service.dart';
import 'package:ispect/src/features/json_viewer/services/json_search_service.dart';
import 'package:ispect/src/features/json_viewer/services/json_tree_flattener.dart';

/// Handles the data and manages the state of a json explorer.
///
/// This class has been refactored to use separate services for better
/// separation of concerns and improved maintainability.
class JsonExplorerStore extends ChangeNotifier {
  List<NodeViewModelState> _displayNodes = [];
  UnmodifiableListView<NodeViewModelState> _allNodes = UnmodifiableListView([]);

  final List<SearchResult> _searchResults = <SearchResult>[];
  String _searchTerm = '';
  var _focusedSearchResultIndex = 0;
  Timer? _currentSearchOperation;
  DateTime? _lastSearchTime;
  bool _mounted = true;

  // Services for better separation of concerns
  final JsonViewerCacheService _cacheService = JsonViewerCacheService();

  bool get mounted => _mounted;

  /// Gets the list of nodes to be displayed.
  UnmodifiableListView<NodeViewModelState> get displayNodes =>
      UnmodifiableListView(_displayNodes);

  /// Gets the current search term.
  String get searchTerm => _searchTerm;

  /// Gets a list containing the nodes found by the current search term.
  UnmodifiableListView<SearchResult> get searchResults =>
      UnmodifiableListView(_searchResults);

  /// Gets the current focused search node index.
  int get focusedSearchResultIndex => _focusedSearchResultIndex;

  /// Gets the current focused search result.
  SearchResult get focusedSearchResult =>
      _searchResults[_focusedSearchResultIndex];

  /// Collapses the given `node` so its children won't be visible.
  void collapseNode(NodeViewModelState node) {
    if (node.isCollapsed || !node.isRoot) {
      return;
    }

    _displayNodes = JsonNodeService.collapseNode(node, _displayNodes);
    _cacheService.clearHierarchyCaches();
    notifyListeners();
  }

  /// Collapses all nodes.
  void collapseAll() {
    _displayNodes = JsonNodeService.collapseAll(_displayNodes, _allNodes);
    _cacheService.clearHierarchyCaches();
    notifyListeners();
  }

  /// Expands the given `node` so its children become visible.
  void expandNode(NodeViewModelState node) {
    if (!node.isCollapsed || !node.isRoot) {
      return;
    }

    final nodeIndex = _displayNodes.indexOf(node) + 1;
    final nodes = JsonTreeFlattener.flatten(node.value);
    _displayNodes.insertAll(nodeIndex, nodes);
    node.expand();
    _cacheService.clearHierarchyCaches();
    notifyListeners();
  }

  /// Expands all nodes.
  void expandAll() {
    _displayNodes = JsonNodeService.expandAll(_allNodes);
    notifyListeners();
  }

  /// Searches for the given `term` in all nodes.
  void search(String term) {
    final normalizedTerm = term.trim().toLowerCase();

    if (_searchTerm == normalizedTerm) return;

    _searchTerm = normalizedTerm;
    _focusedSearchResultIndex = 0;
    _searchResults.clear();

    if (normalizedTerm.isEmpty) {
      notifyListeners();
      return;
    }

    // Cancel any ongoing search
    _currentSearchOperation?.cancel();

    // Debounce search operations
    _currentSearchOperation = JsonSearchService.debounceSearchOperation(
      normalizedTerm,
      _lastSearchTime,
      _allNodes.length,
      _doSearch,
    );

    _lastSearchTime = DateTime.now();
  }

  /// Sets the focus on the next search result.
  void focusNextSearchResult({bool loop = false}) {
    if (searchResults.isEmpty) return;

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
    if (searchResults.isEmpty) return;

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
    Object? jsonObject, {
    bool areAllCollapsed = false,
  }) async {
    // Clear caches first to avoid memory leaks
    _cacheService.clearAll();

    // Cancel any ongoing search
    _currentSearchOperation?.cancel();
    _searchResults.clear();
    _searchTerm = '';
    _focusedSearchResultIndex = 0;

    // For large JSON objects, process asynchronously
    final isLargeJson = (jsonObject is Map && jsonObject.length > 1000) ||
        (jsonObject is List && jsonObject.length > 1000);

    if (isLargeJson) {
      // Give UI thread a chance to update before heavy processing
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    final builtNodes = JsonNodeBuilder.buildViewModelNodes(jsonObject);
    final flatList = JsonTreeFlattener.flatten(builtNodes);

    _allNodes = UnmodifiableListView(flatList);
    _displayNodes = List.from(flatList);

    if (areAllCollapsed) {
      collapseAll();
    } else {
      if (mounted) notifyListeners();
    }
  }

  @override
  void dispose() {
    // Clear caches when disposing the store
    _cacheService.clearAll();

    // Cancel any ongoing search
    _currentSearchOperation?.cancel();
    _mounted = false;

    // Dispose all nodes to free up resources
    for (final node in _allNodes) {
      node.dispose();
    }

    super.dispose();
  }

  Future<void> _doSearch() async {
    _searchResults.clear();

    // Use search service for better performance and separation of concerns
    final results = await JsonSearchService.searchInNodes(
      allNodes: _allNodes,
      searchTerm: _searchTerm,
      isMounted: () => mounted,
      onProgressUpdate: () {
        if (mounted) notifyListeners();
      },
    );

    if (mounted) {
      _searchResults.addAll(results.cast<SearchResult>());
      notifyListeners();
    }
  }

  /// Expands all the parent nodes of each search result.
  void expandSearchResults() {
    JsonNodeService.expandSearchResults(
        searchResults.cast<SearchResult>().toList(),);
  }

  /// Expands all the parent nodes of the given `node`.
  void expandParentNodes(NodeViewModelState node) {
    JsonNodeService.expandParentNodes(node);
  }
}
