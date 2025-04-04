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

  final double? maxRootNodeWidth;

  @override
  Widget build(BuildContext context) {
    final searchTerm =
        context.select<JsonExplorerStore, String>((store) => store.searchTerm);

    final valueStyle = valueStyleBuilder != null
        ? valueStyleBuilder!.call(
            node.value,
            theme.valueTextStyle,
          )
        : PropertyOverrides(style: theme.valueTextStyle);

    final hasInteraction = node.isRoot || valueStyle.onTap != null;

    return MouseRegion(
      cursor: hasInteraction ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: (event) {
        node
          ..highlight()
          ..focus();
      },
      onExit: (event) {
        node
          ..highlight(isHighlighted: false)
          ..focus(isFocused: false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hasInteraction
            ? () {
                if (valueStyle.onTap != null) {
                  valueStyle.onTap!.call();
                } else {
                  _onTap(context);
                }
              }
            : null,
        child: AnimatedBuilder(
          animation: node,

          /// IntrinsicHeight is not the best solution for this, the performance
          /// hit that we measured is ok for now. We will revisit this in the
          /// future if we fill that we need to improve the node rendering
          /// performance
          builder: (context, child) => Padding(
            padding: const EdgeInsets.only(
              bottom: 4,
            ),
            child: Flex(
              direction: Axis.horizontal,
              crossAxisAlignment: node.isRoot
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Gap(
                  node.treeDepth > 0
                      ? (node.treeDepth * theme.indentationPadding)
                          .clamp(0, 100)
                      : theme.indentationPadding,
                ),
                //
                // // <-- Collapsable Toggle -->
                //
                if (node.isRoot)
                  SizedBox(
                    width: 24,
                    child: collapsableToggleBuilder?.call(
                          context,
                          node,
                        ) ??
                        _defaultCollapsableToggleBuilder(context, node),
                  ),
                //
                // <-- Key -->
                //
                if (maxRootNodeWidth != null)
                  Flexible(
                    child: Container(
                      constraints: BoxConstraints(
                        maxWidth: maxRootNodeWidth!,
                      ),
                      child: JsonCard(
                        backgroundColor: theme.rootKeyTextStyle.color,
                        child: _RootNodeWidget(
                          node: node,
                          rootNameFormatter: rootNameFormatter,
                          propertyNameFormatter: propertyNameFormatter,
                          searchTerm: searchTerm,
                          theme: theme,
                        ),
                      ),
                    ),
                  )
                else
                  JsonCard(
                    backgroundColor: theme.rootKeyTextStyle.color,
                    child: _RootNodeWidget(
                      node: node,
                      rootNameFormatter: rootNameFormatter,
                      propertyNameFormatter: propertyNameFormatter,
                      searchTerm: searchTerm,
                      theme: theme,
                    ),
                  ),
                //
                // <-- Key Separator -->
                //
                Flexible(
                  child: SizedBox(
                    width: 8,
                    child: Text(
                      ':',
                      style: theme.rootKeyTextStyle,
                    ),
                  ),
                ),
                //
                // <--- Array Suffix --->
                //
                if (node.value is List) ...[
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '[${node.children.length}]',
                        style: theme.rootKeyTextStyle.copyWith(
                          color: JsonColors.arrayColor,
                        ),
                      ),
                    ),
                  ),
                ],
                //
                // <--- Map Suffix --->
                //
                if (node.value is Map) ...[
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        '{${node.children.length}}',
                        style: theme.rootKeyTextStyle.copyWith(
                          color: JsonColors.objectColor,
                        ),
                      ),
                    ),
                  ),
                ],

                if (node.isRoot)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: rootInformationBuilder?.call(context, node) ??
                        const SizedBox.shrink(),
                  )
                //
                // <-- Value -->
                //
                else
                  Expanded(
                    flex: 10,
                    child: _PropertyNodeWidget(
                      node: node,
                      searchTerm: searchTerm,
                      valueFormatter: valueFormatter,
                      style: valueStyle.style,
                      searchHighlightStyle: theme.valueSearchHighlightTextStyle,
                      focusedSearchHighlightStyle:
                          theme.focusedValueSearchHighlightTextStyle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    if (node.isRoot) {
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

  /// Default value for [collapsableToggleBuilder]
  ///
  /// A material [Icons.arrow_right] is displayed for collapsed nodes and
  /// [Icons.arrow_drop_down] for expanded nodes.
  static Widget _defaultCollapsableToggleBuilder(
    BuildContext context,
    NodeViewModelState node,
  ) =>
      node.isCollapsed
          ? const Icon(
              Icons.arrow_right,
            )
          : const Icon(
              Icons.arrow_drop_down,
            );
}

/// A [Widget] that renders a node that can be a class or a list.
class _RootNodeWidget extends StatelessWidget {
  const _RootNodeWidget({
    required this.node,
    required this.searchTerm,
    required this.rootNameFormatter,
    required this.propertyNameFormatter,
    required this.theme,
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
    final showHighlightedText = context.select<JsonExplorerStore, bool>(
      (store) => store.searchResults.isNotEmpty,
    );

    final attributeKeyStyle =
        node.isRoot ? theme.rootKeyTextStyle : theme.propertyKeyTextStyle;

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

  @override
  Widget build(BuildContext context) {
    final showHighlightedText = context.select<JsonExplorerStore, bool>(
      (store) => store.searchResults.isNotEmpty,
    );

    final text = valueFormatter?.call(node.value) ??
        ((node.value?.toString().isEmpty ?? false)
            ? 'empty'
            : node.value?.toString() ?? 'null');

    final valueColor = JsonColorsUtils.getValueColorByKey(
      context,
      node.key,
      node.value,
    );

    //
    // <--- Value --->
    //
    if (!showHighlightedText) {
      return Row(
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
    }

    final focusedSearchMatchIndex =
        context.select<JsonExplorerStore, int?>(_getFocusedSearchMatchIndex);

    return Row(
      children: [
        Flexible(
          child: JsonCard(
            backgroundColor: valueColor,
            child: _HighlightedText(
              text: text,
              highlightedText: searchTerm,
              style: style.copyWith(
                color: valueColor,
              ),
              primaryMatchStyle: focusedSearchHighlightStyle,
              secondaryMatchStyle: searchHighlightStyle,
              focusedSearchMatchIndex: focusedSearchMatchIndex,
            ),
          ),
        ),
      ],
    );
  }
}

/// Highlights found occurrences of [highlightedText] with [highlightedStyle]
/// in [text].
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.text,
    required this.highlightedText,
    required this.style,
    required this.primaryMatchStyle,
    required this.secondaryMatchStyle,
    required this.focusedSearchMatchIndex,
  });
  final String text;
  final String highlightedText;

  // The default style when the text or part of it is not highlighted.
  final TextStyle style;

  // The style of the focused search match.
  final TextStyle primaryMatchStyle;

  // The style of the search match that is not focused.
  final TextStyle secondaryMatchStyle;

  // The index of the focused search match.
  final int? focusedSearchMatchIndex;

  @override
  Widget build(BuildContext context) {
    final lowerCaseText = text.toLowerCase();
    final lowerCaseQuery = highlightedText.toLowerCase();

    if (highlightedText.isEmpty || !lowerCaseText.contains(lowerCaseQuery)) {
      return Text(
        text,
        style: style,
      );
    }

    final spans = <InlineSpan>[];
    var start = 0;

    while (true) {
      var index = lowerCaseText.indexOf(lowerCaseQuery, start);
      index = index >= 0 ? index : text.length;
      // final isSearchMatched = index == focusedSearchMatchIndex;

      if (start != index) {
        spans.add(
          TextSpan(
            text: text.substring(start, index),
            style: style,
          ),
        );
      }

      if (index >= text.length) {
        break;
      }

      spans.add(
        TextSpan(
          text: text.substring(index, index + highlightedText.length),
          style: style.copyWith(
            color: primaryMatchStyle.color,
            backgroundColor: primaryMatchStyle.backgroundColor,
            fontWeight: primaryMatchStyle.fontWeight,
            // color: isSearchMatched
            //     ? primaryMatchStyle.color
            //     : secondaryMatchStyle.color,
            // backgroundColor: isSearchMatched
            //     ? primaryMatchStyle.backgroundColor
            //     : secondaryMatchStyle.backgroundColor,
            // fontWeight: isSearchMatched
            //     ? primaryMatchStyle.fontWeight
            //     : secondaryMatchStyle.fontWeight,
          ),
        ),
      );
      start = index + highlightedText.length;
    }

    return Text.rich(
      TextSpan(
        children: spans,
      ),
    );
  }
}
