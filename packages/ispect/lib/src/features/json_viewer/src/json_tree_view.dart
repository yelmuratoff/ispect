// ignore_for_file: avoid_positional_boolean_parameters, prefer_foreach, inference_failure_on_collection_literal

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ispect/src/features/json_viewer/src/json_tree_node.dart';
import 'package:ispect/src/features/json_viewer/src/models/json_node.dart';
import 'package:ispect/src/features/json_viewer/src/utils/json_parser.dart';

class JsonTreeView extends StatefulWidget {
  //

  const JsonTreeView({
    required this.jsonString,
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
    this.searchHintText = 'Search...',
    this.backgroundColor,
    this.indentWidth = 24.0,
    this.nodeSpacing = 4.0,
    this.nodePadding = const EdgeInsets.symmetric(vertical: 4),
  });

  final String jsonString;

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
  final String searchHintText;

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(JsonTreeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.jsonString != oldWidget.jsonString) {
      _searchController.clear();
      _searchQuery = '';
      _searchMatchedNodes.clear();
      _expandedNodes.clear();
      _parseJson();
    }
  }

  void _parseJson() {
    if (widget.jsonString.trim().isEmpty) {
      _rootNode = JsonParser.parse({});
      return;
    }

    try {
      final dynamic jsonData = json.decode(widget.jsonString);
      _rootNode = JsonParser.parse(jsonData);
      if (widget.initiallyExpanded) {
        _expandAllNodesWithoutSetState(_rootNode);
      }
    } catch (e) {
      _rootNode = JsonParser.parse(
        {'error': 'Invalid JSON string', 'details': e.toString()},
      );
    }
  }

  void _expandAllNodesWithoutSetState(JsonNode node) {
    _expandedNodes[node.key] = true;
    for (final child in node.children) {
      _expandAllNodesWithoutSetState(child);
    }
  }

  void _expandAll() {
    setState(() {
      _expandAllNodes(_rootNode);
    });
    widget.onExpandedChanged?.call(true);
  }

  void _collapseAll() {
    setState(_expandedNodes.clear);
    widget.onExpandedChanged?.call(false);
  }

  void _handleSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _searchMatchedNodes.clear();
      if (_searchQuery.isNotEmpty) {
        _searchNodes(_rootNode);

        _expandMatchedNodes();
      }
    });
  }

  bool _searchNodes(JsonNode node) {
    var hasMatch = false;

    if (_nodeMatchesSearch(node)) {
      _searchMatchedNodes.add(node.key);
      hasMatch = true;
    }

    for (final child in node.children) {
      if (_searchNodes(child)) {
        hasMatch = true;
      }
    }

    return hasMatch;
  }

  bool _nodeMatchesSearch(JsonNode node) =>
      node.key.toLowerCase().contains(_searchQuery) ||
      node.value.toString().toLowerCase().contains(_searchQuery);

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

  void _expandNodeAndParents(JsonNode node) {
    var currentKey = node.key;
    while (currentKey.isNotEmpty) {
      _expandedNodes[currentKey] = true;

      final lastDotIndex = currentKey.lastIndexOf('.');
      if (lastDotIndex == -1) break;
      currentKey = currentKey.substring(0, lastDotIndex);
    }
  }

  void _expandAllNodes(JsonNode node) {
    _expandedNodes[node.key] = true;
    for (final child in node.children) {
      _expandAllNodes(child);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
        color: widget.backgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.enableSearch) _buildSearchBar(),
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
      );

  Widget _buildSearchBar() => Padding(
        padding: const EdgeInsets.all(8),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.searchHintText,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _handleSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _handleSearch,
        ),
      );

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
          onTap: () => _toggleNode(node.key),
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
          padding: widget.nodePadding, // 传递节点内边距
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: EdgeInsets.only(left: widget.indentWidth), // 使用配置的缩进宽度
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: node.children
                  .map(
                    (child) => Padding(
                      padding:
                          EdgeInsets.only(top: widget.nodeSpacing), // 添加节点间距
                      child: _buildNode(child, depth + 1),
                    ),
                  )
                  .toList(),
            ),
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: widget.animationDuration,
        ),
      ],
    );
  }

  void _toggleNode(String key) {
    setState(() {
      _expandedNodes[key] = !(_expandedNodes[key] ?? false);
    });
  }
}

extension JsonTreeViewStateExtension on GlobalKey<JsonTreeViewState> {
  void expandAll() {
    currentState?._expandAll();
  }

  void collapseAll() {
    currentState?._collapseAll();
  }
}
