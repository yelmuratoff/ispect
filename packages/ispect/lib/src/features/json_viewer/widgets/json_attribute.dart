import 'package:flutter/material.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/copy_clipboard.dart';
import 'package:ispect/src/core/res/json_color.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/theme.dart';
import 'package:ispect/src/features/json_viewer/utils/colors.dart';
import 'package:ispect/src/features/json_viewer/widgets/controller/store.dart';
import 'package:ispect/src/features/json_viewer/widgets/explorer.dart';
import 'package:ispect/src/features/json_viewer/widgets/json_card.dart';
import 'package:ispect/src/features/json_viewer/widgets/paints/dot_painter.dart';
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
  PropertyOverrides? _cachedValueStyle;
  bool? _cachedHasInteraction;

  @override
  void didUpdateWidget(JsonAttribute oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear cache if node or relevant properties changed
    if (oldWidget.node != widget.node ||
        oldWidget.valueStyleBuilder != widget.valueStyleBuilder ||
        oldWidget.theme != widget.theme) {
      _cachedValueStyle = null;
      _cachedHasInteraction = null;
    }
  }

  PropertyOverrides get _valueStyle =>
      _cachedValueStyle ??= widget.valueStyleBuilder?.call(
            widget.node.value,
            widget.theme.valueTextStyle,
          ) ??
          PropertyOverrides(style: widget.theme.valueTextStyle);

  bool get _hasInteraction =>
      _cachedHasInteraction ??= widget.node.isRoot || _valueStyle.onTap != null;

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
          if (store.focusedSearchResult.matchLocation ==
              SearchMatchLocation.key) {
            focusedKeyIndex = store.focusedSearchResult.matchIndex;
          } else if (store.focusedSearchResult.matchLocation ==
              SearchMatchLocation.value) {
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
          cursor: _hasInteraction ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) => _handleMouseEnter(),
          onExit: (_) => _handleMouseExit(),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _hasInteraction ? () => _handleTap(context, valueStyle) : null,
            child: AnimatedBuilder(
              animation: widget.node,
              builder: (context, _) => RepaintBoundary(
                child: Padding(
                  padding: _kBottomPadding,
                  child: Row(
                    crossAxisAlignment: widget.node.isRoot
                        ? CrossAxisAlignment.center
                        : CrossAxisAlignment.start,
                    children: [
                      SelectionContainer.disabled(
                        child: _IndentationWidget(
                          depth: widget.node.treeDepth,
                          indentationPadding: widget.theme.indentationPadding,
                          color: widget.theme.indentationLineColor,
                        ),
                      ),
                      if (widget.node.isRoot && widget.node.children.isNotEmpty)
                        const SelectionContainer.disabled(
                          child: SizedBox(
                            width: 24,
                            child: _ToggleButton(),
                          ),
                        ),
                      _buildNodeKey(
                        context,
                        searchData.searchTerm,
                        searchData.hasSearchResults,
                        searchData.focusedKeyMatchIndex,
                      ),
                      const SizedBox(
                        width: 8,
                        child: _KeySeparatorText(),
                      ),
                      if (widget.node.value is List)
                        _ArraySuffixWidget(
                          length: widget.node.children.length,
                          style: widget.theme.rootKeyTextStyle,
                        ),
                      if (widget.node.value is Map || widget.node.value is Set)
                        _MapSuffixWidget(
                          length: widget.node.children.length,
                          style: widget.theme.rootKeyTextStyle,
                        ),
                      if (widget.node.isRoot)
                        SelectionContainer.disabled(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _CopyButton(
                              node: widget.node,
                              theme: widget.theme,
                            ),
                          ),
                        ),
                      if (widget.node.isRoot)
                        _buildRootInformation(context)
                      else
                        _buildPropertyValue(
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
    final nodeKey = _RootNodeWidget(
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

    if (widget.maxRootNodeWidth != null) {
      return Flexible(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: widget.maxRootNodeWidth!,
          ),
          child: jsonCard,
        ),
      );
    }

    return jsonCard;
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
        child: _PropertyNodeWidget(
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

    if (widget.node.isCollapsed) {
      widget.store.expandNode(widget.node);
    } else {
      widget.store.collapseNode(widget.node);
    }
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.node,
    required this.theme,
  });

  final NodeViewModelState node;
  final JsonExplorerTheme theme;

  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        onTap: () {
          copyClipboard(
            context,
            value: '${node.key}: ${JsonTruncatorService.pretty(node.rawValue)}',
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Icon(
            Icons.copy_rounded,
            size: 14,
            color: theme.rootKeyTextStyle.color,
          ),
        ),
      );
}

class _IndentationWidget extends StatelessWidget {
  const _IndentationWidget({
    required this.depth,
    required this.indentationPadding,
    required this.color,
  });

  final int depth;
  final double indentationPadding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final indentation = depth > 0
        ? ((depth + 1) * indentationPadding).clamp(0, 100)
        : indentationPadding;
    return Padding(
      padding: const EdgeInsets.only(right: 4, left: 4),
      child: CustomPaint(
        painter: DotPainter(
          count: (indentation / 5).clamp(0, double.infinity),
          color: color,
        ),
        size: Size(
          indentation.toDouble(),
          20,
        ),
      ),
    );
  }
}

class _ArraySuffixWidget extends StatelessWidget {
  const _ArraySuffixWidget({required this.length, required this.style});
  final int length;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Flexible(
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '[$length]',
            style: style.copyWith(
              color: JsonColors.arrayColor,
            ),
          ),
        ),
      );
}

class _MapSuffixWidget extends StatelessWidget {
  const _MapSuffixWidget({required this.length, required this.style});
  final int length;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Flexible(
        child: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            '{$length}',
            style: style.copyWith(
              color: JsonColors.objectColor,
            ),
          ),
        ),
      );
}

/// Toggle button for expanding/collapsing nodes
class _ToggleButton extends StatefulWidget {
  const _ToggleButton();

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  JsonAttribute? _cachedJsonAttribute;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedJsonAttribute =
        context.findAncestorWidgetOfExactType<JsonAttribute>();
  }

  @override
  Widget build(BuildContext context) {
    final jsonAttribute = _cachedJsonAttribute!;
    final node = jsonAttribute.node;
    final toggle = jsonAttribute.collapsableToggleBuilder;

    return ListenableBuilder(
      listenable: node,
      builder: (context, child) =>
          toggle?.call(context, node) ??
          (AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              node.isCollapsed
                  ? Icons.arrow_right_rounded
                  : Icons.arrow_drop_down_rounded,
              key: ValueKey(node.isCollapsed),
              color: jsonAttribute.theme.rootKeyTextStyle.color,
            ),
          )),
    );
  }
}

/// Text separator widget showing colon between key and value
class _KeySeparatorText extends StatefulWidget {
  const _KeySeparatorText();

  @override
  State<_KeySeparatorText> createState() => _KeySeparatorTextState();
}

class _KeySeparatorTextState extends State<_KeySeparatorText> {
  JsonExplorerTheme? _cachedTheme;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _cachedTheme =
        context.findAncestorWidgetOfExactType<JsonAttribute>()?.theme;
  }

  @override
  Widget build(BuildContext context) =>
      Text(':', style: _cachedTheme?.rootKeyTextStyle);
}

/// A `Widget` that renders a node that can be a class or a list.
class _RootNodeWidget extends StatelessWidget {
  const _RootNodeWidget({
    required this.node,
    required this.searchTerm,
    required this.rootNameFormatter,
    required this.propertyNameFormatter,
    required this.theme,
    required this.hasSearchResults,
    required this.focusedSearchMatchIndex,
    super.key,
  });

  final NodeViewModelState node;
  final String searchTerm;
  final Formatter? rootNameFormatter;
  final Formatter? propertyNameFormatter;
  final JsonExplorerTheme theme;
  final bool hasSearchResults;
  final int? focusedSearchMatchIndex;

  String _keyName() {
    if (node.isRoot) {
      return rootNameFormatter?.call(node.key) ?? node.key;
    }
    return propertyNameFormatter?.call(node.key) ?? node.key;
  }

  @override
  Widget build(BuildContext context) {
    final attributeKeyStyle =
        node.isRoot ? theme.rootKeyTextStyle : theme.propertyKeyTextStyle;

    // Memoize text value
    final text = _keyName();

    if (!hasSearchResults) {
      return Row(
        children: [
          Text(
            text,
            style: attributeKeyStyle,
          ),
        ],
      );
    }

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

/// A `Widget` that renders a leaf node.
class _PropertyNodeWidget extends StatelessWidget {
  const _PropertyNodeWidget({
    required this.node,
    required this.searchTerm,
    required this.valueFormatter,
    required this.style,
    required this.searchHighlightStyle,
    required this.focusedSearchHighlightStyle,
    required this.hasSearchResults,
    required this.focusedSearchMatchIndex,
    super.key,
  });

  final NodeViewModelState node;
  final String searchTerm;
  final Formatter? valueFormatter;
  final TextStyle style;
  final TextStyle searchHighlightStyle;
  final TextStyle focusedSearchHighlightStyle;
  final bool hasSearchResults;
  final int? focusedSearchMatchIndex;

// Use a cached value if possible - this could be further optimized with a memo
  String _formatValue() =>
      valueFormatter?.call(node.value) ??
      ((node.value?.toString().isEmpty ?? false)
          ? 'empty'
          : node.value?.toString() ?? 'null');

  @override
  Widget build(BuildContext context) {
    // Cache computations
    final text = _formatValue();
    final valueColor = JsonColorsUtils.valueColorByKey(
      context,
      node.key,
      node.value,
    );

    if (!hasSearchResults) {
      return _buildSimpleValue(text, valueColor);
    }

    return _buildHighlightedValue(
      text,
      valueColor,
      focusedSearchMatchIndex,
    );
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

/// Highlights found occurrences of `highlightedText` in [text].
class _HighlightedText extends StatefulWidget {
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
  State<_HighlightedText> createState() => _HighlightedTextState();
}

class _HighlightedTextState extends State<_HighlightedText> {
  List<InlineSpan>? _cachedSpans;
  String? _lastText;
  String? _lastHighlightedText;
  int? _lastFocusedIndex;

  @override
  void didUpdateWidget(_HighlightedText oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Clear cache if relevant properties changed
    if (oldWidget.text != widget.text ||
        oldWidget.highlightedText != widget.highlightedText ||
        oldWidget.focusedSearchMatchIndex != widget.focusedSearchMatchIndex) {
      _cachedSpans = null;
    }
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: Builder(
          builder: (context) {
            if (widget.highlightedText.isEmpty ||
                !widget.text
                    .toLowerCase()
                    .contains(widget.highlightedText.toLowerCase())) {
              return Text(widget.text, style: widget.style);
            }

            // Use cached spans if available and valid
            if (_cachedSpans != null &&
                _lastText == widget.text &&
                _lastHighlightedText == widget.highlightedText &&
                _lastFocusedIndex == widget.focusedSearchMatchIndex) {
              return Text.rich(TextSpan(children: _cachedSpans));
            }

            // Build and cache new spans
            final lowerCaseText = widget.text.toLowerCase();
            final lowerCaseQuery = widget.highlightedText.toLowerCase();

            _cachedSpans =
                _buildTextSpans(widget.text, lowerCaseText, lowerCaseQuery);
            _lastText = widget.text;
            _lastHighlightedText = widget.highlightedText;
            _lastFocusedIndex = widget.focusedSearchMatchIndex;

            return Text.rich(TextSpan(children: _cachedSpans));
          },
        ),
      );

  List<InlineSpan> _buildTextSpans(
    String text,
    String lowerCaseText,
    String lowerCaseQuery,
  ) {
    final spans = <InlineSpan>[];
    final queryLength = widget.highlightedText.length;

    // Pre-calculate all match positions
    final matchPositions = <int>[];

    var pos = 0;
    while (true) {
      pos = lowerCaseText.indexOf(lowerCaseQuery, pos);
      if (pos == -1) break;
      matchPositions.add(pos);
      pos += queryLength;
    }

    // Process each position
    if (matchPositions.isEmpty) {
      spans.add(TextSpan(text: text, style: widget.style));
      return spans;
    }

    var lastEnd = 0;
    for (final position in matchPositions) {
      final highlightStyle = position == widget.focusedSearchMatchIndex
          ? widget.primaryMatchStyle
          : widget.secondaryMatchStyle;

      if (position > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, position),
            style: widget.style,
          ),
        );
      }

      spans.add(
        TextSpan(
          text: text.substring(position, position + queryLength),
          style: highlightStyle.copyWith(
            color: highlightStyle.color,
            backgroundColor: highlightStyle.backgroundColor,
            fontWeight: highlightStyle.fontWeight,
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
          style: widget.style,
        ),
      );
    }

    return spans;
  }
}
