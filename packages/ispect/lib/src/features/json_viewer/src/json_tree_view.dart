// ignore_for_file: prefer_foreach, avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/json_viewer/src/json_tree_node.dart';
import 'package:ispect/src/features/json_viewer/src/models/json_node.dart';
import 'package:ispect/src/features/json_viewer/src/utils/json_parser.dart';

/// A widget that renders a collapsible and searchable JSON tree view.
///
/// The [JsonTreeView] recursively displays a JSON map structure as an
/// interactive tree of expandable/collapsible nodes. It also includes a built-in
/// search bar (optional) that highlights and expands nodes containing matching
/// keys or values.
///
/// ### Features:
/// - Expand/collapse individual or all nodes
/// - Built-in animated transitions
/// - Optional search with highlight and auto-expand
/// - Customizable styling (key/value text, padding, spacing, icons)
///
/// ### Parameters:
/// - [json]: The JSON map to display. Must be a valid `Map<String, dynamic>`.
/// - [expandIcon]: Icon widget shown when a node is collapsed.
/// - [collapseIcon]: Icon widget shown when a node is expanded.
/// - [keyStyle]: Custom [TextStyle] for JSON keys.
/// - [valueStyle]: Custom [TextStyle] for JSON values.
/// - [initiallyExpanded]: Whether all nodes should be expanded on first render.
/// - [onExpandedChanged]: Optional callback triggered when all nodes are expanded or collapsed.
/// - [animationDuration]: Duration of node expand/collapse animations.
/// - [showControls]: Reserved for future use (e.g., expand/collapse buttons).
/// - [enableSearch]: Enables the search bar at the top of the widget.
/// - [searchHighlightColor]: Highlight color used for matched search results.
/// - [backgroundColor]: Background color for the widget container.
/// - [indentWidth]: Left padding (per depth level) applied to child nodes.
/// - [nodeSpacing]: Vertical spacing between sibling nodes.
/// - [nodePadding]: Inner padding applied to each node row.
///
/// ### Example:
/// ```dart
/// JsonTreeView(
///   json: {
///     'name': 'Alice',
///     'address': {
///       'city': 'Almaty',
///       'zip': '050000',
///     },
///     'skills': ['Flutter', 'Dart'],
///   },
///   keyStyle: const TextStyle(fontWeight: FontWeight.bold),
///   initiallyExpanded: false,
/// )
/// ```
///
/// ### Edge Cases:
/// - If [json] is empty, an empty node will be shown.
/// - If [json] is invalid or parsing fails, a fallback error node is displayed.
/// - If [initiallyExpanded] is `true`, the entire tree will be expanded on load.

class JsonTreeView extends StatefulWidget {
  const JsonTreeView({
    required this.json,
    super.key,
    this.expandIcon,
    this.collapseIcon,
    this.keyStyle,
    this.valueStyle,
    this.initiallyExpanded = true,
    this.onExpandedChanged,
    this.animationDuration = const Duration(milliseconds: 200),
    this.showControls = false,
    this.enableSearch = true,
    this.searchHighlightColor = const Color(0xFFFFEB3B),
    this.backgroundColor,
    this.indentWidth = 6.0,
    this.nodeSpacing = 0.0,
    this.nodePadding = const EdgeInsets.symmetric(vertical: 2),
  });

  final Map<String, dynamic> json;
  final Widget? expandIcon;
  final Widget? collapseIcon;
  final TextStyle? keyStyle;
  final TextStyle? valueStyle;
  final bool initiallyExpanded;
  final void Function(bool isExpanded)? onExpandedChanged;
  final Duration animationDuration;
  final bool showControls;
  final bool enableSearch;
  final Color searchHighlightColor;
  final Color? backgroundColor;
  final double indentWidth;
  final double nodeSpacing;
  final EdgeInsets nodePadding;

  @override
  JsonTreeViewState createState() => JsonTreeViewState();
}

class JsonTreeViewState extends State<JsonTreeView> {
  late JsonNode _rootNode;
  final Map<String, bool> _expandedNodes = {};
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _searchMatchedNodes = {};

  @override
  void initState() {
    super.initState();
    _parseJson();
  }

  @override
  void didUpdateWidget(JsonTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.json != oldWidget.json) {
      _resetState();
      _parseJson();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetState() {
    _searchController.clear();
    _searchQuery = '';
    _searchMatchedNodes.clear();
    _expandedNodes.clear();
  }

  @override
  Widget build(BuildContext context) => SelectionArea(
        child: Container(
          color: widget.backgroundColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.enableSearch) _buildSearchBar(context),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _buildNode(_rootNode),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  /// Parses the provided JSON map into a [JsonNode] tree structure.
  ///
  /// This method uses [JsonParser.parse] to transform the JSON object into a
  /// tree of [JsonNode]s. If the input is empty, it defaults to parsing an
  /// empty object (`{}`). If parsing fails, it catches the exception and
  /// constructs an error node with the exception details.
  ///
  /// Additionally, if [widget.initiallyExpanded] is `true`, the method will
  /// recursively mark all nodes as expanded using [_setExpandedRecursive].
  ///
  /// Edge Cases:
  /// - Handles empty JSON input by parsing an empty map.
  /// - Gracefully handles parsing errors by creating a fallback error node.
  void _parseJson() {
    try {
      _rootNode = widget.json.isEmpty
          ? JsonParser.parse({})
          : JsonParser.parse(widget.json);
    } catch (e) {
      _rootNode = JsonParser.parse({
        'error': 'Invalid JSON string',
        'details': e.toString(),
      });
    }
    if (widget.initiallyExpanded) {
      _setExpandedRecursive(_rootNode, true);
    }
  }

  /// Recursively updates the expansion state of a [JsonNode] and its descendants.
  ///
  /// This method sets the expansion state of the given [node] to [expanded],
  /// and then traverses its child nodes to apply the same expansion state
  /// recursively. The state is tracked in the [_expandedNodes] map using
  /// each node's unique key.
  ///
  /// - [node]: The root [JsonNode] to start expanding or collapsing from.
  /// - [expanded]: If `true`, all nodes will be marked as expanded; otherwise collapsed.
  ///
  /// Example usage:
  /// ```dart
  /// _setExpandedRecursive(rootNode, true); // expands entire tree
  /// _setExpandedRecursive(rootNode, false); // collapses entire tree
  /// ```
  void _setExpandedRecursive(JsonNode node, bool expanded) {
    _expandedNodes[node.key] = expanded;
    for (final child in node.children) {
      _setExpandedRecursive(child, expanded);
    }
  }

  /// Expands all nodes in the JSON tree view.
  ///
  /// Internally calls [_setExpandedRecursive] with `true` on the root node to
  /// recursively expand all nodes. Then triggers a rebuild via [setState]
  /// and invokes [widget.onExpandedChanged] with `true` if the callback is provided.
  ///
  /// Example usage:
  /// ```dart
  /// _expandAll(); // expands entire JSON tree
  /// ```
  void _expandAll() {
    _setExpandedRecursive(_rootNode, true);
    setState(() {});
    widget.onExpandedChanged?.call(true);
  }

  /// Collapses all nodes in the JSON tree view.
  ///
  /// Clears the [_expandedNodes] map to mark all nodes as collapsed,
  /// then triggers a rebuild via [setState]. If [widget.onExpandedChanged]
  /// is provided, it will be called with `false` to signal the collapse event.
  ///
  /// Example usage:
  /// ```dart
  /// _collapseAll(); // collapses entire JSON tree
  /// ```
  void _collapseAll() {
    _expandedNodes.clear();
    setState(() {});
    widget.onExpandedChanged?.call(false);
  }

  /// Handles search input and updates the tree view with matching nodes.
  ///
  /// Converts the [query] to lowercase and stores it in [_searchQuery],
  /// then clears the previous search results in [_searchMatchedNodes].
  ///
  /// If the query is not empty:
  /// - Traverses the JSON tree to find nodes that match the query using [_searchNodes].
  /// - Automatically expands all parent nodes of matching nodes via [_expandMatchedNodes].
  ///
  /// Finally, triggers a UI rebuild via [setState] to reflect the updated state.
  ///
  /// - [query]: The search string entered by the user.
  void _handleSearch(String query) {
    _searchQuery = query.toLowerCase();
    _searchMatchedNodes.clear();

    if (_searchQuery.isNotEmpty) {
      _searchNodes(_rootNode);
      _expandMatchedNodes();
    }

    setState(() {});
  }

  /// Recursively searches the JSON tree for nodes matching the search query.
  ///
  /// Checks whether the current [node] matches the search criteria using
  /// [_nodeMatchesSearch], and if so, adds its key to [_searchMatchedNodes].
  ///
  /// Then recursively searches all child nodes. If any child or the current
  /// node matches the query, returns `true` to signal a match exists in the subtree.
  ///
  /// - [node]: The [JsonNode] to search from.
  /// - Returns: `true` if the node or any of its descendants match the search query.
  bool _searchNodes(JsonNode node) {
    var hasMatch = _nodeMatchesSearch(node);
    if (hasMatch) _searchMatchedNodes.add(node.key);

    for (final child in node.children) {
      if (_searchNodes(child)) hasMatch = true;
    }

    return hasMatch;
  }

  /// Determines whether a [JsonNode] matches the current search query.
  ///
  /// A node is considered a match if either its key or stringified value
  /// contains the [_searchQuery] substring (case-insensitive).
  ///
  /// - [node]: The node to evaluate against the current search query.
  /// - Returns: `true` if the node's key or value matches the query.
  bool _nodeMatchesSearch(JsonNode node) =>
      node.key.toLowerCase().contains(_searchQuery) ||
      node.value.toString().toLowerCase().contains(_searchQuery);

  /// Expands all nodes that match the search query, including their parent chains.
  ///
  /// This method traverses the entire JSON tree starting from [_rootNode].
  /// For every node whose key exists in [_searchMatchedNodes], it calls
  /// [_expandNodeAndParents] to ensure that not only the matching node,
  /// but all of its ancestor nodes are expanded.
  ///
  /// This ensures that search results are visible in the tree view.
  ///
  /// Example:
  /// ```dart
  /// _expandMatchedNodes(); // makes all matching nodes and their parents visible
  /// ```
  void _expandMatchedNodes() {
    void expandParents(JsonNode node) {
      if (_searchMatchedNodes.contains(node.key)) {
        _expandNodeAndParents(node);
      }
      for (final child in node.children) {
        expandParents(child);
      }
    }

    expandParents(_rootNode);
  }

  /// Expands the given node and all of its ancestor nodes in the JSON tree.
  ///
  /// This method traverses upward through the key hierarchy of the given [node],
  /// setting each corresponding key in [_expandedNodes] to `true`.
  ///
  /// It assumes that nested keys are dot-delimited (e.g., `parent.child.grandchild`)
  /// and works by progressively trimming the key string at each dot to identify parents.
  ///
  /// - [node]: The [JsonNode] whose ancestors should be expanded.
  ///
  /// Example:
  /// ```dart
  /// _expandNodeAndParents(node); // makes the node and its parent hierarchy visible
  /// ```
  void _expandNodeAndParents(JsonNode node) {
    var currentKey = node.key;
    while (currentKey.isNotEmpty) {
      _expandedNodes[currentKey] = true;
      final lastDotIndex = currentKey.lastIndexOf('.');
      if (lastDotIndex == -1) break;
      currentKey = currentKey.substring(0, lastDotIndex);
    }
  }

  /// Builds a visual representation of a [JsonNode] in the JSON tree view.
  ///
  /// This method creates a [JsonTreeNode] widget to display the key-value pair,
  /// along with an expandable section for its children using [AnimatedCrossFade].
  ///
  /// The node's expansion state is retrieved from [_expandedNodes], and search
  /// highlighting is applied if the node's key exists in [_searchMatchedNodes].
  ///
  /// - [node]: The [JsonNode] to render.
  /// - [depth]: The depth of the node in the tree, used for indentation (default is 0).
  ///
  /// Returns a [Widget] representing the current node and its child subtree.
  ///
  /// Example:
  /// ```dart
  /// final rootWidget = _buildNode(_rootNode);
  /// ```

  Widget _buildNode(JsonNode node, [int depth = 0]) {
    final isExpanded = _expandedNodes[node.key] ?? false;
    final isMatched =
        _searchQuery.isNotEmpty && _searchMatchedNodes.contains(node.key);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JsonTreeNode(
          keyName: node.key,
          value: node.value,
          isExpanded: isExpanded,
          onTap: () => setState(() {
            _expandedNodes[node.key] = !isExpanded;
          }),
          keyStyle: widget.keyStyle,
          valueStyle: widget.valueStyle,
          expandIcon: widget.expandIcon,
          collapseIcon: widget.collapseIcon,
          depth: depth,
          type: node.type,
          animationDuration: widget.animationDuration,
          isHighlighted: isMatched,
          highlightColor: widget.searchHighlightColor,
          searchQuery: _searchQuery,
          padding: widget.nodePadding,
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildChildren(node, depth),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: widget.animationDuration,
        ),
      ],
    );
  }

  /// Builds a column of child widgets for a given [JsonNode].
  ///
  /// Each child node is rendered using [_buildNode], with indentation and
  /// spacing applied according to [widget.indentWidth] and [widget.nodeSpacing].
  /// This method is typically used inside an [AnimatedCrossFade] to show
  /// children when a node is expanded.
  ///
  /// - [node]: The parent [JsonNode] whose children will be rendered.
  /// - [depth]: The current depth level in the tree, used for recursion.
  ///
  /// Returns a padded [Column] widget containing all child nodes.

  Widget _buildChildren(JsonNode node, int depth) => Padding(
        padding: EdgeInsets.only(left: widget.indentWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: node.children
              .map(
                (child) => Padding(
                  padding: EdgeInsets.only(top: widget.nodeSpacing),
                  child: _buildNode(child, depth + 1),
                ),
              )
              .toList(),
        ),
      );

  /// Builds the search bar widget used to filter the JSON tree nodes.
  ///
  /// This method wraps a [SearchBar] with padding and applies styling such as
  /// minimum height, rounded corners, and a search icon. The search input is
  /// linked to [_searchController], and user input triggers [_handleSearch].
  ///
  /// Also triggers `ISpect.read(context)` for localization or theming support.
  ///
  /// - [context]: The current [BuildContext], used for localization access.
  ///
  /// Returns a styled [SearchBar] wrapped in a [Padding] widget.

  Widget _buildSearchBar(BuildContext context) {
    ISpect.read(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SearchBar(
        controller: _searchController,
        constraints: const BoxConstraints(minHeight: 45),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        leading: const Icon(Icons.search_rounded),
        elevation: WidgetStateProperty.all(0),
        hintText: context.ispectL10n.search,
        onChanged: _handleSearch,
      ),
    );
  }
}

/// Extension on [GlobalKey] to provide external access to expand/collapse all functionality
/// of the [JsonTreeViewState].
///
/// This allows parent widgets to control the expansion state of the JSON tree
/// by calling `expandAll()` or `collapseAll()` directly on the key.
///
/// Example:
/// ```dart
/// final treeKey = GlobalKey<JsonTreeViewState>();
/// ...
/// treeKey.expandAll();   // Expands all nodes
/// treeKey.collapseAll(); // Collapses all nodes
/// ```

extension JsonTreeViewStateExtension on GlobalKey<JsonTreeViewState> {
  void expandAll() => currentState?._expandAll();
  void collapseAll() => currentState?._collapseAll();
}
