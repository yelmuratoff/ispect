import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect_example/main.dart';

void main() {
  testWidgets('Quick start renders its log buttons', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('ISpect Quick Start'), findsOneWidget);
    expect(find.text('info'), findsOneWidget);
    expect(find.text('error'), findsOneWidget);
  });

  testWidgets('tapping the info button records a log', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('info'));
    await tester.pump();

    expect(
      ISpect.logger.history.any(
        (e) => e.message?.contains('Hello from ISpect!') ?? false,
      ),
      isTrue,
    );
  });
}
