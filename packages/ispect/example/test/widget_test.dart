import 'package:flutter_test/flutter_test.dart';
import 'package:ispect_example/main.dart';

void main() {
  testWidgets('Quick start renders log buttons', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Log info'), findsOneWidget);
    expect(find.text('Log error'), findsOneWidget);
  });
}
