import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ispect/ispect.dart';
import 'package:ispect/src/common/utils/json_input_preflight.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_format.dart';
import 'package:ispect/src/features/log_viewer/domain/models/file_processing_result.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget appShell(VoidCallback onPressed) => ISpectScopeController(
    model: ISpectScopeModel(isISpectEnabled: true),
    child: MaterialApp(
      localizationsDelegates: ISpectLocalization.localizationDelegates,
      supportedLocales: ISpectLocalization.supportedLocales,
      home: Scaffold(
        body: Center(
          child: ElevatedButton(onPressed: onPressed, child: const Text('go')),
        ),
      ),
    ),
  );

  Future<void> expectRejectedContent(
    WidgetTester tester,
    String content, {
    DiagnosticResourceLimits resourceLimits = DiagnosticResourceLimits.balanced,
  }) async {
    final result = FileProcessingResult.success(
      content: content,
      displayName: 'test',
      mimeType: 'application/json',
      fileName: 'hostile.json',
      format: FileFormat.json,
      resourceLimits: resourceLimits,
    );

    await tester.pumpWidget(
      appShell(
        () => result.action(tester.element(find.byType(ElevatedButton))),
      ),
    );

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();

    final screen = tester.widget<JsonScreen>(find.byType(JsonScreen));
    expect(screen.data, const {'content': JsonInputPreflight.rejectedContent});
  }

  group('FileProcessingResult.action JSON handling', () {
    testWidgets('opens JsonScreen with array wrapped under data', (
      tester,
    ) async {
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
          () => result.action(tester.element(find.byType(ElevatedButton))),
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

    testWidgets('opens JsonScreen with primitive wrapped under value', (
      tester,
    ) async {
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
          () => result.action(tester.element(find.byType(ElevatedButton))),
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

    testWidgets('shows toast and falls back to raw content for invalid JSON', (
      tester,
    ) async {
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
          () => result.action(tester.element(find.byType(ElevatedButton))),
        ),
      );

      await tester.tap(find.text('go'));
      await tester.pumpAndSettle();

      // Should navigate to JsonScreen showing raw content fallback
      final finder = find.byType(JsonScreen);
      expect(finder, findsOneWidget);
      final screen = tester.widget<JsonScreen>(finder);
      expect(screen.data.containsKey('content'), isTrue);
      expect(screen.data['content'], content);
    });

    testWidgets('does not decode oversized JSON', (tester) async {
      final oversizedPrefix = '{"value":"'.padRight(
        JsonInputPreflight.maxCharacters,
        'x',
      );
      final content = '$oversizedPrefix"}';

      await expectRejectedContent(tester, content);
    });

    testWidgets('uses the result-local import budget', (tester) async {
      final limits = DiagnosticResourceLimits.balanced.copyWith(
        maxImportCharacters: 64,
        maxImportBytes: 64,
      );

      await expectRejectedContent(
        tester,
        '{"value":"${'x' * 100}"}',
        resourceLimits: limits,
      );
    });

    testWidgets('does not decode deeply nested JSON', (tester) async {
      final openings = List<String>.filled(
        JsonInputPreflight.maxNestingDepth + 1,
        '[',
      ).join();
      final closings = List<String>.filled(
        JsonInputPreflight.maxNestingDepth + 1,
        ']',
      ).join();

      await expectRejectedContent(tester, '$openings$closings');
    });

    testWidgets('does not decode JSON wider than the viewer budget', (
      tester,
    ) async {
      final values = List<String>.filled(
        JsonInputPreflight.maxViewerNodes,
        'null',
      ).join(',');

      await expectRejectedContent(tester, '[$values]');
    });
  });
}
