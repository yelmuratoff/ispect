import 'dart:collection';

import 'package:flutter/widgets.dart';

/// A view model state that represents a single node item in a json object tree.
/// A decoded json object can be converted to a `NodeViewModelState` by calling
/// the `buildViewModelNodes` method.
///
/// A node item can be eiter a class root, an array or a single
/// class/array field.
///
///
/// The string `key` is the same as the json key, unless this node is an element
/// if an array, then its key is its index in the array.
///
/// The node `value` behaviour depends on what this node represents, if it is
/// a property (from json: "key": "value"), then the value is the actual
/// property value, one of `num`, [String], [bool], [Null]. Since this node
/// represents a single property, both `isClass` and [isArray] are false.
///
/// If this node represents a class, `value` contains a
/// `Map<String, NodeViewModelState>` with this node's children. In this case
/// `isClass` is true.
///
/// If this node represents an array, `value` contains a
/// `List<NodeViewModelState>` with this node's children. In this case
/// `isArray` is true.
///
/// See also:
/// * `buildViewModelNodes`
/// * `flatten`
class NodeViewModelState extends ChangeNotifier {
  /// Build a `NodeViewModelState` as a property.
  /// A property is a single attribute in the json, can be of a type
  /// `num`, [String], [bool] or [Null].
  ///
  /// Properties always return `false` when calling [isClass], [isArray]
  /// and `isRoot`
  factory NodeViewModelState.fromProperty({
    required int treeDepth,
    required String key,
    required Object? value,
    required NodeViewModelState? parent,
    required Object? rawValue,
  }) =>
      NodeViewModelState._(
        key: key,
        value: value,
        treeDepth: treeDepth,
        parent: parent,
        rawValue: rawValue,
      );

  /// Build a `NodeViewModelState` as a class.
  /// A class is a JSON node containing a whole class, a class can have
  /// multiple children properties, classes or arrays.
  /// Its value is always a `Map<String, NodeViewModelState>` containing the
  /// children information.
  ///
  /// Classes always return `true` when calling [isClass] and [isRoot].
  factory NodeViewModelState.fromClass({
    required int treeDepth,
    required String key,
    required NodeViewModelState? parent,
    required Object? rawValue,
  }) =>
      NodeViewModelState._(
        isClass: true,
        key: key,
        treeDepth: treeDepth,
        parent: parent,
        rawValue: rawValue,
      );

  /// Build a `NodeViewModelState` as an array.
  /// An array is a JSON node containing an array of objects, each element
  /// inside the array is represented by another `NodeViewModelState`. Thus
  /// it can be values or classes.
  /// Its value is always a `List<NodeViewModelState>` containing the
  /// children information.
  ///
  /// Arrays always return `true` when calling [isArray] and [isRoot].
  factory NodeViewModelState.fromArray({
    required int treeDepth,
    required String key,
    required NodeViewModelState? parent,
    required Object? rawValue,
  }) =>
      NodeViewModelState._(
        isArray: true,
        key: key,
        treeDepth: treeDepth,
        parent: parent,
        rawValue: rawValue,
      );
  NodeViewModelState._({
    required this.treeDepth,
    required this.key,
    required this.rawValue,
    this.isClass = false,
    this.isArray = false,
    Object? value,
    bool isCollapsed = false,
    NodeViewModelState? parent,
  })  : _isCollapsed = isCollapsed,
        _parent = parent,
        _value = value;

  /// This attribute name.
  final String key;

  /// How deep in the tree this node is.
  final int treeDepth;

  /// Flags if this node is a class, if `true`, then [value] is as Map
  final bool isClass;

  /// Flags if this node is an array, if `true`, then [value] is a
  /// `List<NodeViewModelState>`.
  final bool isArray;

  final dynamic rawValue;

  bool _isHighlighted = false;
  bool _isFocused = false;
  bool _isCollapsed;

  NodeViewModelState? _parent;

  /// A reference to the closest node above this one.
  NodeViewModelState? get parent => _parent;

  dynamic _value;
  int? _childrenCount;

  /// Updates the `value` of this node.
  @visibleForTesting
  set value(Object? value) {
    _value = value;
    _childrenCount = null; // Reset cache when value changes
  }

  /// This attribute value, it may be one of the following:
  /// `num`, [String], [bool], [Null], [Map<String, NodeViewModelState>] or
  /// `List<NodeViewModelState>`.
  dynamic get value => _value;

  /// Cached children count for performance
  int get childrenCount {
    if (_childrenCount != null) return _childrenCount!;

    final dynamic currentValue = value;
    if (currentValue is Map<String, dynamic>) {
      _childrenCount = currentValue.keys.length;
    } else if (currentValue is List) {
      _childrenCount = currentValue.length;
    } else {
      _childrenCount = 0;
    }

    return _childrenCount!;
  }

  /// Returns `true` if this node is highlighted.
  ///
  /// This is a mutable property, `notifyListeners` is called to notify all
  ///  registered listeners.
  bool get isHighlighted => _isHighlighted;

  /// Returns `true` if this node is focused.
  ///
  /// This is a mutable property, `notifyListeners` is called to notify all
  ///  registered listeners.
  bool get isFocused => _isFocused;

  /// Returns `true` if this node is collapsed.
  ///
  /// This is a mutable property, `notifyListeners` is called to notify all
  /// registered listeners.
  bool get isCollapsed => _isCollapsed;

  /// Returns `true` if this is a root node.
  ///
  /// A root node is a node that contains multiple children. A class or an
  /// array.
  bool get isRoot => isClass || isArray;

  bool get isLast {
    // if (parent == null) {
    //   return true;
    // }
    final children = parent?.children;
    return children?.lastOrNull == this;
  }

  /// Returns a list of this node's children.
  /// Cached for performance to avoid repeated iterations.
  Iterable<NodeViewModelState> get children {
    if (isClass) {
      return (value as Map<String, NodeViewModelState>).values;
    } else if (isArray) {
      return value as List<NodeViewModelState>;
    }
    return const <NodeViewModelState>[];
  }

  /// Sets the highlight property of this node and all of its children.
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  void highlight({bool isHighlighted = true}) {
    _isHighlighted = isHighlighted;
    for (final children in children) {
      children.highlight(isHighlighted: isHighlighted);
    }
    notifyListeners();
  }

  /// Sets the focus property of this node.
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  void focus({bool isFocused = true}) {
    _isFocused = isFocused;
    notifyListeners();
  }

  /// Sets the `isCollapsed` property to [false].
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  void collapse() {
    _isCollapsed = true;
    notifyListeners();
  }

  /// Sets the `isCollapsed` property to [true].
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  void expand() {
    _isCollapsed = false;
    notifyListeners();
  }
}

/// Builds `NodeViewModelState` nodes based on a decoded json object.
///
/// The return `Map<String, NodeViewModelState>` has the same structure as
/// the decoded `object`, except that every class, array and property is now
/// a `NodeViewModelState`.
@visibleForTesting
Map<String, NodeViewModelState> buildViewModelNodes(Object? object) {
  if (object is Map<String, dynamic>) {
    return _buildClassNodes(object: object);
  }
  return _buildClassNodes(object: <String, dynamic>{'data': object});
}

Map<String, NodeViewModelState> _buildClassNodes({
  required Map<String, dynamic> object,
  int treeDepth = 0,
  NodeViewModelState? parent,
}) {
  final map = <String, NodeViewModelState>{};
  object.forEach((key, value) {
    if (value is Map<String, dynamic>) {
      final classNode = NodeViewModelState.fromClass(
        treeDepth: treeDepth,
        key: key,
        parent: parent,
        rawValue: value,
      );

      final children = _buildClassNodes(
        object: value,
        treeDepth: treeDepth + 1,
        parent: classNode,
      );

      classNode.value = children;

      map[key] = classNode;
    } else if (value is List) {
      final arrayNode = NodeViewModelState.fromArray(
        treeDepth: treeDepth,
        key: key,
        parent: parent,
        rawValue: value,
      );

      final children = _buildArrayNodes(
        object: value,
        treeDepth: treeDepth,
        parent: arrayNode,
      );

      arrayNode.value = children;

      map[key] = arrayNode;
    } else {
      map[key] = NodeViewModelState.fromProperty(
        key: key,
        value: value,
        treeDepth: treeDepth,
        parent: parent,
        rawValue: value,
      );
    }
  });
  return map;
}

List<NodeViewModelState> _buildArrayNodes({
  required List<dynamic> object,
  int treeDepth = 0,
  NodeViewModelState? parent,
}) {
  final array = <NodeViewModelState>[];
  for (var i = 0; i < object.length; i++) {
    final dynamic arrayValue = object[i];

    if (arrayValue is Map<String, dynamic>) {
      final classNode = NodeViewModelState.fromClass(
        key: i.toString(),
        treeDepth: treeDepth + 1,
        parent: parent,
        rawValue: arrayValue,
      );

      final children = _buildClassNodes(
        object: arrayValue,
        treeDepth: treeDepth + 2,
        parent: classNode,
      );

      classNode.value = children;

      array.add(classNode);
    } else {
      array.add(
        NodeViewModelState.fromProperty(
          key: i.toString(),
          value: arrayValue,
          treeDepth: treeDepth + 1,
          parent: parent,
          rawValue: arrayValue,
        ),
      );
    }
  }
  return array;
}

@visibleForTesting
List<NodeViewModelState> flatten(Object? object) {
  if (object is List) {
    return _flattenArray(object as List<NodeViewModelState>);
  }
  if (object == null) {
    return const <NodeViewModelState>[];
  }
  return _flattenClass(object as Map<String, NodeViewModelState>);
}

List<NodeViewModelState> _flattenClass(Map<String, NodeViewModelState> object) {
  final flatList = <NodeViewModelState>[];

  object.forEach((key, value) {
    flatList.add(value);

    if (!value.isCollapsed) {
      if (value.value is Map) {
        // Avoid unnecessary allocations by directly adding to the list
        _addFlattenedClassToList(
          value.value as Map<String, NodeViewModelState>,
          flatList,
        );
      } else if (value.value is List) {
        _addFlattenedArrayToList(
          value.value as List<NodeViewModelState>,
          flatList,
        );
      }
    }
  });
  return flatList;
}

void _addFlattenedClassToList(
  Map<String, NodeViewModelState> object,
  List<NodeViewModelState> flatList,
) {
  object.forEach((key, value) {
    flatList.add(value);

    if (!value.isCollapsed) {
      if (value.value is Map<String, NodeViewModelState>) {
        _addFlattenedClassToList(
          value.value as Map<String, NodeViewModelState>,
          flatList,
        );
      } else if (value.value is List) {
        _addFlattenedArrayToList(
          value.value as List<NodeViewModelState>,
          flatList,
        );
      }
    }
  });
}

List<NodeViewModelState> _flattenArray(List<NodeViewModelState> objects) {
  final flatList = <NodeViewModelState>[];

  for (final object in objects) {
    flatList.add(object);
    if (!object.isCollapsed &&
        object.value is Map<String, NodeViewModelState>) {
      _addFlattenedClassToList(
        object.value as Map<String, NodeViewModelState>,
        flatList,
      );
    }
  }
  return flatList;
}

void _addFlattenedArrayToList(
  List<NodeViewModelState> objects,
  List<NodeViewModelState> flatList,
) {
  for (final object in objects) {
    flatList.add(object);
    if (!object.isCollapsed &&
        object.value is Map<String, NodeViewModelState>) {
      _addFlattenedClassToList(
        object.value as Map<String, NodeViewModelState>,
        flatList,
      );
    }
  }
}

/// Handles the data and manages the state of a json explorer.
///
/// The data must be initialized by calling the `buildNodes` method.
/// This method takes a raw JSON object `Map<String, dynamic>` or
/// `List<dynamic>` and builds a flat node list of [NodeViewModelState].
///
///
/// The property `displayNodes` contains a flat list of all nodes that can be
/// displayed.
/// This means that each node property is an element in this list, even inner
/// class properties.
///
/// ## Example
///
/// {@tool snippet}
///
/// Considering the following JSON file with inner classes and properties:
///
/// ```json
/// {
///   "someClass": {
///     "classField": "value",
///     "innerClass": {
///         "innerClassField": "value"
///         }
///     }
///     "arrayField": `0, 1`
/// }
///
/// The `displayNodes` representation is going to look like this:
/// [
///   node {"someClass": ...},
///   node {"classField": ...},
///   node {"innerClass": ...},
///   node {"innerClassField": ...},
///   node {"arrayField": ...},
///   node {"0": ...},
///   node {"1": ...},
/// ]
///
/// ```
/// {@end-tool}
///
/// This data structure allows us to render the nodes easily using a
/// `ListView.builder` for example, or any other kind of list rendering widget.
///
class JsonExplorerStore extends ChangeNotifier {
  List<NodeViewModelState> _displayNodes = [];
  UnmodifiableListView<NodeViewModelState> _allNodes = UnmodifiableListView([]);

  final List<SearchResult> _searchResults = <SearchResult>[];
  String _searchTerm = '';
  var _focusedSearchResultIndex = 0;
  Future<void>? _currentSearchOperation;
  DateTime? _lastSearchTime;
  static const _searchDebounceTime = Duration(milliseconds: 300);
  bool _mounted = true;

  // Cache for search term results to avoid recomputing on navigation
  final Map<String, List<int>> _searchMatchesCache = {};

  bool get mounted => _mounted;

  /// Gets the list of nodes to be displayed.
  ///
  /// `notifyListeners` is called whenever this value changes.
  /// The returned `Iterable` is closed for modification.
  UnmodifiableListView<NodeViewModelState> get displayNodes =>
      UnmodifiableListView(_displayNodes);

  /// Gets the current search term.
  ///
  /// `notifyListeners` is called whenever this value changes.
  String get searchTerm => _searchTerm;

  /// Gets a list containing the nodes found by the current search term.
  ///
  /// `notifyListeners` is called whenever this value changes.
  /// The returned `Iterable` is closed for modification.
  UnmodifiableListView<SearchResult> get searchResults =>
      UnmodifiableListView(_searchResults);

  /// Gets the current focused search node index.
  /// If there are search results, this is going to be an index of
  /// `searchResults` list. It always going to be 0 by default.
  ///
  /// Use `focusNextSearchResult` and [focusPreviousSearchResult] to change the
  /// current focused search node.
  ///
  /// `notifyListeners` is called whenever this value changes.
  int get focusedSearchResultIndex => _focusedSearchResultIndex;

  /// Gets the current focused search result.
  ///
  /// Use `focusNextSearchResult` and [focusPreviousSearchResult] to change the
  /// current focused search node.
  ///
  /// `notifyListeners` is called whenever this value changes.
  SearchResult get focusedSearchResult =>
      _searchResults[_focusedSearchResultIndex];

  /// Collapses the given `node` so its children won't be visible.
  ///
  /// This will change the `node` [NodeViewModelState.isCollapsed] property to
  /// true. But its children won't change states, so when the node is expanded
  /// its children states are unchanged.
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  ///
  /// See also:
  /// * `expandNode`
  void collapseNode(NodeViewModelState node) {
    if (node.isCollapsed || !node.isRoot) {
      return;
    }

    final nodeIndex = _displayNodes.indexOf(node) + 1;
    final children = _visibleChildrenCount(node) - 1;
    _displayNodes.removeRange(nodeIndex, nodeIndex + children);
    node.collapse();
    _visibleChildrenCountCache.clear(); // Очищаем кэш после изменения состояния
    notifyListeners();
  }

  /// Collapses all nodes.
  ///
  /// This collapses every single node of the data structure, meaning that only
  /// the upper root nodes will be in the `displayNodes` list.
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  ///
  /// See also:
  /// * `expandAll`
  void collapseAll() {
    final rootNodes =
        _displayNodes.where((node) => node.treeDepth == 0 && !node.isCollapsed);
    final collapsedNodes = List<NodeViewModelState>.from(_displayNodes);
    for (final node in rootNodes) {
      final nodeIndex = collapsedNodes.indexOf(node) + 1;
      final children = _visibleChildrenCount(node) - 1;
      collapsedNodes.removeRange(nodeIndex, nodeIndex + children);
    }

    for (final node in _allNodes) {
      node.collapse();
    }
    _displayNodes = collapsedNodes;
    _visibleChildrenCountCache.clear(); // Очищаем кэш после массового изменения
    notifyListeners();
  }

  /// Expands the given `node` so its children become visible.
  ///
  /// This will change the `node` [NodeViewModelState.isCollapsed] property to
  /// false. But its children won't change states, so when the node is expanded
  /// its children states are unchanged.
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  ///
  /// See also:
  /// * `collapseNode`
  void expandNode(NodeViewModelState node) {
    if (!node.isCollapsed || !node.isRoot) {
      return;
    }

    final nodeIndex = _displayNodes.indexOf(node) + 1;
    final nodes = flatten(node.value);
    _displayNodes.insertAll(nodeIndex, nodes);
    node.expand();
    _visibleChildrenCountCache.clear(); // Очищаем кэш после изменения состояния
    notifyListeners();
  }

  /// Expands all nodes.
  ///
  /// This expands every single node of the data structure, meaning that all
  /// nodes will be in the `displayNodes` list.
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  ///
  /// See also:
  /// * `collapseAll`
  void expandAll() {
    for (final node in _allNodes) {
      node.expand();
    }
    _displayNodes = List.from(_allNodes);
    _visibleChildrenCountCache.clear(); // Очищаем кэш после массового изменения
    notifyListeners();
  }

  @override
  void dispose() {
    // Clear caches when disposing the store
    _visibleChildrenCountCache.clear();
    _searchMatchesCache.clear();

    // Cancel any ongoing search
    _currentSearchOperation?.ignore();
    _mounted = false;

    // Dispose all nodes to free up resources
    for (final node in _allNodes) {
      node.dispose();
    }

    super.dispose();
  }

  /// Returns true if all nodes are expanded, otherwise returns false.
  bool areAllExpanded() => _displayNodes.length == _allNodes.length;

  /// Returns true if all nodes are collapsed, otherwise returns false.
  bool areAllCollapsed() {
    // Быстрый выход: если длина _displayNodes равна длине _allNodes, значит есть раскрытые узлы
    if (_displayNodes.length >
        _allNodes.where((node) => node.treeDepth == 0).length) {
      return false;
    }

    // Проверяем только корневые узлы для оптимизации
    for (final node in _displayNodes.where((node) => node.childrenCount > 0)) {
      if (!node.isCollapsed) {
        return false;
      }
    }

    return true;
  }

  /// Executes a search in the current data structure looking for the given
  /// search `term`.
  ///
  /// The search looks for matching terms in both key and values from all nodes.
  /// The results can be retrieved in the `searchResults` lists.
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  void search(String term) {
    // Skip work if the term is the same
    final normalizedTerm = term.toLowerCase();
    if (_searchTerm == normalizedTerm) {
      return;
    }

    _searchTerm = normalizedTerm;
    _searchResults.clear();
    _focusedSearchResultIndex = 0;

    // Cancel any ongoing search operation
    _currentSearchOperation?.ignore();

    // Always notify to show search is in progress
    if (mounted) notifyListeners();

    if (term.isEmpty) {
      return;
    }

    // Debounce search operations
    final now = DateTime.now();
    if (_lastSearchTime != null) {
      final timeSinceLastSearch = now.difference(_lastSearchTime!);
      // Adjust debounce time based on term length and dataset size
      final adjustedDebounceTime = _allNodes.length > 10000 && term.length < 3
          ? _searchDebounceTime + const Duration(milliseconds: 50)
          : _searchDebounceTime;

      if (timeSinceLastSearch < adjustedDebounceTime) {
        Future<void>.delayed(adjustedDebounceTime - timeSinceLastSearch)
            .then((_) {
          // Only proceed if another search hasn't been triggered in the meantime
          if (_searchTerm == normalizedTerm && mounted) {
            _currentSearchOperation = _doSearch();
          }
        });
        return;
      }
    }

    _lastSearchTime = now;
    _currentSearchOperation = _doSearch();
  }

  /// Sets the focus on the next search result.
  ///
  /// Does nothing if there are no results or the last node is already focused.
  ///
  /// If `loop` is `true` and the current focused search result is the last
  /// element of `searchResults`, the first element of [searchResults] is
  /// focused.
  ///
  /// See also:
  /// * `focusPreviousSearchResult`
  void focusNextSearchResult({bool loop = false}) {
    if (searchResults.isEmpty) {
      return;
    }

    if (_focusedSearchResultIndex < _searchResults.length - 1) {
      _focusedSearchResultIndex += 1;
      notifyListeners();
    } else if (loop) {
      _focusedSearchResultIndex = 0;
      notifyListeners();
    }
  }

  /// Sets the focus on the previous search result.
  ///
  /// Does nothing if there are no results or the first node is already focused.
  ///
  /// If `loop` is `true` and the current focused search result is the first
  /// element of `searchResults`, the last element of [searchResults] is
  /// focused.
  ///
  /// See also:
  /// * `focusNextSearchResult`
  void focusPreviousSearchResult({bool loop = false}) {
    if (searchResults.isEmpty) {
      return;
    }

    if (_focusedSearchResultIndex > 0) {
      _focusedSearchResultIndex -= 1;
      notifyListeners();
    } else if (loop) {
      _focusedSearchResultIndex = _searchResults.length - 1;
      notifyListeners();
    }
  }

  /// Uses the given `jsonObject` to build the [displayNodes] list.
  ///
  /// If `areAllCollapsed` is true, then all nodes will be collapsed, and
  /// initially only upper root nodes will be in the list.
  ///
  /// `notifyListeners` is called to notify all registered listeners.
  Future<void> buildNodes(
    Object? jsonObject, {
    bool areAllCollapsed = false,
  }) async {
    // Clear caches first to avoid memory leaks
    _visibleChildrenCountCache.clear();
    _searchMatchesCache.clear();

    // Cancel any ongoing search
    _currentSearchOperation?.ignore();
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

    final builtNodes = buildViewModelNodes(jsonObject);
    final flatList = flatten(builtNodes);

    _allNodes = UnmodifiableListView(flatList);
    _displayNodes = List.from(flatList);
    if (areAllCollapsed) {
      collapseAll();
    } else {
      if (mounted) notifyListeners();
    }
  }

  // Cache for visible children count to avoid recalculating
  final Map<NodeViewModelState, int> _visibleChildrenCountCache = {};

  int _visibleChildrenCount(NodeViewModelState node) {
    // Check if the result is already cached
    if (_visibleChildrenCountCache.containsKey(node)) {
      return _visibleChildrenCountCache[node]!;
    }

    final children = node.children;
    var count = 1;
    for (final child in children) {
      count =
          child.isCollapsed ? count + 1 : count + _visibleChildrenCount(child);
    }

    // Save result to cache
    _visibleChildrenCountCache[node] = count;
    return count;
  }

  Future<void> _doSearch() async {
    // Clear existing results (should already be cleared in search())
    _searchResults.clear();

    // For very small search terms, optimize for speed
    if (_searchTerm.length < 2 && _allNodes.length > 5000) {
      // Prioritize the search to handle large datasets more efficiently
      await _optimizedSearchForShortTerms();
    } else {
      // Standard batch processing for normal cases
      await _processSearchInBatches();
    }
  }

  // Optimized search for short search terms in large datasets
  Future<void> _optimizedSearchForShortTerms() async {
    // Use a larger batch size for short terms since each comparison is faster
    const batchSize = 300;
    final totalNodes = _allNodes.length;
    var processedCount = 0;

    // Cache the search term for faster comparison
    final searchTerm = _searchTerm;

    // Use a more aggressive UI update strategy for short terms
    var nextUIUpdateTime =
        DateTime.now().add(const Duration(milliseconds: 150));
    var resultsFoundSinceLastUpdate = 0;

    while (processedCount < totalNodes && mounted) {
      final end = (processedCount + batchSize).clamp(0, totalNodes);
      final batch = _allNodes.sublist(processedCount, end);

      for (final node in batch) {
        if (!mounted) return;

        // Process key first (most likely to match)
        final nodeKey = node.key;
        if (nodeKey.isNotEmpty) {
          final keyLower = nodeKey.toLowerCase();
          if (keyLower.contains(searchTerm)) {
            _addKeyMatches(node, nodeKey, keyLower);
          }
        }

        // Process value only for leaf nodes
        if (!node.isRoot) {
          final dynamic nodeValue = node.value;
          // Skip null values
          if (nodeValue != null) {
            final valueStr = nodeValue.toString();
            if (valueStr.isNotEmpty) {
              final valueLower = valueStr.toLowerCase();
              if (valueLower.contains(searchTerm)) {
                _addValueMatches(node, valueStr, valueLower);
              }
            }
          }
        }
      }

      processedCount = end;
      resultsFoundSinceLastUpdate = _searchResults.length;

      // Update UI less frequently for short terms (smoother performance)
      final now = DateTime.now();
      if (now.isAfter(nextUIUpdateTime) ||
          resultsFoundSinceLastUpdate >= 20 ||
          processedCount >= totalNodes) {
        if (mounted) notifyListeners();

        // Schedule next update with slightly longer interval
        nextUIUpdateTime = now.add(const Duration(milliseconds: 150));
        resultsFoundSinceLastUpdate = 0;

        // Minimal yield to UI thread
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  // Add key matches with optimized approach
  void _addKeyMatches(
    NodeViewModelState node,
    String originalKey,
    String lowerKey,
  ) {
    final indices = _fastFindAllOccurrences(lowerKey, _searchTerm);
    for (final index in indices) {
      _searchResults.add(
        SearchResult(
          node,
          matchLocation: SearchMatchLocation.key,
          matchIndex: index,
        ),
      );
    }
  }

  // Add value matches with optimized approach
  void _addValueMatches(
    NodeViewModelState node,
    String originalValue,
    String lowerValue,
  ) {
    final indices = _fastFindAllOccurrences(lowerValue, _searchTerm);
    for (final index in indices) {
      _searchResults.add(
        SearchResult(
          node,
          matchLocation: SearchMatchLocation.value,
          matchIndex: index,
        ),
      );
    }
  }

  // Process search in batches to avoid UI jank
  Future<void> _processSearchInBatches() async {
    var processedCount = 0;
    // Adjust batch size based on node complexity and term length
    final batchSize = _allNodes.length > 10000
        ? 80
        : _allNodes.length > 5000
            ? 120
            : 200;
    final totalNodes = _allNodes.length;

    // Schedule when we'll update the UI
    var nextUIUpdateTime = DateTime.now().add(const Duration(milliseconds: 80));
    var resultsFoundSinceLastUpdate = 0;

    // Cache the search term to avoid repeated access
    final searchTerm = _searchTerm;

    while (processedCount < totalNodes && mounted) {
      final end = (processedCount + batchSize).clamp(0, totalNodes);
      final batch = _allNodes.sublist(processedCount, end);
      final initialResultsCount = _searchResults.length;

      // Process this batch
      for (final node in batch) {
        if (!mounted) return;

        // Fast path check for the key
        final nodeKey = node.key;
        if (nodeKey.isNotEmpty) {
          final keyLower = nodeKey.toLowerCase();
          if (keyLower.contains(searchTerm)) {
            final keyMatches = _getSearchTermMatchesIndexes(nodeKey, keyLower);
            for (final matchIndex in keyMatches) {
              _searchResults.add(
                SearchResult(
                  node,
                  matchLocation: SearchMatchLocation.key,
                  matchIndex: matchIndex,
                ),
              );
            }
          }
        }

        // Only process values for non-root nodes (optimization)
        if (!node.isRoot) {
          final dynamic nodeValue = node.value;
          if (nodeValue != null) {
            final valueStr = nodeValue.toString();
            if (valueStr.isNotEmpty) {
              // Cache the lowercase version
              final valueLower = valueStr.toLowerCase();
              if (valueLower.contains(searchTerm)) {
                final valueMatches =
                    _getSearchTermMatchesIndexes(valueStr, valueLower);
                for (final matchIndex in valueMatches) {
                  _searchResults.add(
                    SearchResult(
                      node,
                      matchLocation: SearchMatchLocation.value,
                      matchIndex: matchIndex,
                    ),
                  );
                }
              }
            }
          }
        }
      }

      processedCount = end;
      resultsFoundSinceLastUpdate +=
          _searchResults.length - initialResultsCount;

      // Check if we should update the UI based on time or results count
      final now = DateTime.now();
      if (now.isAfter(nextUIUpdateTime) ||
          resultsFoundSinceLastUpdate >= 15 ||
          processedCount >= totalNodes) {
        if (mounted) notifyListeners();

        // Schedule next update
        nextUIUpdateTime = now.add(const Duration(milliseconds: 80));
        resultsFoundSinceLastUpdate = 0;

        // Yield to UI thread with minimal delay
        // Use Duration.zero which is more efficient than a 1ms delay
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  // Fast algorithm to find all occurrences without using RegExp
  List<int> _fastFindAllOccurrences(String text, String pattern) {
    if (text.isEmpty || pattern.isEmpty) {
      return const <int>[];
    }

    final indices = <int>[];
    var startIndex = 0;

    while (true) {
      final index = text.indexOf(pattern, startIndex);
      if (index == -1) break;
      indices.add(index);
      startIndex =
          index + 1; // Move just one character to find overlapping matches
    }

    return indices;
  }

  /// Finds all occurrences of `searchTerm` in [victim] and retrieves all their
  /// indexes. Takes an optional pre-computed lowercase version of the string.
  List<int> _getSearchTermMatchesIndexes(String victim, [String? victimLower]) {
    // Early return for empty strings to avoid unnecessary work
    if (victim.isEmpty || _searchTerm.isEmpty) {
      return const <int>[];
    }

    // Use provided lowercase or compute it
    final lowerVictim = victimLower ?? victim.toLowerCase();

    // Fast path: if searchTerm isn't in victim, return early
    if (!lowerVictim.contains(_searchTerm)) {
      return const <int>[];
    }

    return _fastFindAllOccurrences(lowerVictim, _searchTerm);
  }

  /// Expands all the parent nodes of each `SearchResult.node` in
  /// `searchResults`.
  void expandSearchResults() {
    for (final searchResult in searchResults) {
      expandParentNodes(searchResult.node);
    }
  }

  /// Expands all the parent nodes of the given `node`.
  void expandParentNodes(NodeViewModelState node) {
    final parent = node.parent;

    if (parent == null) {
      return;
    }

    expandParentNodes(parent);

    expandNode(parent);
  }
}

/// A matched search in the given `node`.
///
/// If the match is registered in the node's key, then `matchLocation` is going
/// to be `SearchMatchLocation.key`.
///
/// If the match is in the value, then `matchLocation` is
/// `SearchMatchLocation.value`.
class SearchResult {
  const SearchResult(
    this.node, {
    required this.matchLocation,
    required this.matchIndex,
  });
  final NodeViewModelState node;
  final SearchMatchLocation matchLocation;
  final int matchIndex;
}

/// The location of the search match in a node.
///
/// Can be in the node's key or in the node's value.
enum SearchMatchLocation {
  key,
  value,
}
