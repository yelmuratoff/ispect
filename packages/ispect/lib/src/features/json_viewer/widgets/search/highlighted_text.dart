import 'package:flutter/widgets.dart';
import 'package:ispect/src/features/json_viewer/services/text_match_service.dart';

/// Highlights all occurrences of [highlightedText] inside [text].
///
/// - Uses [TextMatchService] to separate search + caching from rendering.
/// - Applies [primaryMatchStyle] to the focused match (by index), and
///   [secondaryMatchStyle] to other matches.
class HighlightedText extends StatelessWidget {
  const HighlightedText({
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
  Widget build(BuildContext context) {
    if (highlightedText.isEmpty) {
      return Text(text, style: style);
    }

    final positions =
        TextMatchService.instance.findMatches(text, highlightedText);
    if (positions.isEmpty) {
      return Text(text, style: style);
    }

    final spans = _buildSpans(text, positions, highlightedText.length);
    return Text.rich(TextSpan(children: spans));
  }

  List<InlineSpan> _buildSpans(
    String source,
    List<int> positions,
    int matchLength,
  ) {
    final spans = <InlineSpan>[];
    var lastEnd = 0;

    for (var i = 0; i < positions.length; i++) {
      final start = positions[i];
      final isFocused = start == focusedSearchMatchIndex;
      final highlightStyle =
          isFocused ? primaryMatchStyle : secondaryMatchStyle;

      if (start > lastEnd) {
        spans.add(
          TextSpan(text: source.substring(lastEnd, start), style: style),
        );
      }

      spans.add(
        TextSpan(
          text: source.substring(start, start + matchLength),
          style: highlightStyle,
        ),
      );

      lastEnd = start + matchLength;
    }

    if (lastEnd < source.length) {
      spans.add(TextSpan(text: source.substring(lastEnd), style: style));
    }

    return spans;
  }
}
