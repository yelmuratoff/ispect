import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/json_viewer/models/node_view_model.dart';
import 'package:ispect/src/features/json_viewer/utils/colors.dart';
import 'package:ispect/src/features/json_viewer/widgets/explorer.dart'
    show Formatter;
import 'package:ispect/src/features/json_viewer/widgets/json_card.dart';
import 'package:ispect/src/features/json_viewer/widgets/search/highlighted_text.dart';

/// Renders a leaf value with optional search highlight.
class PropertyNodeWidget extends StatelessWidget {
  const PropertyNodeWidget({
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

  String _formatValue() {
    final val = node.value;
    final custom = valueFormatter?.call(val);
    if (custom != null) return custom;
    return switch (val) {
      null => 'null',
      _ => val.toString().isEmpty ? 'empty' : val.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = _formatValue();
    final valueColor =
        JsonColorsUtils.valueColorByKey(context, node.key, node.value);
    final valueStyle = style.copyWith(color: valueColor);

    return switch (hasSearchResults) {
      false => Row(
          children: [
            Flexible(
              child: JsonCard(
                backgroundColor: valueColor,
                child: Text(text, style: valueStyle),
              ),
            ),
          ],
        ),
      true => Row(
          children: [
            Flexible(
              child: JsonCard(
                backgroundColor: valueColor,
                child: HighlightedText(
                  key: ValueKey('highlight-value-$text'),
                  text: text,
                  highlightedText: searchTerm,
                  style: valueStyle,
                  primaryMatchStyle: focusedSearchHighlightStyle,
                  secondaryMatchStyle: searchHighlightStyle,
                  focusedSearchMatchIndex: focusedSearchMatchIndex,
                ),
              ),
            ),
          ],
        ),
    };
  }
}
