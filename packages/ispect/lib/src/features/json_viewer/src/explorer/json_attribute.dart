import 'package:flutter/material.dart';
import 'package:ispect/src/common/widgets/gap/gap.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/json_viewer/src/explorer/explorer.dart';
import 'package:ispect/src/features/json_viewer/src/explorer/json_item_card.dart';
import 'package:ispect/src/features/json_viewer/src/explorer/store.dart';
import 'package:ispect/src/features/json_viewer/src/explorer/theme.dart';
import 'package:ispect/src/features/json_viewer/src/utils/colors.dart';
import 'package:provider/provider.dart';

class JsonAttribute extends StatelessWidget {
  const JsonAttribute({
    required this.node,
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

  /// A builder to add a widget as a suffix for root nodes.
  ///
  /// This can be used to display useful information such as the number of
  /// children nodes, or to indicate if the node is class or an array
  /// for example.
  final NodeBuilder? rootInformationBuilder;

  /// Build the expand/collapse icons in root nodes.
  ///
  /// If this builder is null, a material [Icons.arrow_right] is displayed for
  /// collapsed nodes and [Icons.arrow_drop_down] for expanded nodes.
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
  /// * [StyleBuilder]
  final StyleBuilder? valueStyleBuilder;

  /// Sets the spacing between each list item.
  final double itemSpacing;

  /// Theme used to render this widget.
  final JsonExplorerTheme theme;

  /// Maximum width for root nodes, will wrap if exceeded
  final double? maxRootNodeWidth;

  // Static constants for reuse
  static const _kEmptyWidget = SizedBox.shrink();
  static const _kLeftPadding = EdgeInsets.only(left: 4);
  static const _kBottomPadding = EdgeInsets.only(bottom: 4);

  @override
  Widget build(BuildContext context) {
    // Combine provider lookups to reduce rebuilds
    final storeData = context.select<JsonExplorerStore, ({String searchTerm})>(
      (store) => (searchTerm: store.searchTerm),
    );
    final searchTerm = storeData.searchTerm;

    // Memoize style calculation
    final valueStyle = valueStyleBuilder?.call(
          node.value,
          theme.valueTextStyle,
        ) ??
        PropertyOverrides(style: theme.valueTextStyle);

    final hasInteraction = node.isRoot || valueStyle.onTap != null;

    return MouseRegion(
      cursor: hasInteraction ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (_) => _handleMouseEnter(),
      onExit: (_) => _handleMouseExit(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hasInteraction ? () => _handleTap(context, valueStyle) : null,
        child: AnimatedBuilder(
          animation: node,
          builder: (context, _) => RepaintBoundary(
            child: _buildNodeContent(context, searchTerm, valueStyle),
          ),
        ),
      ),
    );
  }

  void _handleMouseEnter() {
    node
      ..highlight()
      ..focus();
  }

  void _handleMouseExit() {
    node
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

  Widget _buildNodeContent(
    BuildContext context,
    String searchTerm,
    PropertyOverrides valueStyle,
  ) =>
      Padding(
        padding: _kBottomPadding,
        child: Row(
          crossAxisAlignment: node.isRoot
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            _buildIndentation(),
            if (node.isRoot) _buildToggleButton(context),
            _buildNodeKey(context, searchTerm),
            _buildKeySeparator(),
            if (node.value is List) _buildArraySuffix(),
            if (node.value is Map) _buildMapSuffix(),
            if (node.isRoot)
              _buildRootInformation(context)
            else
              _buildPropertyValue(context, searchTerm, valueStyle),
            if (trailingBuilder != null) trailingBuilder!(context, node),
          ],
        ),
      );

  Widget _buildIndentation() {
    final double indentation;

    // Memoize calculation for better performance and readability
    if (node.treeDepth > 0) {
      indentation = (node.treeDepth * theme.indentationPadding).clamp(0, 100);
    } else {
      indentation = theme.indentationPadding;
    }

    return Gap(indentation);
  }

  Widget _buildToggleButton(BuildContext context) => const SizedBox(
        width: 24,
        child: _ToggleButton(),
      );

  Widget _buildNodeKey(BuildContext context, String searchTerm) {
    final Widget nodeKey = _RootNodeWidget(
      key: ValueKey('${node.key}-${node.isRoot}'),
      node: node,
      rootNameFormatter: rootNameFormatter,
      propertyNameFormatter: propertyNameFormatter,
      searchTerm: searchTerm,
      theme: theme,
    );

    final jsonCard = JsonCard(
      backgroundColor: theme.rootKeyTextStyle.color,
      child: nodeKey,
    );

    if (maxRootNodeWidth != null) {
      return Flexible(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxRootNodeWidth!,
          ),
          child: jsonCard,
        ),
      );
    }

    return jsonCard;
  }

  Widget _buildKeySeparator() => const Flexible(
        child: SizedBox(
          width: 8,
          child: _KeySeparatorText(),
        ),
      );

  Widget _buildArraySuffix() => Flexible(
        child: Padding(
          padding: _kLeftPadding,
          child: Text(
            '[${node.children.length}]',
            style: theme.rootKeyTextStyle.copyWith(
              color: JsonColors.arrayColor,
            ),
          ),
        ),
      );

  Widget _buildMapSuffix() => Flexible(
        child: Padding(
          padding: _kLeftPadding,
          child: Text(
            '{${node.children.length}}',
            style: theme.rootKeyTextStyle.copyWith(
              color: JsonColors.objectColor,
            ),
          ),
        ),
      );

  Widget _buildRootInformation(BuildContext context) => Padding(
        padding: _kLeftPadding,
        child: rootInformationBuilder?.call(context, node) ?? _kEmptyWidget,
      );

  Widget _buildPropertyValue(
    BuildContext context,
    String searchTerm,
    PropertyOverrides valueStyle,
  ) =>
      Expanded(
        flex: 10,
        child: _PropertyNodeWidget(
          key: ValueKey('value-${node.key}'),
          node: node,
          searchTerm: searchTerm,
          valueFormatter: valueFormatter,
          style: valueStyle.style,
          searchHighlightStyle: theme.valueSearchHighlightTextStyle,
          focusedSearchHighlightStyle:
              theme.focusedValueSearchHighlightTextStyle,
        ),
      );

  void _onNodeTap(BuildContext context) {
    if (!node.isRoot) return;

    final jsonExplorerStore = Provider.of<JsonExplorerStore>(
      context,
      listen: false,
    );

    if (node.isCollapsed) {
      jsonExplorerStore.expandNode(node);
    } else {
      jsonExplorerStore.collapseNode(node);
    }
  }
}

/// Toggle button for expanding/collapsing nodes
class _ToggleButton extends StatelessWidget {
  const _ToggleButton();

  @override
  Widget build(BuildContext context) {
    final jsonAttribute =
        context.findAncestorWidgetOfExactType<JsonAttribute>()!;
    final node = jsonAttribute.node;
    final toggle = jsonAttribute.collapsableToggleBuilder;

    return toggle?.call(context, node) ??
        (node.isCollapsed
            ? const Icon(Icons.arrow_right)
            : const Icon(Icons.arrow_drop_down));
  }
}

/// Text separator widget showing colon between key and value
class _KeySeparatorText extends StatelessWidget {
  const _KeySeparatorText();

  @override
  Widget build(BuildContext context) {
    final theme = context.findAncestorWidgetOfExactType<JsonAttribute>()!.theme;
    return Text(':', style: theme.rootKeyTextStyle);
  }
}

/// A [Widget] that renders a node that can be a class or a list.
class _RootNodeWidget extends StatelessWidget {
  const _RootNodeWidget({
    required this.node,
    required this.searchTerm,
    required this.rootNameFormatter,
    required this.propertyNameFormatter,
    required this.theme,
    super.key,
  });

  final NodeViewModelState node;
  final String searchTerm;
  final Formatter? rootNameFormatter;
  final Formatter? propertyNameFormatter;
  final JsonExplorerTheme theme;

  String _keyName() {
    if (node.isRoot) {
      return rootNameFormatter?.call(node.key) ?? node.key;
    }
    return propertyNameFormatter?.call(node.key) ?? node.key;
  }

  /// Gets the index of the focused search match.
  int? _getFocusedSearchMatchIndex(JsonExplorerStore store) {
    if (store.searchResults.isEmpty) {
      return null;
    }

    if (store.focusedSearchResult.node != node) {
      return null;
    }

    // Assert that it's the key and not the value of the node.
    if (store.focusedSearchResult.matchLocation != SearchMatchLocation.key) {
      return null;
    }

    return store.focusedSearchResult.matchIndex;
  }

  @override
  Widget build(BuildContext context) {
    // Combine selectors to reduce rebuilds
    final storeData =
        context.select<JsonExplorerStore, ({bool hasSearchResults})>(
      (store) => (hasSearchResults: store.searchResults.isNotEmpty),
    );
    final showHighlightedText = storeData.hasSearchResults;

    final attributeKeyStyle =
        node.isRoot ? theme.rootKeyTextStyle : theme.propertyKeyTextStyle;

    // Memoize text value
    final text = _keyName();

    if (!showHighlightedText) {
      return Row(
        children: [
          Text(
            text,
            style: attributeKeyStyle,
          ),
        ],
      );
    }

    final focusedSearchMatchIndex =
        context.select<JsonExplorerStore, int?>(_getFocusedSearchMatchIndex);

    return _HighlightedText(
      key: ValueKey('highlight-$text-$searchTerm'),
      text: text,
      highlightedText: searchTerm,
      style: attributeKeyStyle,
      primaryMatchStyle: theme.focusedKeySearchNodeHighlightTextStyle,
      secondaryMatchStyle: theme.keySearchHighlightTextStyle,
      focusedSearchMatchIndex: focusedSearchMatchIndex,
    );
  }
}

/// A [Widget] that renders a leaf node.
class _PropertyNodeWidget extends StatelessWidget {
  const _PropertyNodeWidget({
    required this.node,
    required this.searchTerm,
    required this.valueFormatter,
    required this.style,
    required this.searchHighlightStyle,
    required this.focusedSearchHighlightStyle,
    super.key,
  });

  final NodeViewModelState node;
  final String searchTerm;
  final Formatter? valueFormatter;
  final TextStyle style;
  final TextStyle searchHighlightStyle;
  final TextStyle focusedSearchHighlightStyle;

  /// Gets the index of the focused search match.
  int? _getFocusedSearchMatchIndex(JsonExplorerStore store) {
    if (store.searchResults.isEmpty) {
      return null;
    }

    if (store.focusedSearchResult.node != node) {
      return null;
    }

    // Assert that it's the value and not the key of the node.
    if (store.focusedSearchResult.matchLocation != SearchMatchLocation.value) {
      return null;
    }

    return store.focusedSearchResult.matchIndex;
  }

// Use a cached value if possible - this could be further optimized with a memo
  String _formatValue() =>
      valueFormatter?.call(node.value) ??
      ((node.value?.toString().isEmpty ?? false)
          ? 'empty'
          : node.value?.toString() ?? 'null');

  @override
  Widget build(BuildContext context) {
    // Combine selectors to reduce context lookups
    final storeData =
        context.select<JsonExplorerStore, ({bool hasSearchResults})>(
      (store) => (hasSearchResults: store.searchResults.isNotEmpty),
    );
    final showHighlightedText = storeData.hasSearchResults;

    // Cache computations
    final text = _formatValue();
    final valueColor = JsonColorsUtils.getValueColorByKey(
      context,
      node.key,
      node.value,
    );

    if (!showHighlightedText) {
      return _buildSimpleValue(text, valueColor);
    }

    final focusedSearchMatchIndex =
        context.select<JsonExplorerStore, int?>(_getFocusedSearchMatchIndex);

    return _buildHighlightedValue(text, valueColor, focusedSearchMatchIndex);
  }

  Widget _buildSimpleValue(String text, Color valueColor) => Row(
        children: [
          Flexible(
            child: JsonCard(
              backgroundColor: valueColor,
              child: Text(
                text,
                style: style.copyWith(color: valueColor),
              ),
            ),
          ),
        ],
      );

  Widget _buildHighlightedValue(
    String text,
    Color valueColor,
    int? focusedSearchMatchIndex,
  ) =>
      Row(
        children: [
          Flexible(
            child: JsonCard(
              backgroundColor: valueColor,
              child: _HighlightedText(
                key: ValueKey('highlight-value-$text'),
                text: text,
                highlightedText: searchTerm,
                style: style.copyWith(color: valueColor),
                primaryMatchStyle: focusedSearchHighlightStyle,
                secondaryMatchStyle: searchHighlightStyle,
                focusedSearchMatchIndex: focusedSearchMatchIndex,
              ),
            ),
          ),
        ],
      );
}

/// Highlights found occurrences of [highlightedText] in [text].
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.highlightedText,
    required this.style,
    required this.primaryMatchStyle,
    required this.secondaryMatchStyle,
    required this.focusedSearchMatchIndex,
    super.key,
  });

  final String text;
  final String highlightedText;
  final TextStyle style;
  final TextStyle primaryMatchStyle;
  final TextStyle secondaryMatchStyle;
  final int? focusedSearchMatchIndex;

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Builder(
          builder: (context) {
            // Cache these expensive operations
            final lowerCaseText = text.toLowerCase();
            final lowerCaseQuery = highlightedText.toLowerCase();

            if (highlightedText.isEmpty ||
                !lowerCaseText.contains(lowerCaseQuery)) {
              return Text(text, style: style);
            }

            return Text.rich(
              TextSpan(
                children: _buildTextSpans(text, lowerCaseText, lowerCaseQuery),
              ),
            );
          },
        ),
      );

  List<InlineSpan> _buildTextSpans(
    String text,
    String lowerCaseText,
    String lowerCaseQuery,
  ) {
    final spans = <InlineSpan>[];
    final queryLength = highlightedText.length;

    // Pre-calculate all match positions for better performance
    final matchPositions = <int>[];
    var pos = 0;
    while (true) {
      pos = lowerCaseText.indexOf(lowerCaseQuery, pos);
      if (pos == -1) break;
      matchPositions.add(pos);
      pos += queryLength;
    }

    // Process each position more efficiently
    if (matchPositions.isEmpty) {
      spans.add(TextSpan(text: text, style: style));
      return spans;
    }

    var lastEnd = 0;
    for (final position in matchPositions) {
      if (position > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, position),
            style: style,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(position, position + queryLength),
          style: style.copyWith(
            color: primaryMatchStyle.color,
            backgroundColor: primaryMatchStyle.backgroundColor,
            fontWeight: primaryMatchStyle.fontWeight,
          ),
        ),
      );

      lastEnd = position + queryLength;
    }

    // Add any remaining text after the last match
    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: style,
        ),
      );
    }

    return spans;
  }
}
