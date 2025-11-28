import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/theme.dart';
import 'package:ispect/src/features/json_viewer/widgets/explorer.dart'
    show Formatter;
import 'package:ispect/src/features/json_viewer/widgets/search/highlighted_text.dart';

/// Renders a node key (root/property) with optional search highlight.
class RootNodeWidget extends StatelessWidget {
  const RootNodeWidget({
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
    final text = _keyName();

    if (!hasSearchResults) {
      return Row(children: [Text(text, style: attributeKeyStyle)]);
    }

    return HighlightedText(
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
