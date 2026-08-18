import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_layout/src/widgets/components/property_extractors.dart';

void main() {
  testWidgets('typography values preserve hundredths without trailing zeros', (
    tester,
  ) async {
    final props = spanProps(
      const TextStyle(
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.25,
        wordSpacing: 1.5,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [for (final prop in props) prop.child],
        ),
      ),
    );

    expect(find.text('14'), findsOneWidget);
    expect(find.text('1.43'), findsOneWidget);
    expect(find.text('0.25'), findsOneWidget);
    expect(find.text('1.5'), findsOneWidget);
    expect(find.text('0.3'), findsNothing);
  });
}
