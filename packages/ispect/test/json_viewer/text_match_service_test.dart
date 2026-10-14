import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/src/features/json_viewer/services/text_match_service.dart';
import 'package:ispect/src/features/json_viewer/widgets/search/highlighted_text.dart';

void main() {
  group('TextMatchService', () {
    test('returns case-insensitive matches in source coordinates', () {
      expect(TextMatchService.instance.findMatches('İİabc ABC', 'abc'), [2, 6]);
    });

    test('treats the query literally', () {
      expect(TextMatchService.instance.findMatches('a.b axb', 'a.b'), [0]);
    });
  });

  testWidgets('HighlightedText highlights the source slice of each match', (
    tester,
  ) async {
    const highlight = TextStyle(fontWeight: FontWeight.bold);
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: HighlightedText(
          text: 'İİabc',
          highlightedText: 'ABC',
          style: TextStyle(),
          primaryMatchStyle: highlight,
          secondaryMatchStyle: highlight,
          focusedSearchMatchIndex: 2,
        ),
      ),
    );

    final rich = tester.widget<RichText>(find.byType(RichText));
    final leaves = <TextSpan>[];
    rich.text.visitChildren((span) {
      if (span is TextSpan && span.text != null) leaves.add(span);
      return true;
    });
    expect([for (final span in leaves) span.text], ['İİ', 'abc']);
    expect(leaves.last.style, highlight);
  });
}
