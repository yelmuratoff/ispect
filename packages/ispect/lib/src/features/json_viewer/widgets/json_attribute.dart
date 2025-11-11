import 'package:flutter/material.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/services/value_style_cache.dart';
import 'package:ispect/src/features/json_viewer/theme.dart';
import 'package:ispect/src/features/json_viewer/widgets/controller/store.dart';
import 'package:ispect/src/features/json_viewer/widgets/explorer.dart';
import 'package:ispect/src/features/json_viewer/widgets/json_card.dart';
import 'package:ispect/src/features/json_viewer/widgets/rendering/primitives.dart';
import 'package:ispect/src/features/json_viewer/widgets/rendering/property_node_widget.dart';
import 'package:ispect/src/features/json_viewer/widgets/rendering/root_node_widget.dart';
import 'package:ispect/src/features/json_viewer/widgets/store_selector.dart';

class JsonAttribute extends StatefulWidget {
  const JsonAttribute({
    required this.node,
    required this.store,
    required this.theme,
    super.key,
    this.rootInformationBuilder,
    this.collapsableToggleBuilder,
    this.trailingBuilder,
    this.rootNameFormatter,
    this.propertyNameFormatter,
    this.valueFormatter,
    this.valueStyleBuilder,
    this.itemSpacing = 4,
    this.maxRootNodeWidth,
  });

  /// Node to be displayed.
  final NodeViewModelState node;
  final JsonExplorerStore store;

  /// A builder to add a widget as a suffix for root nodes.
  ///
  /// This can be used to display useful information such as the number of
  /// children nodes, or to indicate if the node is class or an array
  /// for example.
  final NodeBuilder? rootInformationBuilder;

  /// Build the expand/collapse icons in root nodes.
  ///
  /// If this builder is null, a material `Icons.arrow_right` is displayed for
  /// collapsed nodes and `Icons.arrow_drop_down` for expanded nodes.
  final NodeBuilder? collapsableToggleBuilder;

  /// A builder to add a trailing widget in each node.
  ///
  /// This widget is added to the end of the node on top of the content.
  final NodeBuilder? trailingBuilder;

  /// Customizes how class/array names are formatted as string.
  ///
  /// By default the class and array names are displayed as follows: 'name:'
  final Formatter? rootNameFormatter;

  /// Customizes how property names are formatted as string.
  ///
  /// By default the property names are displayed as follows: 'name:'
  final Formatter? propertyNameFormatter;

  /// Customizes how property values are formatted as string.
  ///
  /// By default the value is converted to a string by calling the .toString()
  /// method.
  final Formatter? valueFormatter;

  /// Customizes a property style and interaction based on its value.
  ///
  /// See also:
  /// * `StyleBuilder`
  final StyleBuilder? valueStyleBuilder;

  /// Sets the spacing between each list item.
  final double itemSpacing;

  /// Theme used to render this widget.
  final JsonExplorerTheme theme;

  /// Maximum width for root nodes, will wrap if exceeded
  final double? maxRootNodeWidth;

  @override
  State<JsonAttribute> createState() => _JsonAttributeState();
}

class _JsonAttributeState extends State<JsonAttribute> {
  // Static constants for reuse
  static const _kEmptyWidget = SizedBox.shrink();
  static const _kLeftPadding = EdgeInsets.only(left: 4);
  static const _kBottomPadding = EdgeInsets.only(bottom: 4);

  // Cached expensive computations
  final ValueStyleCache _valueStyleCache = ValueStyleCache();

  @override
  void didUpdateWidget(JsonAttribute oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear cache if node or relevant properties changed
    if (oldWidget.node != widget.node ||
        oldWidget.valueStyleBuilder != widget.valueStyleBuilder ||
        oldWidget.theme != widget.theme) {
      _valueStyleCache.invalidate();
    }
  }

  PropertyOverrides get _valueStyle => _valueStyleCache.resolveValueStyle(
        value: widget.node.value,
        defaultStyle: widget.theme.valueTextStyle,
        styleBuilder: widget.valueStyleBuilder,
      );

  bool get _hasInteraction => _valueStyleCache.resolveHasInteraction(
        isRoot: widget.node.isRoot,
        valueStyle: _valueStyle,
      );

  @override
  Widget build(BuildContext context) => JsonStoreSelector<
          ({
            String searchTerm,
            bool hasSearchResults,
            int? focusedKeyMatchIndex,
            int? focusedValueMatchIndex,
          })>(
        store: widget.store,
        selector: (store) {
          final hasResults = store.searchResults.isNotEmpty;
          int? focusedKeyIndex;
          int? focusedValueIndex;

          if (hasResults && store.focusedSearchResult.node == widget.node) {
            switch (store.focusedSearchResult.matchLocation) {
              case SearchMatchLocation.key:
                focusedKeyIndex = store.focusedSearchResult.matchIndex;
              case SearchMatchLocation.value:
                focusedValueIndex = store.focusedSearchResult.matchIndex;
            }
          }

          return (
            searchTerm: store.searchTerm,
            hasSearchResults: hasResults,
            focusedKeyMatchIndex: focusedKeyIndex,
            focusedValueMatchIndex: focusedValueIndex,
          );
        },
        builder: (context, searchData) {
          final valueStyle = _valueStyle;

          return MouseRegion(
            cursor: switch (_hasInteraction) {
              true => SystemMouseCursors.click,
              false => MouseCursor.defer,
            },
            onEnter: (_) => _handleMouseEnter(),
            onExit: (_) => _handleMouseExit(),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _hasInteraction
                  ? () => _handleTap(context, valueStyle)
                  : null,
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: widget.node,
                  builder: (context, _) => Padding(
                    padding: _kBottomPadding,
                    child: Row(
                      crossAxisAlignment: widget.node.isRoot
                          ? CrossAxisAlignment.center
                          : CrossAxisAlignment.start,
                      children: [
                        SelectionContainer.disabled(
                          child: IndentationWidget(
                            depth: widget.node.treeDepth,
                            indentationPadding: widget.theme.indentationPadding,
                            color: widget.theme.indentationLineColor,
                          ),
                        ),
                        _buildToggleForNode(),
                        _buildNodeKey(
                          context,
                          searchData.searchTerm,
                          searchData.hasSearchResults,
                          searchData.focusedKeyMatchIndex,
                        ),
                        const SizedBox(width: 8, child: KeySeparatorText()),
                        _buildSuffixForValue(widget.node.value),
                        if (widget.node.isRoot)
                          SelectionContainer.disabled(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: CopyButton(
                                node: widget.node,
                                theme: widget.theme,
                              ),
                            ),
                          ),
                        _buildValueOrRootInfo(
                          context,
                          searchData.searchTerm,
                          searchData.hasSearchResults,
                          searchData.focusedValueMatchIndex,
                          valueStyle,
                        ),
                        if (widget.trailingBuilder != null)
                          widget.trailingBuilder!(context, widget.node),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );

  void _handleMouseEnter() {
    widget.node
      ..highlight()
      ..focus();
  }

  void _handleMouseExit() {
    widget.node
      ..highlight(isHighlighted: false)
      ..focus(isFocused: false);
  }

  void _handleTap(BuildContext context, PropertyOverrides valueStyle) {
    if (valueStyle.onTap != null) {
      valueStyle.onTap!();
    } else {
      _onNodeTap(context);
    }
  }

  Widget _buildNodeKey(
    BuildContext context,
    String searchTerm,
    bool hasSearchResults,
    int? focusedMatchIndex,
  ) {
    final nodeKey = RootNodeWidget(
      key: ValueKey('${widget.node.key}-${widget.node.isRoot}'),
      node: widget.node,
      rootNameFormatter: widget.rootNameFormatter,
      propertyNameFormatter: widget.propertyNameFormatter,
      searchTerm: searchTerm,
      theme: widget.theme,
      hasSearchResults: hasSearchResults,
      focusedSearchMatchIndex: focusedMatchIndex,
    );
    final jsonCard = JsonCard(
      backgroundColor: widget.theme.rootKeyTextStyle.color,
      child: nodeKey,
    );

    return switch (widget.maxRootNodeWidth) {
      null => jsonCard,
      final v => Flexible(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: v),
            child: jsonCard,
          ),
        ),
    };
  }

  Widget _buildRootInformation(BuildContext context) => Padding(
        padding: _kLeftPadding,
        child: widget.rootInformationBuilder?.call(context, widget.node) ??
            _kEmptyWidget,
      );

  Widget _buildPropertyValue(
    BuildContext context,
    String searchTerm,
    bool hasSearchResults,
    int? focusedMatchIndex,
    PropertyOverrides valueStyle,
  ) =>
      Expanded(
        flex: 10,
        child: PropertyNodeWidget(
          key: ValueKey('value-${widget.node.key}'),
          node: widget.node,
          searchTerm: searchTerm,
          valueFormatter: widget.valueFormatter,
          style: valueStyle.style,
          searchHighlightStyle: widget.theme.valueSearchHighlightTextStyle,
          focusedSearchHighlightStyle:
              widget.theme.focusedValueSearchHighlightTextStyle,
          hasSearchResults: hasSearchResults,
          focusedSearchMatchIndex: focusedMatchIndex,
        ),
      );

  void _onNodeTap(BuildContext context) {
    if (!widget.node.isRoot) return;
    switch (widget.node.isCollapsed) {
      case true:
        widget.store.expandNode(widget.node);
      case false:
        widget.store.collapseNode(widget.node);
    }
  }

  Widget _buildToggleForNode() => switch (
        (widget.node.isRoot, widget.node.children.isNotEmpty)) {
        (true, true) => const SelectionContainer.disabled(
            child: SizedBox(width: 24, child: ToggleButton()),
          ),
        _ => _kEmptyWidget,
      };

  Widget _buildValueOrRootInfo(
    BuildContext context,
    String searchTerm,
    bool hasSearchResults,
    int? focusedMatchIndex,
    PropertyOverrides valueStyle,
  ) =>
      switch (widget.node.isRoot) {
        true => _buildRootInformation(context),
        false => _buildPropertyValue(
            context,
            searchTerm,
            hasSearchResults,
            focusedMatchIndex,
            valueStyle,
          ),
      };

  Widget _buildSuffixForValue(Object? value) => switch (value) {
        List<Object?> _ => ArraySuffixWidget(
            length: widget.node.children.length,
            style: widget.theme.rootKeyTextStyle,
          ),
        Map<Object?, Object?> _ || Set<Object?> _ => MapSuffixWidget(
            length: widget.node.children.length,
            style: widget.theme.rootKeyTextStyle,
          ),
        _ => _kEmptyWidget,
      };
}

// Rendering and search widgets moved to rendering/ and search/ directories.
