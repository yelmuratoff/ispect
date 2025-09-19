import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/features/ispect/domain/models/file_format.dart';
import 'package:ispect/src/features/ispect/domain/models/file_processing_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget appShell(VoidCallback onPressed) => ISpectScopeController(
        model: ISpectScopeModel(isISpectEnabled: true),
        child: MaterialApp(
          localizationsDelegates: ISpectLocalization.localizationDelegates,
          supportedLocales: ISpectLocalization.supportedLocales,
          home: Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: onPressed,
                child: const Text('go'),
              ),
            ),
          ),
        ),
      );

  group('FileProcessingResult.action JSON handling', () {
    testWidgets('opens JsonScreen with array wrapped under data',
        (tester) async {
      final content = jsonEncode([
        {'a': 1},
        {'b': 2},
      ]);

      final result = FileProcessingResult.success(
        content: content,
        displayName: 'test',
        mimeType: 'application/json',
        fileName: 'array.json',
        format: FileFormat.json,
      );

      await tester.pumpWidget(
        appShell(
          () => result.action(
            tester.element(find.byType(ElevatedButton)),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final finder = find.byType(JsonScreen);
      expect(finder, findsOneWidget);
      final screen = tester.widget<JsonScreen>(finder);
      expect(screen.data.containsKey('data'), isTrue);
      expect(screen.data['data'], isA<List<dynamic>>());
      expect((screen.data['data'] as List).length, 2);
    });

    testWidgets('opens JsonScreen with primitive wrapped under value',
        (tester) async {
      const content = '123';
      final result = FileProcessingResult.success(
        content: content,
        displayName: 'test',
        mimeType: 'application/json',
        fileName: 'number.json',
        format: FileFormat.json,
      );

      await tester.pumpWidget(
        appShell(
          () => result.action(
            tester.element(find.byType(ElevatedButton)),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      final finder = find.byType(JsonScreen);
      expect(finder, findsOneWidget);
      final screen = tester.widget<JsonScreen>(finder);
      expect(screen.data.containsKey('value'), isTrue);
      expect(screen.data['value'], 123);
    });

    testWidgets('shows toast and does not push for invalid JSON',
        (tester) async {
      const content = '{invalid json}';
      final result = FileProcessingResult.success(
        content: content,
        displayName: 'test',
        mimeType: 'application/json',
        fileName: 'invalid.json',
        format: FileFormat.json,
      );

      await tester.pumpWidget(
        appShell(
          () => result.action(
            tester.element(find.byType(ElevatedButton)),
          ),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pump();

      // Should not navigate to JsonScreen on invalid JSON
      expect(find.byType(JsonScreen), findsNothing);
    });
  });
}
