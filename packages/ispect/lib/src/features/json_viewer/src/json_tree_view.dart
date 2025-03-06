// ignore_for_file: prefer_foreach, avoid_positional_boolean_parameters

import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/extensions/context.dart';
import 'package:ispect/src/features/json_viewer/src/json_tree_node.dart';
import 'package:ispect/src/features/json_viewer/src/models/json_node.dart';
import 'package:ispect/src/features/json_viewer/src/utils/json_parser.dart';

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
  final _searchController = TextEditingController();
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

  void _setExpandedRecursive(JsonNode node, bool expanded) {
    _expandedNodes[node.key] = expanded;
    for (final child in node.children) {
      _setExpandedRecursive(child, expanded);
    }
  }

  void _expandAll() {
    setState(() => _setExpandedRecursive(_rootNode, true));
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
    var hasMatch = _nodeMatchesSearch(node);
    if (hasMatch) _searchMatchedNodes.add(node.key);
    for (final child in node.children) {
      if (_searchNodes(child)) hasMatch = true;
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

  Widget _buildSearchBar() {
    final theme = Theme.of(context);
    ISpect.read(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: TextFormField(
        controller: _searchController,
        style: theme.textTheme.bodyLarge!.copyWith(
          color: context.ispectTheme.textColor,
          fontSize: 14,
        ),
        onChanged: _handleSearch,
        cursorColor: context.isDarkMode
            ? context.ispectTheme.colorScheme.primaryContainer
            : context.ispectTheme.colorScheme.primary,
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        decoration: InputDecoration(
          fillColor: theme.cardColor,
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: context.isDarkMode
                  ? context.ispectTheme.colorScheme.primaryContainer
                  : context.ispectTheme.colorScheme.primary,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: ISpect.read(context).theme.dividerColor(context) ??
                  context.ispectTheme.dividerColor,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: ISpect.read(context).theme.dividerColor(context) ??
                  context.ispectTheme.dividerColor,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(10)),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: Icon(
            Icons.search,
            color: context.isDarkMode
                ? context.ispectTheme.colorScheme.primaryContainer
                : context.ispectTheme.colorScheme.primary,
            size: 20,
          ),
          hintText: context.ispectL10n.search,
          hintStyle: theme.textTheme.bodyLarge!.copyWith(
            color: context.ispectTheme.hintColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

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
          onTap: () => setState(() => _expandedNodes[node.key] = !isExpanded),
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
          secondChild: Padding(
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
          ),
          crossFadeState:
              isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: widget.animationDuration,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => SelectionArea(
        child: Container(
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
        ),
      );
}

extension JsonTreeViewStateExtension on GlobalKey<JsonTreeViewState> {
  void expandAll() => currentState?._expandAll();
  void collapseAll() => currentState?._collapseAll();
}
